import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class InMemoryAuthRepository implements AuthRepository {
  final Map<String, User> _usersByEmail = {};
  User? _current;

  @override
  Future<User?> currentUser() async => _current;

  @override
  Future<User> registerAdult(
      {required String displayName,
      required String email,
      required String password}) async {
    final now = DateTime.now();
    _current = User(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: 'self'),
      displayName: displayName,
      email: email,
    );
    _usersByEmail[email] = _current!;
    return _current!;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final user = _usersByEmail[email];
    if (user == null) {
      throw StateError('No local user found for $email.');
    }
    _current = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required Uri redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({required String password}) async {}
}

class InMemoryFamilyRepository implements FamilyRepository {
  final Map<String, Family> _familiesByOwner = {};
  final List<FamilyMember> _members = [];
  final List<AdultInvitation> _invitations = [];
  final Map<String, String> _invitationCodes = {};
  // Keyed by userId, not exposed on FamilyDepartureNotice itself - on
  // Supabase, RLS already scopes departed_family_notices to the caller, so
  // the domain entity has no reason to carry whose notice it is.
  final Map<String, List<FamilyDepartureNotice>> _departureNoticesByUser = {};

  @override
  Future<Family> createFamily(
      {required String ownerUserId, required String name}) async {
    final now = DateTime.now();
    final family = Family(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: ownerUserId),
      name: name,
      adultUserIds: [ownerUserId],
    );
    _familiesByOwner[ownerUserId] = family;
    _members.add(FamilyMember(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: ownerUserId),
      familyId: family.metadata.id,
      userId: ownerUserId,
      role: FamilyMemberRole.owner,
    ));
    return family;
  }

  @override
  Future<Family?> currentFamily(String ownerUserId) async {
    final direct = _familiesByOwner[ownerUserId];
    if (direct != null) {
      return direct;
    }
    final memberships =
        _members.where((member) => member.userId == ownerUserId);
    if (memberships.isEmpty) {
      return null;
    }
    final familyId = memberships.first.familyId;
    final matches = _familiesByOwner.values
        .where((family) => family.metadata.id == familyId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<FamilyMember>> membersForFamily(String familyId) async {
    return _members
        .where((member) => member.familyId == familyId)
        .toList(growable: false);
  }

  @override
  Future<AdultInvitation> createAdultInvitation({
    required String familyId,
    required String email,
    required FamilyMemberRole role,
    required String invitedByUserId,
  }) async {
    if (role == FamilyMemberRole.owner) {
      throw StateError('Owner role cannot be invited.');
    }
    final inviter = _members.where((member) =>
        member.familyId == familyId && member.userId == invitedByUserId);
    if (inviter.isEmpty ||
        !const {FamilyMemberRole.owner, FamilyMemberRole.parent}
            .contains(inviter.first.role)) {
      throw StateError('User cannot create family invitations.');
    }
    final now = DateTime.now();
    final invitation = AdultInvitation(
      metadata: EntityMetadata(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          ownerId: invitedByUserId),
      familyId: familyId,
      email: email.trim().toLowerCase(),
      role: role,
      status: AdultInvitationStatus.pending,
      expiresAt: now.add(const Duration(days: 14)),
      invitedByUserId: invitedByUserId,
    );
    _invitations.add(invitation);
    return invitation;
  }

  @override
  Future<List<AdultInvitation>> invitationsForFamily(String familyId) async {
    return _invitations
        .where((invitation) => invitation.familyId == familyId)
        .toList(growable: false);
  }

  @override
  Future<List<PendingFamilyInvitation>> pendingInvitationsForEmail(
      String authenticatedEmail) async {
    final email = authenticatedEmail.trim().toLowerCase();
    final now = DateTime.now();
    final invitations = _invitations.where((invitation) {
      return invitation.status == AdultInvitationStatus.pending &&
          invitation.expiresAt.isAfter(now) &&
          invitation.email.trim().toLowerCase() == email;
    });
    return [
      for (final invitation in invitations)
        PendingFamilyInvitation(
          invitation: invitation,
          familyName: _familiesByOwner.values
              .firstWhere(
                (family) => family.metadata.id == invitation.familyId,
                orElse: () => Family(
                  metadata: EntityMetadata(
                    id: invitation.familyId,
                    createdAt: now,
                    updatedAt: now,
                    ownerId: invitation.invitedByUserId ?? invitation.familyId,
                  ),
                  name: 'Familia',
                  adultUserIds: const [],
                ),
              )
              .name,
        ),
    ];
  }

  @override
  Future<FamilyMember> acceptInvitation({
    required String invitationId,
    required String userId,
    required String userEmail,
  }) async {
    final index = _invitations
        .indexWhere((invitation) => invitation.metadata.id == invitationId);
    if (index < 0) {
      throw StateError('Invitation not found: $invitationId');
    }
    final invitation = _invitations[index];
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (invitation.email != normalizedEmail) {
      throw StateError('Invitation does not belong to $normalizedEmail.');
    }
    final now = DateTime.now();
    final existingMembers = _members.where((member) =>
        member.familyId == invitation.familyId && member.userId == userId);
    if (existingMembers.isNotEmpty) {
      _invitations[index] = _acceptedInvitation(invitation, userId, now);
      return existingMembers.first;
    }
    if (invitation.expiresAt.isBefore(now)) {
      _invitations[index] = AdultInvitation(
        metadata: EntityMetadata(
          id: invitation.metadata.id,
          createdAt: invitation.metadata.createdAt,
          updatedAt: now,
          ownerId: invitation.metadata.ownerId,
        ),
        familyId: invitation.familyId,
        email: invitation.email,
        role: invitation.role,
        status: AdultInvitationStatus.expired,
        expiresAt: invitation.expiresAt,
        invitedByUserId: invitation.invitedByUserId,
        acceptedByUserId: invitation.acceptedByUserId,
      );
      throw StateError('Invitation has expired.');
    }
    if (invitation.status != AdultInvitationStatus.pending) {
      throw StateError('Invitation is not pending.');
    }
    final member = FamilyMember(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: userId),
      familyId: invitation.familyId,
      userId: userId,
      role: invitation.role,
      email: invitation.email,
    );
    _members.add(member);
    _invitations[index] = _acceptedInvitation(invitation, userId, now);
    return member;
  }

  AdultInvitation _acceptedInvitation(
    AdultInvitation invitation,
    String userId,
    DateTime now,
  ) {
    return AdultInvitation(
      metadata: EntityMetadata(
        id: invitation.metadata.id,
        createdAt: invitation.metadata.createdAt,
        updatedAt: now,
        ownerId: invitation.metadata.ownerId,
      ),
      familyId: invitation.familyId,
      email: invitation.email,
      role: invitation.role,
      status: AdultInvitationStatus.accepted,
      expiresAt: invitation.expiresAt,
      invitedByUserId: invitation.invitedByUserId,
      acceptedByUserId: userId,
    );
  }

  @override
  Future<InvitationCodeCreated> createInvitationWithCode({
    required String familyId,
    required String email,
    required FamilyMemberRole role,
    required String invitedByUserId,
    required String invitedByUserEmail,
  }) async {
    const allowedRoles = {
      FamilyMemberRole.parent,
      FamilyMemberRole.caregiver,
      FamilyMemberRole.professional,
      FamilyMemberRole.viewer,
    };
    if (!allowedRoles.contains(role)) {
      throw const FamilyInvitationException('INVITATION_ROLE_INVALID');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const FamilyInvitationException('INVITATION_EMAIL_INVALID');
    }
    if (normalizedEmail == invitedByUserEmail.trim().toLowerCase()) {
      throw const FamilyInvitationException('INVITATION_SELF_FORBIDDEN');
    }
    final inviter = _members.where((member) =>
        member.familyId == familyId && member.userId == invitedByUserId);
    if (inviter.isEmpty ||
        !const {FamilyMemberRole.owner, FamilyMemberRole.parent}
            .contains(inviter.first.role)) {
      throw const FamilyInvitationException('INVITATION_CREATE_FORBIDDEN');
    }
    final now = DateTime.now();
    for (var i = 0; i < _invitations.length; i++) {
      final existing = _invitations[i];
      if (existing.familyId == familyId &&
          existing.email == normalizedEmail &&
          existing.status == AdultInvitationStatus.pending &&
          existing.expiresAt.isBefore(now)) {
        _invitations[i] =
            _invitationWithStatus(existing, AdultInvitationStatus.expired, now);
      }
    }
    final stillPending = _invitations.any((invitation) =>
        invitation.familyId == familyId &&
        invitation.email == normalizedEmail &&
        invitation.status == AdultInvitationStatus.pending);
    if (stillPending) {
      throw const FamilyInvitationException('INVITATION_ALREADY_PENDING');
    }
    final invitation = AdultInvitation(
      metadata: EntityMetadata(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          ownerId: invitedByUserId),
      familyId: familyId,
      email: normalizedEmail,
      role: role,
      status: AdultInvitationStatus.pending,
      expiresAt: now.add(const Duration(days: 7)),
      invitedByUserId: invitedByUserId,
    );
    _invitations.add(invitation);
    final code = _uuid.v4().replaceAll('-', '');
    _invitationCodes[invitation.metadata.id] = code;
    return InvitationCodeCreated(
      invitationId: invitation.metadata.id,
      familyId: familyId,
      email: normalizedEmail,
      role: role,
      expiresAt: invitation.expiresAt,
      code: code,
    );
  }

  @override
  Future<InvitationCodeAccepted> acceptInvitationByCode({
    required String code,
    required String userId,
    required String userEmail,
  }) async {
    final normalizedCode =
        code.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
    if (normalizedCode.isEmpty) {
      throw const FamilyInvitationException(
          'INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    final index = _invitations.indexWhere((invitation) =>
        _invitationCodes[invitation.metadata.id] == normalizedCode);
    if (index < 0) {
      throw const FamilyInvitationException(
          'INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    var invitation = _invitations[index];
    final now = DateTime.now();
    if (invitation.status == AdultInvitationStatus.pending &&
        invitation.expiresAt.isBefore(now)) {
      invitation =
          _invitationWithStatus(invitation, AdultInvitationStatus.expired, now);
      _invitations[index] = invitation;
      throw const FamilyInvitationException(
          'INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    if (invitation.status != AdultInvitationStatus.pending) {
      throw const FamilyInvitationException(
          'INVITATION_CODE_INVALID_OR_EXPIRED');
    }
    if (invitation.email != userEmail.trim().toLowerCase()) {
      throw const FamilyInvitationException(
          'INVITATION_CODE_INVALID_OR_EXPIRED');
    }

    // One family per adult: leave every other family before joining this
    // one. Abandoned families are left in place, just like the Supabase RPC.
    _members.removeWhere((member) =>
        member.userId == userId && member.familyId != invitation.familyId);
    final alreadyMember = _members.any((member) =>
        member.familyId == invitation.familyId && member.userId == userId);
    if (!alreadyMember) {
      _members.add(FamilyMember(
        metadata: EntityMetadata(
            id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: userId),
        familyId: invitation.familyId,
        userId: userId,
        role: invitation.role,
        email: invitation.email,
      ));
    }
    _invitations[index] = _invitationWithStatus(
      invitation,
      AdultInvitationStatus.accepted,
      now,
      acceptedByUserId: userId,
    );
    return InvitationCodeAccepted(
      familyId: invitation.familyId,
      role: invitation.role,
    );
  }

  @override
  Future<void> cancelInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final index = _invitations
        .indexWhere((invitation) => invitation.metadata.id == invitationId);
    if (index < 0) {
      throw const FamilyInvitationException('INVITATION_NOT_FOUND');
    }
    final invitation = _invitations[index];
    final canceller = _members.where((member) =>
        member.familyId == invitation.familyId && member.userId == userId);
    if (canceller.isEmpty ||
        !const {FamilyMemberRole.owner, FamilyMemberRole.parent}
            .contains(canceller.first.role)) {
      throw const FamilyInvitationException('INVITATION_CANCEL_FORBIDDEN');
    }
    if (invitation.status != AdultInvitationStatus.pending) {
      throw const FamilyInvitationException('INVITATION_NOT_PENDING');
    }
    _invitations[index] = _invitationWithStatus(
      invitation,
      AdultInvitationStatus.canceled,
      DateTime.now(),
    );
  }

  AdultInvitation _invitationWithStatus(
    AdultInvitation invitation,
    AdultInvitationStatus status,
    DateTime now, {
    String? acceptedByUserId,
  }) {
    return AdultInvitation(
      metadata: EntityMetadata(
        id: invitation.metadata.id,
        createdAt: invitation.metadata.createdAt,
        updatedAt: now,
        ownerId: invitation.metadata.ownerId,
      ),
      familyId: invitation.familyId,
      email: invitation.email,
      role: invitation.role,
      status: status,
      expiresAt: invitation.expiresAt,
      invitedByUserId: invitation.invitedByUserId,
      acceptedByUserId: acceptedByUserId ?? invitation.acceptedByUserId,
    );
  }

  @override
  Future<void> deleteFamily({
    required String familyId,
    required String userId,
  }) async {
    final isOwner = _members.any((member) =>
        member.familyId == familyId &&
        member.userId == userId &&
        member.role == FamilyMemberRole.owner);
    if (!isOwner) {
      throw const FamilyLifecycleException('FAMILY_DELETE_FORBIDDEN');
    }
    final familyEntries = _familiesByOwner.entries
        .where((entry) => entry.value.metadata.id == familyId)
        .toList(growable: false);
    final familyName =
        familyEntries.isEmpty ? 'Familia' : familyEntries.first.value.name;

    // Notify every other adult before cutting their access, same order as
    // delete_family in 0014_family_deletion.sql - never the one deleting.
    final departingMembers = _members
        .where((member) =>
            member.familyId == familyId && member.userId != userId)
        .toList(growable: false);
    for (final member in departingMembers) {
      _departureNoticesByUser.putIfAbsent(member.userId, () => []).add(
            FamilyDepartureNotice(
              id: _uuid.v4(),
              familyName: familyName,
              deletedAt: DateTime.now(),
            ),
          );
    }

    if (familyEntries.isNotEmpty) {
      _familiesByOwner.remove(familyEntries.first.key);
    }
    _members.removeWhere((member) => member.familyId == familyId);
  }

  @override
  Future<void> transferFamilyOwnership({
    required String userId,
    required String newOwnerUserId,
  }) async {
    final ownerIndex = _members.indexWhere((member) =>
        member.userId == userId && member.role == FamilyMemberRole.owner);
    if (ownerIndex < 0) {
      throw const FamilyLifecycleException('TRANSFER_FORBIDDEN');
    }
    final familyId = _members[ownerIndex].familyId;
    final targetIndex = _members.indexWhere((member) =>
        member.familyId == familyId && member.userId == newOwnerUserId);
    if (targetIndex < 0) {
      throw const FamilyLifecycleException('TRANSFER_TARGET_NOT_MEMBER');
    }
    _members[targetIndex] =
        _withRole(_members[targetIndex], FamilyMemberRole.owner);
    _members[ownerIndex] =
        _withRole(_members[ownerIndex], FamilyMemberRole.parent);
  }

  @override
  Future<void> deleteMyAccount({required String userId}) async {
    final ownerMembership = _members.where((member) =>
        member.userId == userId && member.role == FamilyMemberRole.owner);
    if (ownerMembership.isNotEmpty) {
      final familyId = ownerMembership.first.familyId;
      final otherMembers = _members.where((member) =>
          member.familyId == familyId && member.userId != userId);
      if (otherMembers.isNotEmpty) {
        throw const FamilyLifecycleException(
            'OWNER_MUST_TRANSFER_OR_DELETE_FAMILY');
      }
      // Sole adult of their family: deleting the personal account IS
      // deleting the family - same rule as delete_my_account server-side.
      await deleteFamily(familyId: familyId, userId: userId);
    } else {
      _members.removeWhere((member) => member.userId == userId);
    }
  }

  @override
  Future<List<FamilyDepartureNotice>> departureNotices(String userId) async {
    return List.unmodifiable(_departureNoticesByUser[userId] ?? const []);
  }

  @override
  Future<void> dismissDepartureNotice({
    required String noticeId,
    required String userId,
  }) async {
    _departureNoticesByUser[userId]
        ?.removeWhere((notice) => notice.id == noticeId);
  }

  FamilyMember _withRole(FamilyMember member, FamilyMemberRole role) {
    return FamilyMember(
      metadata: member.metadata,
      familyId: member.familyId,
      userId: member.userId,
      role: role,
      email: member.email,
      displayName: member.displayName,
    );
  }
}

class InMemoryProfileRepository implements ProfileRepository {
  final List<ChildProfile> _children = [];
  final List<TeenProfile> _teens = [];

  @override
  Future<List<ChildProfile>> childProfiles(String familyId) async {
    return _children
        .where((profile) => profile.familyId == familyId)
        .toList(growable: false);
  }

  @override
  Future<ChildProfile> createChildProfile(
      {required String familyId,
      required String displayName,
      required int age}) async {
    final now = DateTime.now();
    final profile = ChildProfile(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: familyId),
      familyId: familyId,
      displayName: displayName,
      age: age,
    );
    _children.add(profile);
    return profile;
  }

  @override
  Future<TeenProfile> createTeenProfile(
      {required String familyId,
      required String displayName,
      required int age}) async {
    final now = DateTime.now();
    final profile = TeenProfile(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: familyId),
      familyId: familyId,
      displayName: displayName,
      age: age,
    );
    _teens.add(profile);
    return profile;
  }

  @override
  Future<List<TeenProfile>> teenProfiles(String familyId) async {
    return _teens
        .where((profile) => profile.familyId == familyId)
        .toList(growable: false);
  }

  /// Not part of [ProfileRepository]: used only by
  /// [InMemoryRoutineSessionRepository] to resolve a routine's family/display
  /// name when recording a family activity event, mirroring what
  /// complete_routine_session resolves server-side on Supabase.
  ({String familyId, String displayName})? summaryForProfileId(
      String profileId) {
    for (final child in _children) {
      if (child.metadata.id == profileId) {
        return (familyId: child.familyId, displayName: child.displayName);
      }
    }
    for (final teen in _teens) {
      if (teen.metadata.id == profileId) {
        return (familyId: teen.familyId, displayName: teen.displayName);
      }
    }
    return null;
  }
}

class InMemoryAdultProfileRepository implements AdultProfileRepository {
  final List<AdultProfile> _adultProfiles = [];

  @override
  Future<AdultProfile> createAdultProfile({
    required String familyId,
    required String profileId,
    required String displayName,
    required AdultProfileKind kind,
    String? email,
    String? roleLabel,
  }) async {
    final now = DateTime.now();
    final adultProfile = AdultProfile(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: familyId),
      familyId: familyId,
      profileId: profileId,
      displayName: displayName,
      kind: kind,
      email: email,
      roleLabel: roleLabel,
    );
    _adultProfiles.add(adultProfile);
    return adultProfile;
  }

  @override
  Future<List<AdultProfile>> adultProfilesForProfile(String profileId) async {
    return _adultProfiles
        .where((profile) => profile.profileId == profileId)
        .toList(growable: false);
  }
}

class InMemoryRoutineRepository implements RoutineRepository {
  final List<Routine> _routines = [];
  final List<RoutineStep> _steps = [];

  @override
  Future<Routine> createRoutine({
    required String profileId,
    required String title,
    required List<String> stepTitles,
    List<int> weekdays = const [],
    int? scheduledHour,
    int? scheduledMinute,
    int? estimatedDurationMinutes,
    int leadReminderMinutes = 10,
    RoutineRepeatPolicy repeatPolicy = RoutineRepeatPolicy.weekly,
    String? responsibleAdultProfileId,
    String? contextLabel,
    String? minimumVersion,
    String? benefitDescription,
    int maxReminderCount = 2,
    int reminderIntervalMinutes = 5,
    bool vibrationEnabled = true,
    bool soundEnabled = false,
    bool silentNotification = false,
    bool canPostpone = true,
    bool canRequestHelp = true,
  }) async {
    if (stepTitles.length < 3) {
      throw ArgumentError.value(
          stepTitles.length, 'stepTitles', 'A routine needs at least 3 steps.');
    }
    final now = DateTime.now();
    final routineId = _uuid.v4();
    final stepIds = <String>[];
    for (var index = 0; index < stepTitles.length; index += 1) {
      final stepId = _uuid.v4();
      stepIds.add(stepId);
      _steps.add(
        RoutineStep(
          metadata: EntityMetadata(
              id: stepId, createdAt: now, updatedAt: now, ownerId: profileId),
          routineId: routineId,
          title: stepTitles[index],
          order: index + 1,
          estimatedMinutes: 5,
        ),
      );
    }
    final routine = Routine(
      metadata: EntityMetadata(
          id: routineId, createdAt: now, updatedAt: now, ownerId: profileId),
      profileId: profileId,
      title: title,
      stepIds: stepIds,
      weekdays: weekdays,
      scheduledHour: scheduledHour,
      scheduledMinute: scheduledMinute,
      estimatedDurationMinutes: estimatedDurationMinutes,
      leadReminderMinutes: leadReminderMinutes,
      repeatPolicy: repeatPolicy,
      responsibleAdultProfileId: responsibleAdultProfileId,
      contextLabel: contextLabel,
      minimumVersion: minimumVersion,
      benefitDescription: benefitDescription,
      maxReminderCount: maxReminderCount,
      reminderIntervalMinutes: reminderIntervalMinutes,
      vibrationEnabled: vibrationEnabled,
      soundEnabled: soundEnabled,
      silentNotification: silentNotification,
      canPostpone: canPostpone,
      canRequestHelp: canRequestHelp,
    );
    _routines.add(routine);
    return routine;
  }

  @override
  Future<List<Routine>> routinesForProfile(String profileId) async {
    return _routines
        .where((routine) =>
            routine.profileId == profileId &&
            routine.metadata.status != EntityStatus.deleted)
        .toList(growable: false);
  }

  @override
  Future<Routine?> routineById(String routineId) async {
    final matches = _routines.where((routine) =>
        routine.metadata.id == routineId &&
        routine.metadata.status != EntityStatus.deleted);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<Routine> updateRoutine({
    required Routine routine,
    required List<String> stepTitles,
  }) async {
    if (stepTitles.length < 3) {
      throw ArgumentError.value(
          stepTitles.length, 'stepTitles', 'A routine needs at least 3 steps.');
    }
    final routineIndex =
        _routines.indexWhere((item) => item.metadata.id == routine.metadata.id);
    if (routineIndex < 0) {
      throw StateError('Routine not found: ${routine.metadata.id}');
    }
    final existingSteps = await stepsForRoutine(routine.metadata.id);
    final now = DateTime.now();
    final stepIds = <String>[];
    for (var index = 0; index < stepTitles.length; index += 1) {
      final previous =
          index < existingSteps.length ? existingSteps[index] : null;
      final step = RoutineStep(
        metadata: EntityMetadata(
          id: previous?.metadata.id ?? _uuid.v4(),
          createdAt: previous?.metadata.createdAt ?? now,
          updatedAt: now,
          ownerId: previous?.metadata.ownerId ?? routine.profileId,
        ),
        routineId: routine.metadata.id,
        title: stepTitles[index],
        order: index + 1,
        estimatedMinutes: previous?.estimatedMinutes ?? 5,
        status: previous?.status ?? RoutineStepStatus.pending,
      );
      stepIds.add(step.metadata.id);
      final stepIndex =
          _steps.indexWhere((item) => item.metadata.id == step.metadata.id);
      if (stepIndex < 0) {
        _steps.add(step);
      } else {
        _steps[stepIndex] = step;
      }
    }
    for (var index = stepTitles.length;
        index < existingSteps.length;
        index += 1) {
      final step = existingSteps[index];
      final stepIndex =
          _steps.indexWhere((item) => item.metadata.id == step.metadata.id);
      if (stepIndex >= 0) {
        _steps[stepIndex] = _routineStepWithStatus(step, EntityStatus.deleted);
      }
    }
    final updated = _routineWithValues(routine, stepIds: stepIds);
    _routines[routineIndex] = updated;
    return updated;
  }

  @override
  Future<Routine> duplicateRoutine(String routineId) async {
    final routine = await routineById(routineId);
    if (routine == null) {
      throw StateError('Routine not found: $routineId');
    }
    final steps = await stepsForRoutine(routineId);
    return createRoutine(
      profileId: routine.profileId,
      title: '${routine.title} — copia',
      stepTitles: steps.map((step) => step.title).toList(growable: false),
      weekdays: routine.weekdays,
      scheduledHour: routine.scheduledHour,
      scheduledMinute: routine.scheduledMinute,
      estimatedDurationMinutes: routine.estimatedDurationMinutes,
      leadReminderMinutes: routine.leadReminderMinutes,
      repeatPolicy: routine.repeatPolicy,
      responsibleAdultProfileId: routine.responsibleAdultProfileId,
      contextLabel: routine.contextLabel,
      minimumVersion: routine.minimumVersion,
      benefitDescription: routine.benefitDescription,
      maxReminderCount: routine.maxReminderCount,
      reminderIntervalMinutes: routine.reminderIntervalMinutes,
      vibrationEnabled: routine.vibrationEnabled,
      soundEnabled: routine.soundEnabled,
      silentNotification: routine.silentNotification,
      canPostpone: routine.canPostpone,
      canRequestHelp: routine.canRequestHelp,
    );
  }

  @override
  Future<Routine> updateRoutineStatus(
      String routineId, EntityStatus status) async {
    final index =
        _routines.indexWhere((routine) => routine.metadata.id == routineId);
    if (index < 0) {
      throw StateError('Routine not found: $routineId');
    }
    final updated = _routineWithStatus(_routines[index], status);
    _routines[index] = updated;
    return updated;
  }

  @override
  Future<List<RoutineStep>> stepsForRoutine(String routineId) async {
    final steps = _steps
        .where((step) =>
            step.routineId == routineId &&
            step.metadata.status != EntityStatus.deleted)
        .toList();
    steps.sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }
}

Routine _routineWithStatus(Routine routine, EntityStatus status) => Routine(
      metadata: EntityMetadata(
        id: routine.metadata.id,
        createdAt: routine.metadata.createdAt,
        updatedAt: DateTime.now(),
        ownerId: routine.metadata.ownerId,
        status: status,
        accessRules: routine.metadata.accessRules,
      ),
      profileId: routine.profileId,
      title: routine.title,
      stepIds: routine.stepIds,
      weekdays: routine.weekdays,
      scheduledHour: routine.scheduledHour,
      scheduledMinute: routine.scheduledMinute,
      estimatedDurationMinutes: routine.estimatedDurationMinutes,
      leadReminderMinutes: routine.leadReminderMinutes,
      repeatPolicy: routine.repeatPolicy,
      responsibleAdultProfileId: routine.responsibleAdultProfileId,
      contextLabel: routine.contextLabel,
      minimumVersion: routine.minimumVersion,
      benefitDescription: routine.benefitDescription,
      maxReminderCount: routine.maxReminderCount,
      reminderIntervalMinutes: routine.reminderIntervalMinutes,
      vibrationEnabled: routine.vibrationEnabled,
      soundEnabled: routine.soundEnabled,
      silentNotification: routine.silentNotification,
      canPostpone: routine.canPostpone,
      canRequestHelp: routine.canRequestHelp,
    );

Routine _routineWithValues(Routine routine, {required List<String> stepIds}) =>
    Routine(
      metadata: EntityMetadata(
        id: routine.metadata.id,
        createdAt: routine.metadata.createdAt,
        updatedAt: DateTime.now(),
        ownerId: routine.metadata.ownerId,
        status: routine.metadata.status,
        accessRules: routine.metadata.accessRules,
      ),
      profileId: routine.profileId,
      title: routine.title,
      stepIds: stepIds,
      weekdays: routine.weekdays,
      scheduledHour: routine.scheduledHour,
      scheduledMinute: routine.scheduledMinute,
      estimatedDurationMinutes: routine.estimatedDurationMinutes,
      leadReminderMinutes: routine.leadReminderMinutes,
      repeatPolicy: routine.repeatPolicy,
      responsibleAdultProfileId: routine.responsibleAdultProfileId,
      contextLabel: routine.contextLabel,
      minimumVersion: routine.minimumVersion,
      benefitDescription: routine.benefitDescription,
      maxReminderCount: routine.maxReminderCount,
      reminderIntervalMinutes: routine.reminderIntervalMinutes,
      vibrationEnabled: routine.vibrationEnabled,
      soundEnabled: routine.soundEnabled,
      silentNotification: routine.silentNotification,
      canPostpone: routine.canPostpone,
      canRequestHelp: routine.canRequestHelp,
    );

RoutineStep _routineStepWithStatus(RoutineStep step, EntityStatus status) =>
    RoutineStep(
      metadata: EntityMetadata(
        id: step.metadata.id,
        createdAt: step.metadata.createdAt,
        updatedAt: DateTime.now(),
        ownerId: step.metadata.ownerId,
        status: status,
        accessRules: step.metadata.accessRules,
      ),
      routineId: step.routineId,
      title: step.title,
      order: step.order,
      estimatedMinutes: step.estimatedMinutes,
      status: step.status,
    );

class InMemoryRoutineSessionRepository implements RoutineSessionRepository {
  InMemoryRoutineSessionRepository({
    InMemoryProfileRepository? profileRepository,
    InMemoryFamilyActivityEventRepository? activityEvents,
  })  : _profileRepository = profileRepository,
        _activityEvents = activityEvents;

  final Map<String, RoutineSession> _sessions = {};
  final InMemoryProfileRepository? _profileRepository;
  final InMemoryFamilyActivityEventRepository? _activityEvents;

  @override
  Future<RoutineSession?> activeSessionForProfile(String profileId) async {
    final sessions = _sessions.values.where((session) {
      return session.routine.profileId == profileId && _isOpenSession(session);
    }).toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<RoutineSession?> activeSessionForRoutineToday({
    required String routineId,
    required DateTime localDate,
  }) async {
    final sessions = _sessions.values.where((session) {
      return session.routine.metadata.id == routineId &&
          _isOpenSession(session) &&
          sameHabitarFunctionalDate(session.sessionDate, localDate);
    }).toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<List<RoutineSession>> sessionsForProfileDate({
    required String profileId,
    required DateTime localDate,
  }) async {
    final sessions = _sessions.values.where((session) {
      return session.routine.profileId == profileId &&
          sameHabitarFunctionalDate(session.sessionDate, localDate);
    }).toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<RoutineSession?> latestSessionForRoutineDate({
    required String routineId,
    required DateTime localDate,
  }) async {
    final sessions = _sessions.values.where((session) {
      return session.routine.metadata.id == routineId &&
          sameHabitarFunctionalDate(session.sessionDate, localDate);
    }).toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<RoutineSession?> byId(String sessionId) async => _sessions[sessionId];

  @override
  Future<void> save(RoutineSession session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<RoutineSession> completeSession(RoutineSession session) async {
    _sessions[session.id] = session;
    final activityEvents = _activityEvents;
    final profileRepository = _profileRepository;
    if (activityEvents == null || profileRepository == null) {
      return session;
    }
    if (activityEvents.hasEventFor(session.id, 'routine_completed')) {
      return session;
    }
    final summary =
        profileRepository.summaryForProfileId(session.routine.profileId);
    if (summary == null) {
      return session;
    }
    final now = DateTime.now();
    activityEvents.events.add(FamilyActivityEvent(
      metadata: EntityMetadata(
        id: _uuid.v4(),
        createdAt: session.completedAt ?? now,
        updatedAt: session.completedAt ?? now,
        ownerId: summary.familyId,
      ),
      familyId: summary.familyId,
      profileId: session.routine.profileId,
      routineId: session.routine.metadata.id,
      sessionId: session.id,
      kind: 'routine_completed',
      profileDisplayName: summary.displayName,
      routineTitle: session.routine.title,
    ));
    return session;
  }
}

class InMemoryFamilyActivityEventRepository
    implements FamilyActivityEventRepository {
  final List<FamilyActivityEvent> events = [];

  bool hasEventFor(String sessionId, String kind) => events
      .any((event) => event.sessionId == sessionId && event.kind == kind);

  @override
  Future<List<FamilyActivityEvent>> recentEventsForFamily(
    String familyId, {
    int limit = 20,
  }) async {
    final filtered = events.where((event) => event.familyId == familyId).toList()
      ..sort((a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt));
    return filtered.take(limit).toList(growable: false);
  }
}

bool _isOpenSession(RoutineSession session) =>
    session.status == RoutineSessionStatus.running ||
    session.status == RoutineSessionStatus.paused ||
    session.status == RoutineSessionStatus.postponed;

class InMemoryRoutineOverrideRepository implements RoutineOverrideRepository {
  final List<RoutineOverride> _overrides = [];

  @override
  Future<RoutineOverride> saveOverride(RoutineOverride override) async {
    final index = _overrides.indexWhere((item) =>
        item.routineId == override.routineId &&
        _sameDay(item.date, override.date));
    if (index < 0) {
      _overrides.add(override);
    } else {
      _overrides[index] = override;
    }
    return override;
  }

  @override
  Future<List<RoutineOverride>> overridesForProfileDate({
    required String profileId,
    required DateTime date,
  }) async {
    return _overrides
        .where((override) =>
            override.profileId == profileId && _sameDay(override.date, date))
        .toList(growable: false);
  }
}

class InMemoryHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];

  @override
  Future<List<Habit>> habitsForProfile(String profileId) async {
    return _habits
        .where((habit) => habit.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<Habit> proposeHabit({
    required String profileId,
    required String title,
    required String minimumVersion,
    required HabitStatus status,
  }) async {
    final now = DateTime.now();
    final habit = Habit(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: profileId),
      profileId: profileId,
      title: title,
      status: status,
      minimumVersion: minimumVersion,
    );
    _habits.add(habit);
    return habit;
  }

  @override
  Future<Habit> saveHabit(Habit habit) async {
    final index =
        _habits.indexWhere((item) => item.metadata.id == habit.metadata.id);
    if (index == -1) {
      _habits.add(habit);
    } else {
      _habits[index] = habit;
    }
    return habit;
  }
}

class InMemoryHabitProgressRepository implements HabitProgressRepository {
  final List<HabitProgressEntry> _entries = [];

  @override
  Future<List<HabitProgressEntry>> entriesForHabit(String habitId) async {
    return _entries
        .where((entry) => entry.habitId == habitId)
        .toList(growable: false);
  }

  @override
  Future<void> record(HabitProgressEntry entry) async {
    _entries.add(entry);
  }
}

class InMemoryTimeBankRepository implements TimeBankRepository {
  final List<TimeBankBenefit> _benefits = [];

  @override
  Future<List<TimeBankBenefit>> benefitsForProfile(String profileId) async {
    return _benefits
        .where((benefit) => benefit.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<TimeBankBenefit> saveBenefit(TimeBankBenefit benefit) async {
    final index =
        _benefits.indexWhere((item) => item.metadata.id == benefit.metadata.id);
    if (index == -1) {
      _benefits.add(benefit);
    } else {
      _benefits[index] = benefit;
    }
    return benefit;
  }
}

class InMemoryNotificationPreferenceRepository
    implements NotificationPreferenceRepository {
  final Map<String, NotificationConsent> _consentsByProfile = {};

  @override
  Future<NotificationConsent?> consentForProfile(String profileId) async =>
      _consentsByProfile[profileId];

  @override
  Future<NotificationConsent> saveConsent(NotificationConsent consent) async {
    _consentsByProfile[consent.profileId] = consent;
    return consent;
  }
}

class InMemoryEmotionCheckInRepository implements EmotionCheckInRepository {
  final List<EmotionCheckIn> _entries = [];

  @override
  Future<List<EmotionCheckIn>> entriesForProfile(String profileId) async {
    return _entries
        .where((entry) => entry.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<EmotionCheckIn> save(EmotionCheckIn checkIn) async {
    _entries.add(checkIn);
    return checkIn;
  }
}

class InMemorySupportRequestRepository implements SupportRequestRepository {
  final List<SupportRequest> _requests = [];

  @override
  Future<List<SupportRequest>> requestsForProfile(String profileId) async {
    return _requests
        .where((request) => request.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<SupportRequest> save(SupportRequest request) async {
    _requests.add(request);
    return request;
  }
}

class InMemoryStoryProgressRepository implements StoryProgressRepository {
  final Map<String, StoryProgress> _progressByKey = {};

  @override
  Future<List<StoryProgress>> progressForProfile(String profileId) async {
    return _progressByKey.values
        .where((progress) => progress.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<StoryProgress> save(StoryProgress progress) async {
    _progressByKey['${progress.profileId}:${progress.storyId}'] = progress;
    return progress;
  }
}

class InMemoryWearableGatewayRepository implements WearableGatewayRepository {
  final Map<WearablePlatform, WearableRoutineSnapshot> _snapshots = {};
  final Map<WearablePlatform, WearableConnectionStatus> _statuses = {
    WearablePlatform.watchOS: WearableConnectionStatus.disconnected,
    WearablePlatform.wearOS: WearableConnectionStatus.disconnected,
  };

  WearableRoutineSnapshot? snapshotFor(WearablePlatform platform) =>
      _snapshots[platform];

  void setStatus(WearablePlatform platform, WearableConnectionStatus status) {
    _statuses[platform] = status;
  }

  @override
  Future<List<WearableCommand>> pendingCommands(
      WearablePlatform platform, String sessionId) async {
    return const [];
  }

  @override
  Future<void> publishSnapshot(
      WearablePlatform platform, WearableRoutineSnapshot snapshot) async {
    _snapshots[platform] = snapshot;
    _statuses[platform] = WearableConnectionStatus.syncing;
  }

  @override
  Future<WearableConnectionStatus> status(WearablePlatform platform) async {
    return _statuses[platform] ?? WearableConnectionStatus.unavailable;
  }
}

class InMemorySyncQueueRepository implements SyncQueueRepository {
  final Map<String, SyncQueueItem> _items = {};

  @override
  Future<SyncQueueItem> enqueue({
    required String collection,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      collection: collection,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
      status: SyncQueueStatus.pending,
    );
    _items[item.id] = item;
    return item;
  }

  @override
  Future<void> markFailed(String itemId, String error) async {
    final item = _items[itemId];
    if (item == null) {
      return;
    }
    _items[itemId] = SyncQueueItem(
      id: item.id,
      collection: item.collection,
      entityId: item.entityId,
      operation: item.operation,
      payload: item.payload,
      createdAt: item.createdAt,
      status: SyncQueueStatus.failed,
      lastError: error,
    );
  }

  @override
  Future<void> markPushed(String itemId) async {
    final item = _items[itemId];
    if (item == null) {
      return;
    }
    _items[itemId] = SyncQueueItem(
      id: item.id,
      collection: item.collection,
      entityId: item.entityId,
      operation: item.operation,
      payload: item.payload,
      createdAt: item.createdAt,
      status: SyncQueueStatus.pushed,
      lastError: item.lastError,
    );
  }

  @override
  Future<List<SyncQueueItem>> pending() async {
    final items = _items.values
        .where((item) =>
            item.status == SyncQueueStatus.pending ||
            item.status == SyncQueueStatus.failed)
        .toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class InMemoryDeviceTokenRepository implements DeviceTokenRepository {
  // Keyed by token, no por usuario - unique(token) es la clave real, igual
  // que en la migracion. Un mismo userId puede tener varias entradas.
  final Map<String, DeviceToken> _byToken = {};

  @override
  Future<void> registerToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    _byToken[token] = DeviceToken(
      id: _byToken[token]?.id ?? _uuid.v4(),
      userId: userId,
      token: token,
      platform: platform,
    );
  }

  @override
  Future<void> deleteToken(String token) async {
    _byToken.remove(token);
  }

  /// Solo para tests - la interfaz real nunca expone tokens de otro
  /// usuario (ver el comentario de seguridad en
  /// resolve_routine_notification_recipients, 0015_device_tokens.sql).
  List<DeviceToken> tokensForUser(String userId) =>
      _byToken.values.where((t) => t.userId == userId).toList(growable: false);
}

class InMemoryPushNotificationPreferenceRepository
    implements PushNotificationPreferenceRepository {
  final Map<String, PushNotificationPreference> _byUser = {};

  @override
  Future<PushNotificationPreference?> forUser(String userId) async =>
      _byUser[userId];

  @override
  Future<PushNotificationPreference> save(
    PushNotificationPreference preference,
  ) async {
    _byUser[preference.userId] = preference;
    return preference;
  }
}
