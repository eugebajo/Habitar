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
