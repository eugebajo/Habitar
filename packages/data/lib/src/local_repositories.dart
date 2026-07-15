import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:uuid/uuid.dart';

import 'local_store.dart';

const _uuid = Uuid();
const _currentUserKey = 'current_user';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this.store);

  final LocalStore store;

  @override
  Future<User?> currentUser() async {
    final state =
        await store.get(LocalStoreCollections.authState, _currentUserKey);
    final userId = state?['user_id'] as String?;
    if (userId == null) {
      return null;
    }
    final record = await store.get(LocalStoreCollections.users, userId);
    return record == null ? null : _userFromJson(record);
  }

  @override
  Future<User> registerAdult(
      {required String displayName,
      required String email,
      required String password}) async {
    final now = DateTime.now();
    final user = User(
      metadata: EntityMetadata(
          id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: 'self'),
      displayName: displayName,
      email: email,
    );
    await store.put(
        LocalStoreCollections.users, user.metadata.id, _userToJson(user));
    await store.put(LocalStoreCollections.authState, _currentUserKey,
        {'user_id': user.metadata.id});
    return user;
  }
}

class LocalFamilyRepository implements FamilyRepository {
  LocalFamilyRepository(this.store);

  final LocalStore store;

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
    await store.put(LocalStoreCollections.families, family.metadata.id,
        _familyToJson(family));
    return family;
  }

  @override
  Future<Family?> currentFamily(String ownerUserId) async {
    final records = await store.list(LocalStoreCollections.families);
    for (final record in records) {
      final family = _familyFromJson(record);
      if (family.adultUserIds.contains(ownerUserId)) {
        return family;
      }
    }
    return null;
  }
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this.store);

  final LocalStore store;

  @override
  Future<List<ChildProfile>> childProfiles(String familyId) async {
    final records = await store.list(LocalStoreCollections.childProfiles);
    return records
        .map(_childProfileFromJson)
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
    await store.put(LocalStoreCollections.childProfiles, profile.metadata.id,
        _childProfileToJson(profile));
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
    await store.put(LocalStoreCollections.teenProfiles, profile.metadata.id,
        _teenProfileToJson(profile));
    return profile;
  }

  @override
  Future<List<TeenProfile>> teenProfiles(String familyId) async {
    final records = await store.list(LocalStoreCollections.teenProfiles);
    return records
        .map(_teenProfileFromJson)
        .where((profile) => profile.familyId == familyId)
        .toList(growable: false);
  }
}

class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository(this.store);

  final LocalStore store;

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
      final step = RoutineStep(
        metadata: EntityMetadata(
            id: _uuid.v4(), createdAt: now, updatedAt: now, ownerId: profileId),
        routineId: routineId,
        title: stepTitles[index],
        order: index + 1,
        estimatedMinutes: 5,
      );
      stepIds.add(step.metadata.id);
      await store.put(LocalStoreCollections.routineSteps, step.metadata.id,
          _routineStepToJson(step));
    }
    final routine = Routine(
      metadata: EntityMetadata(
          id: routineId, createdAt: now, updatedAt: now, ownerId: profileId),
      profileId: profileId,
      title: title,
      stepIds: stepIds,
    );
    await store.put(LocalStoreCollections.routines, routine.metadata.id,
        _routineToJson(routine));
    return routine;
  }

  @override
  Future<List<Routine>> routinesForProfile(String profileId) async {
    final records = await store.list(LocalStoreCollections.routines);
    return records
        .map(_routineFromJson)
        .where((routine) => routine.profileId == profileId)
        .toList(growable: false);
  }

  @override
  Future<List<RoutineStep>> stepsForRoutine(String routineId) async {
    final records = await store.list(LocalStoreCollections.routineSteps);
    final steps = records
        .map(_routineStepFromJson)
        .where((step) => step.routineId == routineId)
        .toList();
    steps.sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }
}

class LocalRoutineSessionRepository implements RoutineSessionRepository {
  LocalRoutineSessionRepository(this.store);

  final LocalStore store;

  @override
  Future<RoutineSession?> activeSessionForProfile(String profileId) async {
    final records = await store.list(LocalStoreCollections.routineSessions);
    final sessions = records.map(_routineSessionFromJson).where((session) {
      return session.routine.profileId == profileId &&
          session.status != RoutineSessionStatus.completed;
    }).toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<RoutineSession?> byId(String sessionId) async {
    final record =
        await store.get(LocalStoreCollections.routineSessions, sessionId);
    return record == null ? null : _routineSessionFromJson(record);
  }

  @override
  Future<void> save(RoutineSession session) async {
    await store.put(LocalStoreCollections.routineSessions, session.id,
        _routineSessionToJson(session));
  }
}

class LocalHabitRepository implements HabitRepository {
  LocalHabitRepository(this.store);

  final LocalStore store;

  @override
  Future<List<Habit>> habitsForProfile(String profileId) async {
    final records = await store.list(LocalStoreCollections.habits);
    return records
        .map(_habitFromJson)
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
    return saveHabit(habit);
  }

  @override
  Future<Habit> saveHabit(Habit habit) async {
    await store.put(
        LocalStoreCollections.habits, habit.metadata.id, _habitToJson(habit));
    return habit;
  }
}

class LocalHabitProgressRepository implements HabitProgressRepository {
  LocalHabitProgressRepository(this.store);

  final LocalStore store;

  @override
  Future<List<HabitProgressEntry>> entriesForHabit(String habitId) async {
    final records = await store.list(LocalStoreCollections.habitProgress);
    return records
        .map(_habitProgressFromJson)
        .where((entry) => entry.habitId == habitId)
        .toList(growable: false);
  }

  @override
  Future<void> record(HabitProgressEntry entry) async {
    await store.put(
        LocalStoreCollections.habitProgress,
        '${entry.habitId}-${entry.recordedAt.toIso8601String()}',
        _habitProgressToJson(entry));
  }
}

Map<String, Object?> _metadataToJson(EntityMetadata metadata) {
  return {
    'id': metadata.id,
    'created_at': metadata.createdAt.toIso8601String(),
    'updated_at': metadata.updatedAt.toIso8601String(),
    'owner_id': metadata.ownerId,
    'status': metadata.status.name,
    'access_rules':
        metadata.accessRules.map(_accessRuleToJson).toList(growable: false),
  };
}

EntityMetadata _metadataFromJson(Map<String, Object?> json) {
  return EntityMetadata(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    ownerId: json['owner_id'] as String,
    status: _byName(EntityStatus.values,
        json['status'] as String? ?? EntityStatus.active.name),
    accessRules: _objectList(json['access_rules'])
        .map(_accessRuleFromJson)
        .toList(growable: false),
  );
}

Map<String, Object?> _accessRuleToJson(AccessRule rule) {
  return {
    'scope': rule.scope.name,
    'can_read': rule.canRead,
    'can_write': rule.canWrite,
  };
}

AccessRule _accessRuleFromJson(Map<String, Object?> json) {
  return AccessRule(
    scope: _byName(AccessScope.values, json['scope'] as String),
    canRead: json['can_read'] as bool,
    canWrite: json['can_write'] as bool,
  );
}

Map<String, Object?> _userToJson(User user) => {
      'metadata': _metadataToJson(user.metadata),
      'display_name': user.displayName,
      'email': user.email,
    };

User _userFromJson(Map<String, Object?> json) => User(
      metadata: _metadataFromJson(_object(json['metadata'])),
      displayName: json['display_name'] as String,
      email: json['email'] as String,
    );

Map<String, Object?> _familyToJson(Family family) => {
      'metadata': _metadataToJson(family.metadata),
      'name': family.name,
      'adult_user_ids': family.adultUserIds,
    };

Family _familyFromJson(Map<String, Object?> json) => Family(
      metadata: _metadataFromJson(_object(json['metadata'])),
      name: json['name'] as String,
      adultUserIds: _stringList(json['adult_user_ids']),
    );

Map<String, Object?> _childProfileToJson(ChildProfile profile) => {
      'metadata': _metadataToJson(profile.metadata),
      'family_id': profile.familyId,
      'display_name': profile.displayName,
      'age': profile.age,
    };

ChildProfile _childProfileFromJson(Map<String, Object?> json) => ChildProfile(
      metadata: _metadataFromJson(_object(json['metadata'])),
      familyId: json['family_id'] as String,
      displayName: json['display_name'] as String,
      age: json['age'] as int,
    );

Map<String, Object?> _teenProfileToJson(TeenProfile profile) => {
      'metadata': _metadataToJson(profile.metadata),
      'family_id': profile.familyId,
      'display_name': profile.displayName,
      'age': profile.age,
      'private_reflection_enabled': profile.privateReflectionEnabled,
    };

TeenProfile _teenProfileFromJson(Map<String, Object?> json) => TeenProfile(
      metadata: _metadataFromJson(_object(json['metadata'])),
      familyId: json['family_id'] as String,
      displayName: json['display_name'] as String,
      age: json['age'] as int,
      privateReflectionEnabled:
          json['private_reflection_enabled'] as bool? ?? true,
    );

Map<String, Object?> _routineToJson(Routine routine) => {
      'metadata': _metadataToJson(routine.metadata),
      'profile_id': routine.profileId,
      'title': routine.title,
      'step_ids': routine.stepIds,
    };

Routine _routineFromJson(Map<String, Object?> json) => Routine(
      metadata: _metadataFromJson(_object(json['metadata'])),
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      stepIds: _stringList(json['step_ids']),
    );

Map<String, Object?> _routineStepToJson(RoutineStep step) => {
      'metadata': _metadataToJson(step.metadata),
      'routine_id': step.routineId,
      'title': step.title,
      'order': step.order,
      'estimated_minutes': step.estimatedMinutes,
      'status': step.status.name,
    };

RoutineStep _routineStepFromJson(Map<String, Object?> json) => RoutineStep(
      metadata: _metadataFromJson(_object(json['metadata'])),
      routineId: json['routine_id'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      estimatedMinutes: json['estimated_minutes'] as int?,
      status: _byName(RoutineStepStatus.values,
          json['status'] as String? ?? RoutineStepStatus.pending.name),
    );

Map<String, Object?> _routineSessionToJson(RoutineSession session) => {
      'id': session.id,
      'routine': _routineToJson(session.routine),
      'steps': session.steps.map(_routineStepToJson).toList(growable: false),
      'active_step_index': session.activeStepIndex,
      'started_at': session.startedAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
      'status': session.status.name,
      'completed_step_ids': session.completedStepIds,
      'skipped_step_ids': session.skippedStepIds,
      'extra_minutes_by_step_id': session.extraMinutesByStepId,
      'pause_reason': session.pauseReason?.name,
      'help_requested': session.helpRequested,
      'postponed_until': session.postponedUntil?.toIso8601String(),
    };

RoutineSession _routineSessionFromJson(Map<String, Object?> json) =>
    RoutineSession(
      id: json['id'] as String,
      routine: _routineFromJson(_object(json['routine'])),
      steps: _objectList(json['steps'])
          .map(_routineStepFromJson)
          .toList(growable: false),
      activeStepIndex: json['active_step_index'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: _byName(RoutineSessionStatus.values,
          json['status'] as String? ?? RoutineSessionStatus.running.name),
      completedStepIds: _stringList(json['completed_step_ids']),
      skippedStepIds: _stringList(json['skipped_step_ids']),
      extraMinutesByStepId: _intMap(json['extra_minutes_by_step_id']),
      pauseReason: _nullableByName(
          RoutinePauseReason.values, json['pause_reason'] as String?),
      helpRequested: json['help_requested'] as bool? ?? false,
      postponedUntil: _dateTimeOrNull(json['postponed_until']),
    );

Map<String, Object?> _habitToJson(Habit habit) => {
      'metadata': _metadataToJson(habit.metadata),
      'profile_id': habit.profileId,
      'title': habit.title,
      'status': habit.status.name,
      'minimum_version': habit.minimumVersion,
    };

Habit _habitFromJson(Map<String, Object?> json) => Habit(
      metadata: _metadataFromJson(_object(json['metadata'])),
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      status: _byName(HabitStatus.values, json['status'] as String),
      minimumVersion: json['minimum_version'] as String?,
    );

Map<String, Object?> _habitProgressToJson(HabitProgressEntry entry) => {
      'habit_id': entry.habitId,
      'recorded_at': entry.recordedAt.toIso8601String(),
      'completed_minimum_version': entry.completedMinimumVersion,
      'help_level': entry.helpLevel,
      'ease': entry.ease,
      'note': entry.note,
    };

HabitProgressEntry _habitProgressFromJson(Map<String, Object?> json) =>
    HabitProgressEntry(
      habitId: json['habit_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      completedMinimumVersion: json['completed_minimum_version'] as bool,
      helpLevel: json['help_level'] as int,
      ease: json['ease'] as int,
      note: json['note'] as String?,
    );

Map<String, Object?> _object(Object? value) =>
    (value as Map).cast<String, Object?>();

List<Map<String, Object?>> _objectList(Object? value) {
  return (value as List? ?? const [])
      .map((item) => (item as Map).cast<String, Object?>())
      .toList(growable: false);
}

List<String> _stringList(Object? value) =>
    (value as List? ?? const []).cast<String>().toList(growable: false);

Map<String, int> _intMap(Object? value) {
  return (value as Map? ?? {})
      .cast<String, Object?>()
      .map((key, item) => MapEntry(key, item as int));
}

DateTime? _dateTimeOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

T _byName<T extends Enum>(List<T> values, String name) => values.byName(name);

T? _nullableByName<T extends Enum>(List<T> values, String? name) =>
    name == null ? null : values.byName(name);
