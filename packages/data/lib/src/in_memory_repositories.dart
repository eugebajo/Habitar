import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class InMemoryAuthRepository implements AuthRepository {
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
    return _current!;
  }
}

class InMemoryFamilyRepository implements FamilyRepository {
  final Map<String, Family> _familiesByOwner = {};

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
    return family;
  }

  @override
  Future<Family?> currentFamily(String ownerUserId) async =>
      _familiesByOwner[ownerUserId];
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
}

class InMemoryRoutineRepository implements RoutineRepository {
  final List<Routine> _routines = [];
  final List<RoutineStep> _steps = [];

  @override
  Future<Routine> createRoutine(
      {required String profileId,
      required String title,
      required List<String> stepTitles}) async {
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
    );
    _routines.add(routine);
    return routine;
  }

  @override
  Future<List<Routine>> routinesForProfile(String profileId) async {
    return _routines
        .where((routine) => routine.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<List<RoutineStep>> stepsForRoutine(String routineId) async {
    final steps = _steps.where((step) => step.routineId == routineId).toList();
    steps.sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }
}

class InMemoryRoutineSessionRepository implements RoutineSessionRepository {
  final Map<String, RoutineSession> _sessions = {};

  @override
  Future<RoutineSession?> activeSessionForProfile(String profileId) async {
    final sessions = _sessions.values.where((session) {
      return session.routine.profileId == profileId &&
          session.status != RoutineSessionStatus.completed;
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
