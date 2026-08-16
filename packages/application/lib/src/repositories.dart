import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';

enum SyncOperation { create, update, delete }

enum SyncQueueStatus { pending, pushed, failed }

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.collection,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.status,
    this.lastError,
  });

  final String id;
  final String collection;
  final String entityId;
  final SyncOperation operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final SyncQueueStatus status;
  final String? lastError;
}

abstract interface class AuthRepository {
  Future<User> registerAdult(
      {required String displayName,
      required String email,
      required String password});

  Future<User> signIn({required String email, required String password});

  Future<User?> currentUser();

  Future<void> signOut();

  Future<void> requestPasswordReset({
    required String email,
    required Uri redirectTo,
  });

  Future<void> updatePassword({required String password});
}

class PendingFamilyInvitation {
  const PendingFamilyInvitation({
    required this.invitation,
    required this.familyName,
  });

  final AdultInvitation invitation;
  final String familyName;
}

/// Result of creating a WhatsApp-shareable invitation code. [code] is the
/// plaintext code - it only ever exists here, once, right after creation.
/// Nothing persists it; only its hash is stored.
class InvitationCodeCreated {
  const InvitationCodeCreated({
    required this.invitationId,
    required this.familyId,
    required this.email,
    required this.role,
    required this.expiresAt,
    required this.code,
  });

  final String invitationId;
  final String familyId;
  final String email;
  final FamilyMemberRole role;
  final DateTime expiresAt;
  final String code;
}

/// Result of redeeming an invitation code: the family the caller just
/// joined (leaving any other family they belonged to) and the role they
/// were granted.
class InvitationCodeAccepted {
  const InvitationCodeAccepted({
    required this.familyId,
    required this.role,
  });

  final String familyId;
  final FamilyMemberRole role;
}

/// Thrown by [FamilyRepository.createInvitationWithCode],
/// [FamilyRepository.acceptInvitationByCode] and
/// [FamilyRepository.cancelInvitation] for expected, named failures (an
/// invalid/expired/used/canceled code, a duplicate pending invitation,
/// self-invitation, a caller without permission, and so on). [code] is the
/// raw error identifier (e.g. 'INVITATION_CODE_INVALID_OR_EXPIRED') and is
/// meant to be mapped to user-facing copy by the caller - it is not
/// user-facing text itself and must never be shown directly.
class FamilyInvitationException implements Exception {
  const FamilyInvitationException(this.code);

  final String code;

  @override
  String toString() => 'FamilyInvitationException($code)';
}

abstract interface class ProfileRepository {
  Future<List<ChildProfile>> childProfiles(String familyId);

  Future<List<TeenProfile>> teenProfiles(String familyId);

  Future<ChildProfile> createChildProfile(
      {required String familyId,
      required String displayName,
      required int age});

  Future<TeenProfile> createTeenProfile(
      {required String familyId,
      required String displayName,
      required int age});
}

abstract interface class FamilyRepository {
  Future<Family> createFamily(
      {required String ownerUserId, required String name});

  Future<Family?> currentFamily(String ownerUserId);

  Future<List<FamilyMember>> membersForFamily(String familyId);

  Future<AdultInvitation> createAdultInvitation({
    required String familyId,
    required String email,
    required FamilyMemberRole role,
    required String invitedByUserId,
  });

  Future<List<AdultInvitation>> invitationsForFamily(String familyId);

  Future<List<PendingFamilyInvitation>> pendingInvitationsForEmail(
      String authenticatedEmail);

  Future<FamilyMember> acceptInvitation({
    required String invitationId,
    required String userId,
    required String userEmail,
  });

  /// Creates a WhatsApp-shareable invitation code for [email] in [familyId].
  /// [invitedByUserEmail] is the caller's own email, used for the
  /// self-invitation check - on Supabase the RPC re-derives it from
  /// auth.jwt() regardless of what's passed, but local/in-memory backends
  /// have no ambient auth context to look it up from [invitedByUserId], so
  /// it's passed explicitly to keep the check meaningful on every backend.
  /// Throws [FamilyInvitationException] with codes such as
  /// 'INVITATION_SELF_FORBIDDEN', 'INVITATION_ALREADY_PENDING',
  /// 'INVITATION_ROLE_INVALID', 'INVITATION_EMAIL_INVALID' or
  /// 'INVITATION_CREATE_FORBIDDEN'.
  Future<InvitationCodeCreated> createInvitationWithCode({
    required String familyId,
    required String email,
    required FamilyMemberRole role,
    required String invitedByUserId,
    required String invitedByUserEmail,
  });

  /// Redeems [code] for the caller identified by [userId]/[userEmail],
  /// moving them out of any other family they belong to and into the
  /// invitation's family (one family per adult). Throws
  /// [FamilyInvitationException] with code
  /// 'INVITATION_CODE_INVALID_OR_EXPIRED' for every one of: an unknown
  /// code, an expired one, one already used, one that was canceled, and one
  /// whose email doesn't match the caller's - deliberately indistinguishable
  /// so a forwarded/misdirected code can't be used to learn whether it, or
  /// the email address it was meant for, exist.
  Future<InvitationCodeAccepted> acceptInvitationByCode({
    required String code,
    required String userId,
    required String userEmail,
  });

  /// Cancels a still-pending invitation so its code stops working. Only the
  /// family's owner/parent may call this. Throws [FamilyInvitationException]
  /// with codes such as 'INVITATION_NOT_FOUND', 'INVITATION_CANCEL_FORBIDDEN'
  /// or 'INVITATION_NOT_PENDING'.
  Future<void> cancelInvitation({
    required String invitationId,
    required String userId,
  });
}

abstract interface class AdultProfileRepository {
  Future<AdultProfile> createAdultProfile({
    required String familyId,
    required String profileId,
    required String displayName,
    required AdultProfileKind kind,
    String? email,
    String? roleLabel,
  });

  Future<List<AdultProfile>> adultProfilesForProfile(String profileId);
}

abstract interface class RoutineRepository {
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
  });

  Future<List<RoutineStep>> stepsForRoutine(String routineId);

  Future<Routine?> routineById(String routineId);

  Future<List<Routine>> routinesForProfile(String profileId);

  Future<Routine> updateRoutine({
    required Routine routine,
    required List<String> stepTitles,
  });

  Future<Routine> duplicateRoutine(String routineId);

  Future<Routine> updateRoutineStatus(String routineId, EntityStatus status);
}

abstract interface class RoutineSessionRepository {
  Future<void> save(RoutineSession session);

  Future<RoutineSession?> activeSessionForProfile(String profileId);

  Future<RoutineSession?> activeSessionForRoutineToday({
    required String routineId,
    required DateTime localDate,
  });

  Future<List<RoutineSession>> sessionsForProfileDate({
    required String profileId,
    required DateTime localDate,
  });

  Future<RoutineSession?> latestSessionForRoutineDate({
    required String routineId,
    required DateTime localDate,
  });

  Future<RoutineSession?> byId(String sessionId);
}

abstract interface class RoutineOverrideRepository {
  Future<RoutineOverride> saveOverride(RoutineOverride override);

  Future<List<RoutineOverride>> overridesForProfileDate({
    required String profileId,
    required DateTime date,
  });
}

abstract interface class HabitRepository {
  Future<Habit> proposeHabit({
    required String profileId,
    required String title,
    required String minimumVersion,
    required HabitStatus status,
  });

  Future<Habit> saveHabit(Habit habit);

  Future<List<Habit>> habitsForProfile(String profileId);
}

abstract interface class HabitProgressRepository {
  Future<void> record(HabitProgressEntry entry);

  Future<List<HabitProgressEntry>> entriesForHabit(String habitId);
}

abstract interface class TimeBankRepository {
  Future<List<TimeBankBenefit>> benefitsForProfile(String profileId);

  Future<TimeBankBenefit> saveBenefit(TimeBankBenefit benefit);
}

abstract interface class NotificationPreferenceRepository {
  Future<NotificationConsent?> consentForProfile(String profileId);

  Future<NotificationConsent> saveConsent(NotificationConsent consent);
}

abstract interface class EmotionCheckInRepository {
  Future<EmotionCheckIn> save(EmotionCheckIn checkIn);

  Future<List<EmotionCheckIn>> entriesForProfile(String profileId);
}

abstract interface class SupportRequestRepository {
  Future<SupportRequest> save(SupportRequest request);

  Future<List<SupportRequest>> requestsForProfile(String profileId);
}

abstract interface class StoryProgressRepository {
  Future<StoryProgress> save(StoryProgress progress);

  Future<List<StoryProgress>> progressForProfile(String profileId);
}

abstract interface class WearableGatewayRepository {
  Future<WearableConnectionStatus> status(WearablePlatform platform);

  Future<void> publishSnapshot(
      WearablePlatform platform, WearableRoutineSnapshot snapshot);

  Future<List<WearableCommand>> pendingCommands(
      WearablePlatform platform, String sessionId);
}

abstract interface class SyncQueueRepository {
  Future<SyncQueueItem> enqueue({
    required String collection,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  });

  Future<List<SyncQueueItem>> pending();

  Future<void> markPushed(String itemId);

  Future<void> markFailed(String itemId, String error);
}
