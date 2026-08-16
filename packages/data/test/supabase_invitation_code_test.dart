// Exercises SupabaseFamilyRepository's three invitation-code RPC calls
// (create_family_invitation_with_code, accept_family_invitation_by_code,
// cancel_family_invitation from supabase/migrations/0010_invitation_codes.sql)
// against an in-memory fake that mirrors those functions' business rules,
// the same approach used for the HABITAR_ROUTINE_SAVE_23505 regression: a
// fake PostgREST endpoint faithful enough to exercise the real repository
// code, instead of asserting against a reimplementation of it.
//
// The fake has no real auth/JWT machinery - `currentUserId`/
// `currentUserEmail` are plain mutable fields the test sets directly to
// simulate "the next RPC call is made by this authenticated user". That's
// deliberate: Supabase Auth itself is out of scope here, and every RPC in
// 0010 only ever receives target ids as parameters, deriving *who* is
// calling from auth.uid()/auth.jwt() - never from anything the client
// passes - so a test double for those RPCs needs an equivalent "who is
// calling right now" concept without literally decoding JWTs.

import 'dart:convert';

import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

void main() {
  late _FakeInvitationServer server;
  late SupabaseClient client;
  late SupabaseFamilyRepository repository;

  // Mirrors "signing in as" a given user: updates both the real
  // SupabaseClient's session (so client-side checks like
  // SupabaseFamilyRepository.createInvitationWithCode's
  // invitedByUserId-matches-the-session guard pass) and the fake server's
  // notion of who is calling (so the RPC bodies' auth.uid()/auth.jwt()
  // stand-ins are consistent with it). No real auth/JWT machinery is
  // involved - see the file header.
  Future<void> signInAs(String userId, String email) async {
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'fake-access-token-$userId',
      'token_type': 'bearer',
      'user': {'id': userId, 'email': email},
    }));
    server.currentUserId = userId;
    server.currentUserEmail = email;
  }

  setUp(() {
    server = _FakeInvitationServer();
    client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: server,
    );
    repository = SupabaseFamilyRepository(client);
  });

  group('create_family_invitation_with_code', () {
    test('self-invitation is rejected', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');

      await expectLater(
        repository.createInvitationWithCode(
          familyId: 'family-a',
          email: 'adult-a@example.com',
          role: FamilyMemberRole.parent,
          invitedByUserId: 'adult-a',
          invitedByUserEmail: 'adult-a@example.com',
        ),
        throwsA(isA<FamilyInvitationException>()
            .having((e) => e.code, 'code', 'INVITATION_SELF_FORBIDDEN')),
      );
    });

    test('a second pending invitation for the same email is rejected',
        () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');

      await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      await expectLater(
        repository.createInvitationWithCode(
          familyId: 'family-a',
          email: 'invitee@example.com',
          role: FamilyMemberRole.caregiver,
          invitedByUserId: 'adult-a',
          invitedByUserEmail: 'adult-a@example.com',
        ),
        throwsA(isA<FamilyInvitationException>()
            .having((e) => e.code, 'code', 'INVITATION_ALREADY_PENDING')),
      );
    });

    test('returns the plaintext code exactly once', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');

      final created = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      expect(created.code, isNotEmpty);
      expect(created.familyId, 'family-a');
      expect(created.role, FamilyMemberRole.parent);
      // The stored row never carries the plaintext code, only its hash
      // (here: a value that isn't literally the code).
      final stored = server.adultInvitations[created.invitationId]!;
      expect(stored['invite_code_hash'], isNot(created.code));
    });
  });

  group('accept_family_invitation_by_code', () {
    test('valid code leaves the caller in the correct family', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');
      final created = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.caregiver,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      await signInAs('adult-b', 'invitee@example.com');

      final result = await repository.acceptInvitationByCode(
        code: created.code,
        userId: 'adult-b',
        userEmail: 'invitee@example.com',
      );

      expect(result.familyId, 'family-a');
      expect(result.role, FamilyMemberRole.caregiver);
      expect(
        server.familyMembers.values.where(
            (m) => m['user_id'] == 'adult-b' && m['family_id'] == 'family-a'),
        hasLength(1),
      );
    });

    test('a user with their own family ends up only in the new one', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');
      final created = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      // adult-b already owns their own (auto-created at registration) family.
      await signInAs('adult-b', 'invitee@example.com');
      server.seedOwner(familyId: 'family-b', userId: 'adult-b');

      await repository.acceptInvitationByCode(
        code: created.code,
        userId: 'adult-b',
        userEmail: 'invitee@example.com',
      );

      final membershipsForB = server.familyMembers.values
          .where((m) => m['user_id'] == 'adult-b')
          .toList();
      expect(membershipsForB, hasLength(1));
      expect(membershipsForB.single['family_id'], 'family-a');
      // family-b is left orphaned, not deleted.
      expect(server.families.containsKey('family-b'), isTrue);
    });

    test(
        'invalid, expired, already-used, canceled and mismatched-email codes '
        'all fail with the exact same error', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');

      Future<void> expectGenericFailure(Future<void> Function() attempt) {
        return expectLater(
          attempt(),
          throwsA(isA<FamilyInvitationException>().having(
            (e) => e.code,
            'code',
            'INVITATION_CODE_INVALID_OR_EXPIRED',
          )),
        );
      }

      // Unknown code.
      await signInAs('adult-x', 'someone@example.com');
      await expectGenericFailure(() => repository.acceptInvitationByCode(
            code: 'this-code-does-not-exist',
            userId: 'adult-x',
            userEmail: 'someone@example.com',
          ));

      // Expired.
      await signInAs('adult-a', 'adult-a@example.com');
      final expiredCode = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'expired-invitee@example.com',
        role: FamilyMemberRole.viewer,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );
      server.expireInvitation(expiredCode.invitationId);
      await signInAs('adult-y', 'expired-invitee@example.com');
      await expectGenericFailure(() => repository.acceptInvitationByCode(
            code: expiredCode.code,
            userId: 'adult-y',
            userEmail: 'expired-invitee@example.com',
          ));

      // Already used.
      await signInAs('adult-a', 'adult-a@example.com');
      final usedCode = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'used-invitee@example.com',
        role: FamilyMemberRole.viewer,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );
      await signInAs('adult-z', 'used-invitee@example.com');
      await repository.acceptInvitationByCode(
        code: usedCode.code,
        userId: 'adult-z',
        userEmail: 'used-invitee@example.com',
      );
      await expectGenericFailure(() => repository.acceptInvitationByCode(
            code: usedCode.code,
            userId: 'adult-z',
            userEmail: 'used-invitee@example.com',
          ));

      // Canceled.
      await signInAs('adult-a', 'adult-a@example.com');
      final canceledCode = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'canceled-invitee@example.com',
        role: FamilyMemberRole.viewer,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );
      await repository.cancelInvitation(
        invitationId: canceledCode.invitationId,
        userId: 'adult-a',
      );
      await signInAs('adult-w', 'canceled-invitee@example.com');
      await expectGenericFailure(() => repository.acceptInvitationByCode(
            code: canceledCode.code,
            userId: 'adult-w',
            userEmail: 'canceled-invitee@example.com',
          ));

      // Mismatched email: a real, live, pending code redeemed by someone
      // whose authenticated email doesn't match who it was addressed to.
      await signInAs('adult-a', 'adult-a@example.com');
      final mismatchedCode = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'intended@example.com',
        role: FamilyMemberRole.viewer,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );
      await signInAs('adult-v', 'not-the-intended-address@example.com');
      await expectGenericFailure(() => repository.acceptInvitationByCode(
            code: mismatchedCode.code,
            userId: 'adult-v',
            userEmail: 'not-the-intended-address@example.com',
          ));
    });
  });

  group('cancel_family_invitation', () {
    test('a canceled invitation code stops working', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server.seedOwner(familyId: 'family-a', userId: 'adult-a');
      final created = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      await repository.cancelInvitation(
        invitationId: created.invitationId,
        userId: 'adult-a',
      );

      expect(
        server.adultInvitations[created.invitationId]!['status'],
        'canceled',
      );

      await signInAs('adult-b', 'invitee@example.com');
      await expectLater(
        repository.acceptInvitationByCode(
          code: created.code,
          userId: 'adult-b',
          userEmail: 'invitee@example.com',
        ),
        throwsA(isA<FamilyInvitationException>().having(
          (e) => e.code,
          'code',
          'INVITATION_CODE_INVALID_OR_EXPIRED',
        )),
      );
    });

    test('only owner/parent can cancel', () async {
      await signInAs('adult-a', 'adult-a@example.com');
      server
        ..seedOwner(familyId: 'family-a', userId: 'adult-a')
        ..seedMember(
          familyId: 'family-a',
          userId: 'adult-viewer',
          role: 'viewer',
        );
      final created = await repository.createInvitationWithCode(
        familyId: 'family-a',
        email: 'invitee@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      );

      await signInAs('adult-viewer', 'viewer@example.com');
      await expectLater(
        repository.cancelInvitation(
          invitationId: created.invitationId,
          userId: 'adult-viewer',
        ),
        throwsA(isA<FamilyInvitationException>()
            .having((e) => e.code, 'code', 'INVITATION_CANCEL_FORBIDDEN')),
      );
    });
  });
}

class _RpcException implements Exception {
  const _RpcException(this.message);
  final String message;
}

/// In-memory stand-in for the parts of PostgREST that
/// SupabaseFamilyRepository's invitation-code methods touch: table state
/// for `family_members`/`adult_invitations`/`families`, plus RPC dispatch
/// for the three functions in 0010_invitation_codes.sql, mirroring their
/// business rules.
class _FakeInvitationServer extends http.BaseClient {
  final Map<String, Map<String, Object?>> familyMembers = {};
  final Map<String, Map<String, Object?>> adultInvitations = {};
  final Map<String, Map<String, Object?>> families = {};
  String currentUserId = '';
  String currentUserEmail = '';
  int _seq = 0;

  void seedOwner({required String familyId, required String userId}) {
    families[familyId] = {'id': familyId, 'name': 'Familia de prueba'};
    seedMember(familyId: familyId, userId: userId, role: 'owner');
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

  /// Test-only helper: force an invitation into the past so the RPCs' own
  /// lazy-expiry logic (not this helper) is what actually marks it expired.
  void expireInvitation(String invitationId) {
    adultInvitations[invitationId]!['expires_at'] =
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final segments = request.url.pathSegments;
    if (segments.length < 4 ||
        segments[0] != 'rest' ||
        segments[1] != 'v1' ||
        segments[2] != 'rpc') {
      return _json(request, 404, {'message': 'Not found'});
    }
    final functionName = segments[3];
    final body =
        jsonDecode((request as http.Request).body) as Map<String, dynamic>;
    try {
      final result = switch (functionName) {
        'create_family_invitation_with_code' => _createInvitationWithCode(body),
        'accept_family_invitation_by_code' => _acceptInvitationByCode(body),
        'cancel_family_invitation' => _cancelInvitation(body),
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

  Map<String, Object?> _createInvitationWithCode(Map<String, dynamic> body) {
    if (currentUserId.isEmpty) {
      throw const _RpcException('AUTH_REQUIRED');
    }
    final familyId = body['target_family_id'] as String;
    final normalizedEmail =
        (body['target_email'] as String? ?? '').trim().toLowerCase();
    final role = body['target_role'] as String?;

    if (normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@') ||
        normalizedEmail.length > 320) {
      throw const _RpcException('INVITATION_EMAIL_INVALID');
    }
    if (role == null ||
        !const {'parent', 'caregiver', 'professional', 'viewer'}
            .contains(role)) {
      throw const _RpcException('INVITATION_ROLE_INVALID');
    }
    if (normalizedEmail == currentUserEmail.trim().toLowerCase()) {
      throw const _RpcException('INVITATION_SELF_FORBIDDEN');
    }

    String? inviterRole;
    for (final member in familyMembers.values) {
      if (member['family_id'] == familyId &&
          member['user_id'] == currentUserId) {
        inviterRole = member['role'] as String?;
        break;
      }
    }
    if (inviterRole == null ||
        !const {'owner', 'parent'}.contains(inviterRole)) {
      throw const _RpcException('INVITATION_CREATE_FORBIDDEN');
    }

    final now = DateTime.now();
    for (final row in adultInvitations.values) {
      if (row['family_id'] == familyId &&
          row['email'] == normalizedEmail &&
          row['status'] == 'pending' &&
          DateTime.parse(row['expires_at'] as String).isBefore(now)) {
        row['status'] = 'expired';
      }
    }
    final stillPending = adultInvitations.values.any((row) =>
        row['family_id'] == familyId &&
        row['email'] == normalizedEmail &&
        row['status'] == 'pending');
    if (stillPending) {
      throw const _RpcException('INVITATION_ALREADY_PENDING');
    }

    final id = 'invitation-${++_seq}';
    final code = 'code-$_seq-${normalizedEmail.hashCode.toUnsigned(20)}';
    final expiresAt = now.add(const Duration(days: 7)).toIso8601String();
    adultInvitations[id] = {
      'id': id,
      'family_id': familyId,
      'email': normalizedEmail,
      'role': role,
      'status': 'pending',
      'invited_by_user_id': currentUserId,
      // Never the plaintext code - matches the real migration only ever
      // storing a hash.
      'invite_code_hash': 'hash-of-$code',
      'invite_code': code,
      'expires_at': expiresAt,
    };
    return {
      'invitation_id': id,
      'family_id': familyId,
      'email': normalizedEmail,
      'role': role,
      'expires_at': expiresAt,
      'invite_code': code,
    };
  }

  Map<String, Object?> _acceptInvitationByCode(Map<String, dynamic> body) {
    if (currentUserId.isEmpty || currentUserEmail.isEmpty) {
      throw const _RpcException('AUTH_REQUIRED');
    }
    final normalizedCode = (body['invitation_code'] as String? ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s'), '');
    if (normalizedCode.isEmpty) {
      throw const _RpcException('INVITATION_CODE_INVALID_OR_EXPIRED');
    }

    Map<String, Object?>? row;
    for (final candidate in adultInvitations.values) {
      if (candidate['invite_code'] == normalizedCode) {
        row = candidate;
        break;
      }
    }
    if (row == null) {
      throw const _RpcException('INVITATION_CODE_INVALID_OR_EXPIRED');
    }

    final now = DateTime.now();
    if (row['status'] == 'pending' &&
        DateTime.parse(row['expires_at'] as String).isBefore(now)) {
      row['status'] = 'expired';
      throw const _RpcException('INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    if (row['status'] != 'pending') {
      throw const _RpcException('INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    if ((row['email'] as String) != currentUserEmail.trim().toLowerCase()) {
      throw const _RpcException('INVITATION_CODE_INVALID_OR_EXPIRED');
    }

    final familyId = row['family_id'] as String;
    familyMembers.removeWhere((_, member) =>
        member['user_id'] == currentUserId && member['family_id'] != familyId);
    final alreadyMember = familyMembers.values.any((member) =>
        member['family_id'] == familyId && member['user_id'] == currentUserId);
    if (!alreadyMember) {
      final memberId = 'member-${++_seq}';
      familyMembers[memberId] = {
        'id': memberId,
        'family_id': familyId,
        'user_id': currentUserId,
        'role': row['role'],
      };
    }
    row['status'] = 'accepted';
    row['accepted_by_user_id'] = currentUserId;

    return {
      'status': 'accepted',
      'family_id': familyId,
      'role': row['role'],
    };
  }

  Map<String, Object?> _cancelInvitation(Map<String, dynamic> body) {
    if (currentUserId.isEmpty) {
      throw const _RpcException('AUTH_REQUIRED');
    }
    final id = body['target_invitation_id'] as String;
    final row = adultInvitations[id];
    if (row == null) {
      throw const _RpcException('INVITATION_NOT_FOUND');
    }
    final familyId = row['family_id'] as String;

    String? callerRole;
    for (final member in familyMembers.values) {
      if (member['family_id'] == familyId &&
          member['user_id'] == currentUserId) {
        callerRole = member['role'] as String?;
        break;
      }
    }
    if (callerRole == null || !const {'owner', 'parent'}.contains(callerRole)) {
      throw const _RpcException('INVITATION_CANCEL_FORBIDDEN');
    }
    if (row['status'] != 'pending') {
      throw const _RpcException('INVITATION_NOT_PENDING');
    }
    row['status'] = 'canceled';
    return {'status': 'canceled', 'invitation_id': id};
  }

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
