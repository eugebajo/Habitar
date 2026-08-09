import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:supabase/supabase.dart';

class SupabaseFamilyRepository implements FamilyRepository {
  const SupabaseFamilyRepository(this.client);

  final SupabaseClient client;

  @override
  Future<Family> createFamily({
    required String ownerUserId,
    required String name,
  }) async {
    final familyRow = await client
        .from('families')
        .insert({
          'owner': ownerUserId,
          'name': name,
          'access_rules': <Object?>[],
        })
        .select()
        .single();
    final family = _familyFromRow(familyRow);
    await client.from('family_members').insert({
      'family_id': family.metadata.id,
      'user_id': ownerUserId,
      'role': 'owner',
    });
    return family;
  }

  @override
  Future<Family?> currentFamily(String ownerUserId) async {
    final memberRows = await client
        .from('family_members')
        .select('family_id')
        .eq('user_id', ownerUserId)
        .limit(1);
    if (memberRows.isEmpty) {
      return null;
    }
    final familyId = memberRows.first['family_id'] as String;
    final familyRow =
        await client.from('families').select().eq('id', familyId).maybeSingle();
    return familyRow == null ? null : _familyFromRow(familyRow);
  }

  @override
  Future<List<FamilyMember>> membersForFamily(String familyId) async {
    final rows = await client
        .from('family_members')
        .select()
        .eq('family_id', familyId)
        .order('created_at');
    return rows.map(_familyMemberFromRow).toList(growable: false);
  }

  @override
  Future<AdultInvitation> createAdultInvitation({
    required String familyId,
    required String email,
    required FamilyMemberRole role,
    required String invitedByUserId,
  }) async {
    final row = await client
        .from('adult_invitations')
        .insert({
          'family_id': familyId,
          'email': email.trim().toLowerCase(),
          'role': role.name,
          'status': AdultInvitationStatus.pending.name,
          'invited_by_user_id': invitedByUserId,
        })
        .select()
        .single();
    return _adultInvitationFromRow(row);
  }

  @override
  Future<List<AdultInvitation>> invitationsForFamily(String familyId) async {
    final rows = await client
        .from('adult_invitations')
        .select()
        .eq('family_id', familyId)
        .order('created_at');
    return rows.map(_adultInvitationFromRow).toList(growable: false);
  }

  @override
  Future<FamilyMember> acceptInvitation({
    required String invitationId,
    required String userId,
    required String userEmail,
  }) async {
    final row = await client.rpc('accept_family_invitation', params: {
      'target_invitation_id': invitationId,
    }) as Map<String, dynamic>;
    return _familyMemberFromRow(row);
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<ChildProfile>> childProfiles(String familyId) async {
    final rows = await client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .eq('kind', 'child')
        .order('created_at');
    return rows.map(_childProfileFromRow).toList(growable: false);
  }

  @override
  Future<ChildProfile> createChildProfile({
    required String familyId,
    required String displayName,
    required int age,
  }) async {
    final row = await _insertProfile(
      familyId: familyId,
      kind: 'child',
      displayName: displayName,
      age: age,
    );
    return _childProfileFromRow(row);
  }

  @override
  Future<TeenProfile> createTeenProfile({
    required String familyId,
    required String displayName,
    required int age,
  }) async {
    final row = await _insertProfile(
      familyId: familyId,
      kind: 'teen',
      displayName: displayName,
      age: age,
    );
    return _teenProfileFromRow(row);
  }

  @override
  Future<List<TeenProfile>> teenProfiles(String familyId) async {
    final rows = await client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .eq('kind', 'teen')
        .order('created_at');
    return rows.map(_teenProfileFromRow).toList(growable: false);
  }

  Future<Map<String, dynamic>> _insertProfile({
    required String familyId,
    required String kind,
    required String displayName,
    required int age,
  }) async {
    final userId = _currentUserId(client);
    return client
        .from('profiles')
        .insert({
          'owner': userId,
          'family_id': familyId,
          'kind': kind,
          'display_name': displayName,
          'age': age,
          'access_rules': <Object?>[],
        })
        .select()
        .single();
  }
}

class SupabaseRoutineRepository implements RoutineRepository {
  const SupabaseRoutineRepository(this.client);

  final SupabaseClient client;

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
    final userId = _currentUserId(client);
    final routineRow = await client
        .from('routines')
        .insert({
          'owner': userId,
          'profile_id': profileId,
          'title': title,
          'weekdays': weekdays,
          'scheduled_hour': scheduledHour,
          'scheduled_minute': scheduledMinute,
          'estimated_duration_minutes': estimatedDurationMinutes,
          'lead_reminder_minutes': leadReminderMinutes,
          'repeat_policy': repeatPolicy.name,
          'responsible_adult_profile_id': responsibleAdultProfileId,
          'context_label': contextLabel,
          'minimum_version': minimumVersion,
          'benefit_description': benefitDescription,
          'max_reminder_count': maxReminderCount,
          'reminder_interval_minutes': reminderIntervalMinutes,
          'vibration_enabled': vibrationEnabled,
          'sound_enabled': soundEnabled,
          'silent_notification': silentNotification,
          'can_postpone': canPostpone,
          'can_request_help': canRequestHelp,
          'access_rules': <Object?>[],
        })
        .select()
        .single();
    final routineId = routineRow['id'] as String;
    for (var index = 0; index < stepTitles.length; index += 1) {
      await client.from('routine_steps').insert({
        'owner': userId,
        'routine_id': routineId,
        'title': stepTitles[index],
        'step_order': index + 1,
        'estimated_minutes': 5,
        'access_rules': <Object?>[],
      });
    }
    final steps = await stepsForRoutine(routineId);
    return _routineFromRow(
      routineRow,
      stepIds: steps.map((step) => step.metadata.id).toList(growable: false),
    );
  }

  @override
  Future<List<Routine>> routinesForProfile(String profileId) async {
    final rows = await client
        .from('routines')
        .select()
        .eq('profile_id', profileId)
        .neq('status', 'deleted')
        .order('created_at');
    final routines = <Routine>[];
    for (final row in rows) {
      final steps = await stepsForRoutine(row['id'] as String);
      routines.add(_routineFromRow(
        row,
        stepIds: steps.map((step) => step.metadata.id).toList(growable: false),
      ));
    }
    return routines;
  }

  @override
  Future<Routine?> routineById(String routineId) async {
    final row = await client
        .from('routines')
        .select()
        .eq('id', routineId)
        .neq('status', 'deleted')
        .maybeSingle();
    if (row == null) {
      return null;
    }
    final steps = await stepsForRoutine(routineId);
    return _routineFromRow(
      row,
      stepIds: steps.map((step) => step.metadata.id).toList(growable: false),
    );
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
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await client
        .from('routines')
        .update({
          'title': routine.title,
          'weekdays': routine.weekdays,
          'scheduled_hour': routine.scheduledHour,
          'scheduled_minute': routine.scheduledMinute,
          'estimated_duration_minutes': routine.estimatedDurationMinutes,
          'lead_reminder_minutes': routine.leadReminderMinutes,
          'repeat_policy': routine.repeatPolicy.name,
          'responsible_adult_profile_id': routine.responsibleAdultProfileId,
          'context_label': routine.contextLabel,
          'minimum_version': routine.minimumVersion,
          'benefit_description': routine.benefitDescription,
          'max_reminder_count': routine.maxReminderCount,
          'reminder_interval_minutes': routine.reminderIntervalMinutes,
          'vibration_enabled': routine.vibrationEnabled,
          'sound_enabled': routine.soundEnabled,
          'silent_notification': routine.silentNotification,
          'can_postpone': routine.canPostpone,
          'can_request_help': routine.canRequestHelp,
          'updated_at': now,
        })
        .eq('id', routine.metadata.id)
        .select()
        .single();
    final existingSteps = await stepsForRoutine(routine.metadata.id);
    final userId = _currentUserId(client);
    final stepIds = <String>[];
    for (var index = 0; index < stepTitles.length; index += 1) {
      final previous =
          index < existingSteps.length ? existingSteps[index] : null;
      if (previous == null) {
        final inserted = await client
            .from('routine_steps')
            .insert({
              'owner': userId,
              'routine_id': routine.metadata.id,
              'title': stepTitles[index],
              'step_order': index + 1,
              'estimated_minutes': 5,
              'access_rules': <Object?>[],
            })
            .select()
            .single();
        stepIds.add(inserted['id'] as String);
      } else {
        final updated = await client
            .from('routine_steps')
            .update({
              'title': stepTitles[index],
              'step_order': index + 1,
              'updated_at': now,
              'status': previous.metadata.status.name,
            })
            .eq('id', previous.metadata.id)
            .select()
            .single();
        stepIds.add(updated['id'] as String);
      }
    }
    for (var index = stepTitles.length;
        index < existingSteps.length;
        index += 1) {
      await client
          .from('routine_steps')
          .update({'status': 'deleted', 'updated_at': now}).eq(
              'id', existingSteps[index].metadata.id);
    }
    return _routineFromRow(row, stepIds: stepIds);
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
    final row = await client
        .from('routines')
        .update({
          'status': status.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', routineId)
        .select()
        .single();
    final steps = await stepsForRoutine(routineId);
    return _routineFromRow(
      row,
      stepIds: steps.map((step) => step.metadata.id).toList(growable: false),
    );
  }

  @override
  Future<List<RoutineStep>> stepsForRoutine(String routineId) async {
    final rows = await client
        .from('routine_steps')
        .select()
        .eq('routine_id', routineId)
        .neq('status', 'deleted')
        .order('step_order');
    return rows.map(_routineStepFromRow).toList(growable: false);
  }
}

class SupabaseRoutineOverrideRepository implements RoutineOverrideRepository {
  const SupabaseRoutineOverrideRepository(this.client);

  final SupabaseClient client;

  @override
  Future<RoutineOverride> saveOverride(RoutineOverride override) async {
    final row = await client
        .from('routine_overrides')
        .upsert({
          'id': override.metadata.id,
          'routine_id': override.routineId,
          'profile_id': override.profileId,
          'override_date': _dateOnly(override.date),
          'override_type': override.type.name,
          'start_hour': override.startHour,
          'start_minute': override.startMinute,
          'is_paused': override.isPaused,
          'note': override.note,
          'created_by': override.createdBy ?? _currentUserId(client),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    return _routineOverrideFromRow(row);
  }

  @override
  Future<List<RoutineOverride>> overridesForProfileDate({
    required String profileId,
    required DateTime date,
  }) async {
    final rows = await client
        .from('routine_overrides')
        .select()
        .eq('profile_id', profileId)
        .eq('override_date', _dateOnly(date))
        .order('created_at');
    return rows.map(_routineOverrideFromRow).toList(growable: false);
  }
}

String _currentUserId(SupabaseClient client) {
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError('No hay una sesión adulta activa.');
  }
  return userId;
}

Family _familyFromRow(Map<String, dynamic> row) {
  return Family(
    metadata: _metadataFromRow(row),
    name: row['name'] as String,
    adultUserIds: const [],
  );
}

FamilyMember _familyMemberFromRow(Map<String, dynamic> row) {
  return FamilyMember(
    metadata: _metadataFromRow(row),
    familyId: row['family_id'] as String,
    userId: row['user_id'] as String,
    role: _familyMemberRole(row['role'] as String?),
    email: row['email'] as String?,
    displayName: row['display_name'] as String?,
  );
}

AdultInvitation _adultInvitationFromRow(Map<String, dynamic> row) {
  return AdultInvitation(
    metadata: _metadataFromRow(row),
    familyId: row['family_id'] as String,
    email: row['email'] as String,
    role: _familyMemberRole(row['role'] as String?),
    status: _adultInvitationStatus(row['status'] as String?),
    expiresAt: DateTime.parse(row['expires_at'] as String),
    invitedByUserId: row['invited_by_user_id'] as String?,
    acceptedByUserId: row['accepted_by_user_id'] as String?,
  );
}

ChildProfile _childProfileFromRow(Map<String, dynamic> row) {
  return ChildProfile(
    metadata: _metadataFromRow(row),
    familyId: row['family_id'] as String,
    displayName: row['display_name'] as String,
    age: row['age'] as int,
  );
}

TeenProfile _teenProfileFromRow(Map<String, dynamic> row) {
  return TeenProfile(
    metadata: _metadataFromRow(row),
    familyId: row['family_id'] as String,
    displayName: row['display_name'] as String,
    age: row['age'] as int,
    privateReflectionEnabled:
        row['private_reflection_enabled'] as bool? ?? true,
  );
}

Routine _routineFromRow(
  Map<String, dynamic> row, {
  List<String> stepIds = const [],
}) {
  return Routine(
    metadata: _metadataFromRow(row),
    profileId: row['profile_id'] as String,
    title: row['title'] as String,
    stepIds: stepIds,
    weekdays: _intList(row['weekdays']),
    scheduledHour: row['scheduled_hour'] as int?,
    scheduledMinute: row['scheduled_minute'] as int?,
    estimatedDurationMinutes: row['estimated_duration_minutes'] as int?,
    leadReminderMinutes: row['lead_reminder_minutes'] as int? ?? 10,
    repeatPolicy: RoutineRepeatPolicy.values
        .byName(row['repeat_policy'] as String? ?? 'weekly'),
    responsibleAdultProfileId: row['responsible_adult_profile_id'] as String?,
    contextLabel: row['context_label'] as String?,
    minimumVersion: row['minimum_version'] as String?,
    benefitDescription: row['benefit_description'] as String?,
    maxReminderCount: row['max_reminder_count'] as int? ?? 2,
    reminderIntervalMinutes: row['reminder_interval_minutes'] as int? ?? 5,
    vibrationEnabled: row['vibration_enabled'] as bool? ?? true,
    soundEnabled: row['sound_enabled'] as bool? ?? false,
    silentNotification: row['silent_notification'] as bool? ?? false,
    canPostpone: row['can_postpone'] as bool? ?? true,
    canRequestHelp: row['can_request_help'] as bool? ?? true,
  );
}

RoutineStep _routineStepFromRow(Map<String, dynamic> row) {
  return RoutineStep(
    metadata: _metadataFromRow(row),
    routineId: row['routine_id'] as String,
    title: row['title'] as String,
    order: row['step_order'] as int,
    estimatedMinutes: row['estimated_minutes'] as int?,
  );
}

RoutineOverride _routineOverrideFromRow(Map<String, dynamic> row) {
  final dateValue = row['override_date'];
  return RoutineOverride(
    metadata: _metadataFromRow(row),
    routineId: row['routine_id'] as String,
    profileId: row['profile_id'] as String,
    date:
        dateValue is DateTime ? dateValue : DateTime.parse(dateValue as String),
    type: _routineOverrideType(row['override_type'] as String?),
    startHour: row['start_hour'] as int?,
    startMinute: row['start_minute'] as int?,
    isPaused: row['is_paused'] as bool? ?? false,
    note: row['note'] as String?,
    createdBy: row['created_by'] as String?,
  );
}

EntityMetadata _metadataFromRow(Map<String, dynamic> row) {
  final createdAt = DateTime.parse(row['created_at'] as String);
  final updatedAt = DateTime.parse(
    (row['updated_at'] ?? row['created_at']) as String,
  );
  return EntityMetadata(
    id: row['id'] as String,
    createdAt: createdAt,
    updatedAt: updatedAt,
    ownerId: (row['owner'] ??
        row['user_id'] ??
        row['invited_by_user_id'] ??
        row['family_id']) as String,
    status: _entityStatus(row['status'] as String?),
  );
}

EntityStatus _entityStatus(String? status) {
  return switch (status) {
    'paused' => EntityStatus.paused,
    'archived' => EntityStatus.archived,
    'deleted' => EntityStatus.deleted,
    _ => EntityStatus.active,
  };
}

FamilyMemberRole _familyMemberRole(String? role) {
  return switch (role) {
    'owner' => FamilyMemberRole.owner,
    'parent' => FamilyMemberRole.parent,
    'caregiver' => FamilyMemberRole.caregiver,
    'professional' => FamilyMemberRole.professional,
    _ => FamilyMemberRole.viewer,
  };
}

AdultInvitationStatus _adultInvitationStatus(String? status) {
  return switch (status) {
    'accepted' => AdultInvitationStatus.accepted,
    'revoked' => AdultInvitationStatus.revoked,
    'expired' => AdultInvitationStatus.expired,
    _ => AdultInvitationStatus.pending,
  };
}

RoutineOverrideType _routineOverrideType(String? type) {
  return switch (type) {
    'pauseToday' => RoutineOverrideType.pauseToday,
    'skipToday' => RoutineOverrideType.skipToday,
    'runningLate' => RoutineOverrideType.runningLate,
    'sick' => RoutineOverrideType.sick,
    'traveling' => RoutineOverrideType.traveling,
    _ => RoutineOverrideType.changeTime,
  };
}

String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

List<int> _intList(Object? value) {
  return (value as List? ?? const []).map((item) => item as int).toList();
}
