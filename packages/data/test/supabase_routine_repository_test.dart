// Regression coverage for HABITAR_ROUTINE_SAVE_23505: editing and saving an
// existing routine used to raise a Postgres unique_violation on
// routine_steps(routine_id, step_order).
//
// Root cause: `SupabaseRoutineRepository.stepsForRoutine` called
// `.order('step_order')` without `ascending: true`. The `postgrest` package
// defaults `order()` to *descending*, so the steps came back last-first.
// `routine_setup_screen.dart` loads the edit form directly from that list
// (no re-sort by `RoutineStep.order`), so re-saving without any change sent
// the step titles back in reverse order. `updateRoutine` matches
// `stepTitles[index]` against `existingSteps[index]` purely positionally and
// writes `step_order: index + 1` — with the list reversed, the first UPDATE
// tries to move the *last* step into slot 1, which the *first* step still
// occupies, tripping the `unique (routine_id, step_order)` constraint from
// supabase/migrations/0001_initial_schema.sql.
//
// There is no local/remote Supabase instance available in this environment,
// so this test drives the real `SupabaseRoutineRepository` against an
// in-memory fake that speaks enough of the PostgREST HTTP contract —
// including the same unique constraint — to reproduce the failure
// end-to-end through the actual save path.

import 'dart:convert';

import 'package:habitar_data/data.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late _FakePostgrestServer server;
  late SupabaseClient client;
  late SupabaseRoutineRepository repository;

  setUp(() async {
    server = _FakePostgrestServer();
    client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: server,
    );
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'fake-access-token',
      'token_type': 'bearer',
      'user': {'id': 'adult-1'},
    }));
    repository = SupabaseRoutineRepository(client);
  });

  test('stepsForRoutine returns steps in ascending step_order order', () async {
    final routine = await repository.createRoutine(
      profileId: 'profile-1',
      title: 'Rutina de la mañana',
      stepTitles: ['Aseo', 'Vestirse', 'Mochila'],
    );

    final steps = await repository.stepsForRoutine(routine.metadata.id);

    expect(steps.map((step) => step.title), ['Aseo', 'Vestirse', 'Mochila']);
    expect(steps.map((step) => step.order), [1, 2, 3]);
  });

  test(
      'editing and resaving an existing routine does not raise '
      'HABITAR_ROUTINE_SAVE_23505', () async {
    final routine = await repository.createRoutine(
      profileId: 'profile-1',
      title: 'Rutina de la mañana',
      stepTitles: ['Aseo', 'Vestirse', 'Mochila'],
    );

    // Mirrors routine_setup_screen.dart: the edit form is populated
    // straight from stepsForRoutine, with no independent re-sort.
    final loadedSteps = await repository.stepsForRoutine(routine.metadata.id);
    final stepTitlesFromScreen =
        loadedSteps.map((step) => step.title).toList(growable: false);

    final saved = await repository.updateRoutine(
      routine: routine,
      stepTitles: stepTitlesFromScreen,
    );

    final savedSteps = await repository.stepsForRoutine(saved.metadata.id);
    expect(
        savedSteps.map((step) => step.title), ['Aseo', 'Vestirse', 'Mochila']);
    expect(savedSteps.map((step) => step.order), [1, 2, 3]);
  });
}

/// Minimal in-memory PostgREST stand-in, just faithful enough for
/// [SupabaseRoutineRepository]'s `routines`/`routine_steps` calls:
/// eq/neq filters, `order`, `.select().single()`, `Prefer: return=representation`,
/// and — crucially — the same `unique (routine_id, step_order)` constraint
/// that lives on the real `routine_steps` table.
class _FakePostgrestServer extends http.BaseClient {
  final Map<String, Map<String, Object?>> routines = {};
  final Map<String, Map<String, Object?>> routineSteps = {};
  int _seq = 0;

  Map<String, Map<String, Object?>> _table(String name) {
    switch (name) {
      case 'routines':
        return routines;
      case 'routine_steps':
        return routineSteps;
      default:
        throw UnsupportedError('Unhandled table in fake PostgREST: $name');
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final segments = request.url.pathSegments;
    if (segments.length < 3 || segments[0] != 'rest' || segments[1] != 'v1') {
      return _json(request, 404, {'message': 'Not found'});
    }
    final tableName = segments[2];
    final rows = _table(tableName);
    final isSingle =
        request.headers['Accept'] == 'application/vnd.pgrst.object+json';
    final wantsRepresentation =
        (request.headers['Prefer'] ?? '').contains('return=representation');

    try {
      switch (request.method) {
        case 'GET':
          final matches = _filtered(rows.values, request.url);
          if (isSingle) {
            if (matches.length != 1) {
              return _json(request, 406, {
                'code': '406',
                'message':
                    'JSON object requested, multiple (or no) rows returned',
              });
            }
            return _json(request, 200, matches.single);
          }
          return _json(request, 200, matches);
        case 'POST':
          final body = jsonDecode((request as http.Request).body)
              as Map<String, dynamic>;
          final row = Map<String, Object?>.from(body);
          row['id'] ??= '$tableName-${++_seq}';
          row['created_at'] ??= '2026-01-01T00:00:00.000Z';
          row['updated_at'] ??= row['created_at'];
          row['status'] ??= 'active';
          if (tableName == 'routine_steps') {
            _checkUniqueStepOrder(row, excludingId: null);
          }
          rows[row['id'] as String] = row;
          if (!wantsRepresentation) {
            return _empty(request, 201);
          }
          return _json(request, 201, isSingle ? row : [row]);
        case 'PATCH':
          final body = jsonDecode((request as http.Request).body)
              as Map<String, dynamic>;
          final targets = _filtered(rows.values, request.url);
          final updated = <Map<String, Object?>>[];
          for (final target in targets) {
            final id = target['id'] as String;
            final merged = Map<String, Object?>.from(target)..addAll(body);
            if (tableName == 'routine_steps' &&
                body.containsKey('step_order')) {
              _checkUniqueStepOrder(merged, excludingId: id);
            }
            rows[id] = merged;
            updated.add(merged);
          }
          if (!wantsRepresentation) {
            return _empty(request, 200);
          }
          if (isSingle) {
            if (updated.length != 1) {
              return _json(request, 406, {
                'code': '406',
                'message':
                    'JSON object requested, multiple (or no) rows returned',
              });
            }
            return _json(request, 200, updated.single);
          }
          return _json(request, 200, updated);
        default:
          return _json(request, 405, {'message': 'Method not allowed'});
      }
    } on _UniqueViolation catch (error) {
      return _json(request, 409, {
        'code': '23505',
        'message': 'duplicate key value violates unique constraint '
            '"routine_steps_routine_id_step_order_key"',
        'details': error.details,
        'hint': null,
      });
    }
  }

  void _checkUniqueStepOrder(
    Map<String, Object?> candidate, {
    required String? excludingId,
  }) {
    final conflict = routineSteps.values.any((row) =>
        row['id'] != excludingId &&
        row['routine_id'] == candidate['routine_id'] &&
        row['step_order'] == candidate['step_order']);
    if (conflict) {
      throw _UniqueViolation(
        'Key (routine_id, step_order)=(${candidate['routine_id']}, '
        '${candidate['step_order']}) already exists.',
      );
    }
  }

  List<Map<String, Object?>> _filtered(
    Iterable<Map<String, Object?>> rows,
    Uri url,
  ) {
    var result = rows;
    url.queryParameters.forEach((key, value) {
      if (key == 'select' || key == 'order' || key == 'limit') {
        return;
      }
      if (value.startsWith('eq.')) {
        final target = value.substring(3);
        result = result.where((row) => '${row[key]}' == target);
      } else if (value.startsWith('neq.')) {
        final target = value.substring(4);
        result = result.where((row) => '${row[key]}' != target);
      }
    });
    final list = result.toList(growable: false);
    final order = url.queryParameters['order'];
    if (order != null) {
      final parts = order.split('.');
      final column = parts.first;
      final ascending = parts.length > 1 && parts[1] == 'asc';
      list.sort((a, b) {
        final cmp = Comparable.compare(
          a[column] as Comparable,
          b[column] as Comparable,
        );
        return ascending ? cmp : -cmp;
      });
    }
    return list;
  }

  http.StreamedResponse _empty(http.BaseRequest request, int status) =>
      http.StreamedResponse(
        const Stream<List<int>>.empty(),
        status,
        request: request,
        headers: const {'content-type': 'application/json'},
      );

  http.StreamedResponse _json(
    http.BaseRequest request,
    int status,
    Object? body,
  ) {
    final encoded = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream.value(encoded),
      status,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _UniqueViolation implements Exception {
  _UniqueViolation(this.details);
  final String details;
}
