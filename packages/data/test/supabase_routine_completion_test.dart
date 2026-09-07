// Exercises SupabaseRoutineSessionRepository.completeSession (the two-step
// direct-update-then-RPC path added for migration 0011) and
// SupabaseFamilyActivityEventRepository against an in-memory fake that
// mirrors complete_routine_session's business rules - the same approach used
// for the HABITAR_ROUTINE_SAVE_23505 regression and the 0010 invitation-code
// RPCs: a fake PostgREST endpoint faithful enough to exercise the real
// repository code, instead of asserting against a reimplementation of it.
//
// What this fake can and cannot prove: it reimplements
// complete_routine_session's role/membership check and its
// resolve-on-the-server behavior, plus the routine_sessions UPDATE policy's
// using()/with check() split (family membership gates whether the row is
// touched at all; the *resulting* row's owner must equal the caller, mirrored
// in the PATCH handler below), so it is a faithful regression test for those.
// It does NOT run real Postgres RLS - "an adult from another family cannot
// read events" here proves the repository's query filters by family_id
// correctly, not that Postgres would refuse a mismatched request at the
// database layer. That guarantee lives in the RLS policies themselves
// (0007_role_permissions_hardening.sql, 0011_family_activity_events.sql,
// 0012_routine_sessions_completion_lockdown.sql, 0013_decouple_owner_from_
// auth_users.sql, checked manually via
// supabase/0008_0012_routine_sessions_activity_test.sql).

import 'dart:convert';

import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late _FakeRoutineCompletionServer server;
  late SupabaseClient client;
  late SupabaseRoutineSessionRepository sessionRepository;
  late SupabaseFamilyActivityEventRepository activityRepository;

  Future<void> signInAs(String userId) async {
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'fake-access-token-$userId',
      'token_type': 'bearer',
      'user': {'id': userId},
    }));
    server.currentUserId = userId;
  }

  RoutineSession buildSession({
    required String sessionId,
    required String routineId,
    required String routineTitle,
    required String profileId,
  }) {
    final routine = Routine(
      metadata: EntityMetadata(
        id: routineId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: profileId,
      ),
      profileId: profileId,
      // Deliberately different from the server's seeded title: proves the
      // activity event's routine_title comes from the RPC's own lookup, not
      // from whatever Flutter happens to be holding locally.
      title: '$routineTitle (stale client copy)',
      stepIds: const ['step-1', 'step-2', 'step-3'],
    );
    final steps = [
      for (var i = 0; i < 3; i++)
        RoutineStep(
          metadata: EntityMetadata(
            id: 'step-${i + 1}',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            ownerId: profileId,
          ),
          routineId: routineId,
          title: 'Paso ${i + 1}',
          order: i + 1,
        ),
    ];
    return RoutineSession(
      id: sessionId,
      routine: routine,
      steps: steps,
      activeStepIndex: 3,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: RoutineSessionStatus.completed,
      completedStepIds: const ['step-1', 'step-2', 'step-3'],
      completedAt: DateTime.now(),
    );
  }

  setUp(() {
    server = _FakeRoutineCompletionServer();
    client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: server,
    );
    sessionRepository = SupabaseRoutineSessionRepository(client);
    activityRepository = SupabaseFamilyActivityEventRepository(client);
  });

  test('completing a session creates exactly one activity event, resolved '
      'server-side', () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-1', role: 'parent');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    server.seedSession(sessionId: 'session-1', routineId: 'routine-1');
    await signInAs('adult-1');

    final session = buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    );

    final completed = await sessionRepository.completeSession(session);

    expect(completed.status, RoutineSessionStatus.completed);
    expect(server.routineSessions['session-1']!['session_status'],
        'completed');
    expect(server.familyActivityEvents, hasLength(1));
    final event = server.familyActivityEvents.values.single;
    expect(event['session_id'], 'session-1');
    expect(event['kind'], 'routine_completed');
    // Resolved from the server's own routines/profiles rows, not from the
    // (deliberately different) client-side Routine.title above.
    expect(event['routine_title'], 'Prepararse para la escuela');
    expect(event['profile_display_name'], 'Nico');

    final events = await activityRepository.recentEventsForFamily('family-a');
    expect(events, hasLength(1));
    expect(events.single.routineTitle, 'Prepararse para la escuela');
    expect(events.single.profileDisplayName, 'Nico');
  });

  test('calling completeSession twice does not duplicate the event',
      () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-1', role: 'owner');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    server.seedSession(sessionId: 'session-1', routineId: 'routine-1');
    await signInAs('adult-1');

    final session = buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    );

    await sessionRepository.completeSession(session);
    await sessionRepository.completeSession(session);

    expect(server.familyActivityEvents, hasLength(1));
  });

  test('a caregiver may complete a session, but a viewer may not', () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(
        familyId: 'family-a', userId: 'caregiver-1', role: 'caregiver');
    server.seedMember(familyId: 'family-a', userId: 'viewer-1', role: 'viewer');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    server.seedSession(sessionId: 'session-1', routineId: 'routine-1');

    await signInAs('viewer-1');
    final session = buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    );
    await expectLater(
      sessionRepository.completeSession(session),
      throwsA(isA<PostgrestException>()),
    );
    expect(server.familyActivityEvents, isEmpty);

    await signInAs('caregiver-1');
    await sessionRepository.completeSession(session);
    expect(server.familyActivityEvents, hasLength(1));
  });

  test(
      'a session owned by a different adult can still be completed by '
      'another authorized adult, and owner gets re-stamped to whoever '
      'actually finished it', () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-1', role: 'parent');
    server.seedMember(
        familyId: 'family-a', userId: 'adult-2', role: 'caregiver');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    // adult-1 started the session (or completed earlier steps of it);
    // adult-2 is the one finishing it now. Regression coverage for
    // completeSession's step-tracking update (supabase_repositories.dart) -
    // before it re-stamped owner, this update()'s with check evaluated the
    // *unchanged* owner column ('adult-1') against auth.uid() ('adult-2'),
    // which is never true, so Postgres rejected it every time.
    server.seedSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      ownerId: 'adult-1',
    );
    await signInAs('adult-2');

    final session = buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    );

    final completed = await sessionRepository.completeSession(session);

    expect(completed.status, RoutineSessionStatus.completed);
    expect(server.routineSessions['session-1']!['owner'], 'adult-2');
  });

  test(
      'a session whose owner was set to null (the adult who started it left '
      'the family, migration 0013) can still be completed', () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-2', role: 'owner');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    server.seedSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      ownerId: null,
    );
    await signInAs('adult-2');

    final session = buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    );

    final completed = await sessionRepository.completeSession(session);

    expect(completed.status, RoutineSessionStatus.completed);
    expect(server.routineSessions['session-1']!['owner'], 'adult-2');
  });

  test('recentEventsForFamily only returns events for the requested family',
      () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedFamily(
      familyId: 'family-b',
      profileId: 'profile-mia',
      profileDisplayName: 'Mia',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-1', role: 'owner');
    server.seedMember(familyId: 'family-b', userId: 'adult-2', role: 'owner');
    server.seedRoutine(
        routineId: 'routine-a', profileId: 'profile-nico', title: 'Rutina A');
    server.seedRoutine(
        routineId: 'routine-b', profileId: 'profile-mia', title: 'Rutina B');
    server.seedSession(sessionId: 'session-a', routineId: 'routine-a');
    server.seedSession(sessionId: 'session-b', routineId: 'routine-b');

    await signInAs('adult-1');
    await sessionRepository.completeSession(buildSession(
      sessionId: 'session-a',
      routineId: 'routine-a',
      routineTitle: 'Rutina A',
      profileId: 'profile-nico',
    ));
    await signInAs('adult-2');
    await sessionRepository.completeSession(buildSession(
      sessionId: 'session-b',
      routineId: 'routine-b',
      routineTitle: 'Rutina B',
      profileId: 'profile-mia',
    ));

    final familyAEvents =
        await activityRepository.recentEventsForFamily('family-a');
    expect(familyAEvents, hasLength(1));
    expect(familyAEvents.single.routineTitle, 'Rutina A');

    final familyBEvents =
        await activityRepository.recentEventsForFamily('family-b');
    expect(familyBEvents, hasLength(1));
    expect(familyBEvents.single.routineTitle, 'Rutina B');
  });

  test(
      'deleting a routine (routine_id set null) keeps the event and its '
      'snapshot text', () async {
    server.seedFamily(
      familyId: 'family-a',
      profileId: 'profile-nico',
      profileDisplayName: 'Nico',
    );
    server.seedMember(familyId: 'family-a', userId: 'adult-1', role: 'owner');
    server.seedRoutine(
      routineId: 'routine-1',
      profileId: 'profile-nico',
      title: 'Prepararse para la escuela',
    );
    server.seedSession(sessionId: 'session-1', routineId: 'routine-1');
    await signInAs('adult-1');
    await sessionRepository.completeSession(buildSession(
      sessionId: 'session-1',
      routineId: 'routine-1',
      routineTitle: 'Prepararse para la escuela',
      profileId: 'profile-nico',
    ));

    // Simulates the "on delete set null" foreign key from
    // 0011_family_activity_events.sql: the routine row is gone, but the
    // event keeps its own routine_title snapshot.
    server.routines.remove('routine-1');
    for (final event in server.familyActivityEvents.values) {
      if (event['routine_id'] == 'routine-1') {
        event['routine_id'] = null;
      }
    }

    final events = await activityRepository.recentEventsForFamily('family-a');
    expect(events, hasLength(1));
    expect(events.single.routineId, isNull);
    expect(events.single.routineTitle, 'Prepararse para la escuela');
  });
}

class _RpcException implements Exception {
  const _RpcException(this.message);
  final String message;
}

/// In-memory stand-in for the parts of PostgREST that
/// SupabaseRoutineSessionRepository.completeSession and
/// SupabaseFamilyActivityEventRepository touch: a PATCH endpoint for
/// routine_sessions, a GET endpoint for family_activity_events, and RPC
/// dispatch for complete_routine_session mirroring
/// 0011_family_activity_events.sql.
class _FakeRoutineCompletionServer extends http.BaseClient {
  final Map<String, Map<String, Object?>> routineSessions = {};
  final Map<String, Map<String, Object?>> routines = {};
  final Map<String, Map<String, Object?>> profiles = {};
  final Map<String, Map<String, Object?>> familyMembers = {};
  final Map<String, Map<String, Object?>> familyActivityEvents = {};
  String currentUserId = '';
  int _seq = 0;

  void seedFamily({
    required String familyId,
    required String profileId,
    required String profileDisplayName,
  }) {
    profiles[profileId] = {
      'id': profileId,
      'family_id': familyId,
      'display_name': profileDisplayName,
    };
  }

  void seedMember({
    required String familyId,
    required String userId,
    required String role,
  }) {
    final id = 'member-${++_seq}';
    familyMembers[id] = {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role,
    };
  }

  void seedRoutine({
    required String routineId,
    required String profileId,
    required String title,
  }) {
    routines[routineId] = {
      'id': routineId,
      'profile_id': profileId,
      'title': title,
    };
  }

  void seedSession({
    required String sessionId,
    required String routineId,
    // Nullable and defaulting to null (not to whoever seeds it) on purpose:
    // most tests don't care who owns the session, but the ones that do are
    // specifically about migration 0013's on-delete-set-null behavior, where
    // null is exactly the state a departed adult's sessions end up in.
    String? ownerId,
  }) {
    routineSessions[sessionId] = {
      'id': sessionId,
      'routine_id': routineId,
      'owner': ownerId,
      'session_status': 'running',
      'completed_at': null,
      'updated_at': _now(),
      'active_step_index': 0,
      'completed_step_ids': <String>[],
      'skipped_step_ids': <String>[],
      'extra_minutes_by_step_id': <String, Object?>{},
    };
  }

  /// Mirrors the family-membership + role half of the routine_sessions RLS
  /// policies (using()/with check() both require this - see
  /// 0007_role_permissions_hardening.sql:71-91 and
  /// 0012_routine_sessions_completion_lockdown.sql:65-87). Shared by the
  /// PATCH handler and the RPC so both enforce it the same way.
  bool _isAuthorizedAdult(String routineId, String userId) {
    final routine = routines[routineId];
    if (routine == null) return false;
    final profile = profiles[routine['profile_id']];
    if (profile == null) return false;
    final familyId = profile['family_id'];
    return familyMembers.values.any((member) =>
        member['family_id'] == familyId &&
        member['user_id'] == userId &&
        const {'owner', 'parent', 'caregiver'}.contains(member['role']));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final segments = request.url.pathSegments;
    if (segments.length >= 4 &&
        segments[0] == 'rest' &&
        segments[1] == 'v1' &&
        segments[2] == 'rpc') {
      final functionName = segments[3];
      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      try {
        final result = switch (functionName) {
          'complete_routine_session' => _completeRoutineSession(body),
          _ => throw UnsupportedError('Unhandled rpc: $functionName'),
        };
        return _json(request, 200, result);
      } on _RpcException catch (error) {
        return _json(request, 400, {
          'code': 'P0001',
          'message': error.message,
          'details': null,
          'hint': null,
        });
      }
    }

    if (segments.length == 3 &&
        segments[0] == 'rest' &&
        segments[1] == 'v1' &&
        segments[2] == 'routine_sessions' &&
        request.method == 'PATCH') {
      final idFilter = request.url.queryParameters['id'];
      final sessionId = idFilter?.replaceFirst('eq.', '');
      final row = routineSessions[sessionId];
      if (row == null) {
        return _json(request, 404, {'message': 'Not found'});
      }
      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;

      // Mirrors public.routine_sessions RLS for UPDATE (0007/0012): using()
      // only checks family membership + role - a non-member's update simply
      // matches zero rows, PostgREST reports that as a normal empty success,
      // not an error. with check() additionally requires the *resulting*
      // row's owner to equal the caller; Postgres evaluates this against
      // whatever the row ends up holding, so a column this PATCH doesn't
      // touch keeps its stale (possibly null, possibly someone else's)
      // value - exactly the case migration 0013 and this fake exist to
      // exercise.
      final routineId = row['routine_id'] as String;
      if (!_isAuthorizedAdult(routineId, currentUserId)) {
        return _empty(request, 200);
      }
      final resultingOwner =
          body.containsKey('owner') ? body['owner'] : row['owner'];
      if (resultingOwner != currentUserId) {
        return _json(request, 403, {
          'code': '42501',
          'message':
              'new row violates row-level security policy for table "routine_sessions"',
          'details': null,
          'hint': null,
        });
      }

      row.addAll(body);
      return _empty(request, 200);
    }

    if (segments.length == 3 &&
        segments[0] == 'rest' &&
        segments[1] == 'v1' &&
        segments[2] == 'family_activity_events' &&
        request.method == 'GET') {
      var rows = familyActivityEvents.values.toList();
      final familyIdFilter = request.url.queryParameters['family_id'];
      if (familyIdFilter != null && familyIdFilter.startsWith('eq.')) {
        final target = familyIdFilter.substring(3);
        rows = rows.where((row) => row['family_id'] == target).toList();
      }
      final order = request.url.queryParameters['order'];
      if (order != null) {
        final parts = order.split('.');
        final column = parts.first;
        final ascending = parts.length > 1 && parts[1] == 'asc';
        rows.sort((a, b) {
          final cmp = Comparable.compare(
            a[column] as Comparable,
            b[column] as Comparable,
          );
          return ascending ? cmp : -cmp;
        });
      }
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '');
      if (limit != null && rows.length > limit) {
        rows = rows.sublist(0, limit);
      }
      return _json(request, 200, rows);
    }

    return _json(request, 404, {'message': 'Not found'});
  }

  Map<String, Object?> _completeRoutineSession(Map<String, dynamic> body) {
    if (currentUserId.isEmpty) {
      throw const _RpcException('AUTH_REQUIRED');
    }
    final sessionId = body['target_session_id'] as String?;
    if (sessionId == null) {
      throw const _RpcException('SESSION_ID_REQUIRED');
    }
    final session = routineSessions[sessionId];
    if (session == null) {
      throw const _RpcException('SESSION_NOT_FOUND');
    }
    final routine = routines[session['routine_id']];
    if (routine == null) {
      throw const _RpcException('SESSION_NOT_FOUND');
    }
    final profile = profiles[routine['profile_id']];
    if (profile == null) {
      throw const _RpcException('SESSION_NOT_FOUND');
    }
    final familyId = profile['family_id'] as String;

    if (!_isAuthorizedAdult(session['routine_id'] as String, currentUserId)) {
      throw const _RpcException('SESSION_COMPLETION_NOT_ALLOWED');
    }

    String completedAt;
    if (session['session_status'] == 'completed') {
      completedAt = (session['completed_at'] ?? session['updated_at'] ?? _now())
          as String;
    } else {
      completedAt = _now();
      session['session_status'] = 'completed';
      session['completed_at'] = completedAt;
      session['updated_at'] = completedAt;
    }

    final existing = familyActivityEvents.values.where((event) =>
        event['session_id'] == sessionId &&
        event['kind'] == 'routine_completed');
    String eventId;
    if (existing.isEmpty) {
      eventId = 'event-${++_seq}';
      familyActivityEvents[eventId] = {
        'id': eventId,
        'family_id': familyId,
        'profile_id': profile['id'],
        'routine_id': routine['id'],
        'session_id': sessionId,
        'kind': 'routine_completed',
        'profile_display_name': profile['display_name'],
        'routine_title': routine['title'],
        'created_by': currentUserId,
        'created_at': completedAt,
      };
    } else {
      eventId = existing.first['id'] as String;
    }

    return {
      'session_id': sessionId,
      'status': 'completed',
      'completed_at': completedAt,
      'event_id': eventId,
    };
  }

  String _now() => DateTime.now().toUtc().toIso8601String();

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
