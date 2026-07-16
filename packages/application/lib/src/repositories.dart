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

  Future<User?> currentUser();
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
}

abstract interface class RoutineRepository {
  Future<Routine> createRoutine(
      {required String profileId,
      required String title,
      required List<String> stepTitles});

  Future<List<RoutineStep>> stepsForRoutine(String routineId);

  Future<List<Routine>> routinesForProfile(String profileId);
}

abstract interface class RoutineSessionRepository {
  Future<void> save(RoutineSession session);

  Future<RoutineSession?> activeSessionForProfile(String profileId);

  Future<RoutineSession?> byId(String sessionId);
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
