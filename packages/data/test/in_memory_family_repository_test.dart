// InMemoryFamilyRepository is a hand-written mirror of the same rules that
// live in supabase/migrations/0010_invitation_codes.sql (exercised more
// thoroughly, end-to-end, in supabase_invitation_code_test.dart). It backs
// the widget tests for the invitation-code screens, so its own business
// logic gets a direct, fast unit-test pass here too.

import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryFamilyRepository repository;

  setUp(() {
    repository = InMemoryFamilyRepository();
  });

  Future<String> seedOwnedFamily(String userId) async {
    final family =
        await repository.createFamily(ownerUserId: userId, name: 'Familia');
    return family.metadata.id;
  }

  test('self-invitation is rejected', () async {
    final familyId = await seedOwnedFamily('adult-a');

    await expectLater(
      repository.createInvitationWithCode(
        familyId: familyId,
        email: 'adult-a@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      ),
      throwsA(isA<FamilyInvitationException>()
          .having((e) => e.code, 'code', 'INVITATION_SELF_FORBIDDEN')),
    );
  });

  test('a second pending invitation for the same email is rejected', () async {
    final familyId = await seedOwnedFamily('adult-a');
    await repository.createInvitationWithCode(
      familyId: familyId,
      email: 'invitee@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

    await expectLater(
      repository.createInvitationWithCode(
        familyId: familyId,
        email: 'invitee@example.com',
        role: FamilyMemberRole.caregiver,
        invitedByUserId: 'adult-a',
        invitedByUserEmail: 'adult-a@example.com',
      ),
      throwsA(isA<FamilyInvitationException>()
          .having((e) => e.code, 'code', 'INVITATION_ALREADY_PENDING')),
    );
  });

  test('accepting a valid code moves the caller into the correct family',
      () async {
    final familyId = await seedOwnedFamily('adult-a');
    final created = await repository.createInvitationWithCode(
      familyId: familyId,
      email: 'invitee@example.com',
      role: FamilyMemberRole.caregiver,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

    final result = await repository.acceptInvitationByCode(
      code: created.code,
      userId: 'adult-b',
      userEmail: 'invitee@example.com',
    );

    expect(result.familyId, familyId);
    expect(result.role, FamilyMemberRole.caregiver);
    final members = await repository.membersForFamily(familyId);
    expect(members.map((m) => m.userId), contains('adult-b'));
  });

  test('a user with their own family ends up only in the new one', () async {
    final familyIdA = await seedOwnedFamily('adult-a');
    final familyIdB = await seedOwnedFamily('adult-b');
    final created = await repository.createInvitationWithCode(
      familyId: familyIdA,
      email: 'adult-b@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

    await repository.acceptInvitationByCode(
      code: created.code,
      userId: 'adult-b',
      userEmail: 'adult-b@example.com',
    );

    final membersOfA = await repository.membersForFamily(familyIdA);
    final membersOfB = await repository.membersForFamily(familyIdB);
    expect(membersOfA.map((m) => m.userId), contains('adult-b'));
    expect(membersOfB.map((m) => m.userId), isNot(contains('adult-b')));
  });

  test('invalid and mismatched-email codes fail with the same error', () async {
    final familyId = await seedOwnedFamily('adult-a');
    final created = await repository.createInvitationWithCode(
      familyId: familyId,
      email: 'invitee@example.com',
      role: FamilyMemberRole.viewer,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

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

    await expectGenericFailure(() => repository.acceptInvitationByCode(
          code: 'not-a-real-code',
          userId: 'adult-x',
          userEmail: 'anyone@example.com',
        ));

    await expectGenericFailure(() => repository.acceptInvitationByCode(
          code: created.code,
          userId: 'adult-x',
          userEmail: 'wrong-address@example.com',
        ));
  });

  test('a canceled invitation code stops working', () async {
    final familyId = await seedOwnedFamily('adult-a');
    final created = await repository.createInvitationWithCode(
      familyId: familyId,
      email: 'invitee@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

    await repository.cancelInvitation(
      invitationId: created.invitationId,
      userId: 'adult-a',
    );

    await expectLater(
      repository.acceptInvitationByCode(
        code: created.code,
        userId: 'adult-b',
        userEmail: 'invitee@example.com',
      ),
      throwsA(isA<FamilyInvitationException>()
          .having((e) => e.code, 'code', 'INVITATION_CODE_INVALID_OR_EXPIRED')),
    );
  });

  test('only owner/parent can cancel an invitation', () async {
    final familyId = await seedOwnedFamily('adult-a');
    final created = await repository.createInvitationWithCode(
      familyId: familyId,
      email: 'invitee@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: 'adult-a',
      invitedByUserEmail: 'adult-a@example.com',
    );

    await expectLater(
      repository.cancelInvitation(
        invitationId: created.invitationId,
        userId: 'someone-not-in-the-family',
      ),
      throwsA(isA<FamilyInvitationException>()
          .having((e) => e.code, 'code', 'INVITATION_CANCEL_FORBIDDEN')),
    );
  });
}
