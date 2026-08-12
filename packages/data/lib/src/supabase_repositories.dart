import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:supabase/supabase.dart';

class SupabaseFamilyRepository implements FamilyRepository {
  const SupabaseFamilyRepository(this.client);

  final SupabaseClient client;

  @override
  Future<Family> createFamily({
    required String ownerUserId,
    required String name,
  }) async {
    final currentUserId = _currentUserId(client);
    if (ownerUserId != currentUserId) {
      throw StateError('Cannot bootstrap a family for another user.');
    }
    try {
      _debugLog('INITIAL FAMILY RPC: START');
      final familyRow = await client.rpc('create_initial_family', params: {
        'family_name': name,
      }) as Map<String, dynamic>;
      _debugLog('INITIAL FAMILY RPC: OK');
      return _familyFromRow(familyRow);
    } on PostgrestException catch (error) {
      _debugLog('INITIAL FAMILY RPC: ERROR');
      _logPostgrestError(error);
      rethrow;
    }
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
    final currentUserId = _currentUserId(client);
    if (invitedByUserId != currentUserId) {
      throw StateError('Cannot create an invitation for another adult user.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    try {
      _debugLog('INVITATION CREATE:');
      _debugLog('family_id: $familyId');
      _debugLog('email: $normalizedEmail');
      _debugLog('role: ${role.name}');
      final row = await client
          .from('adult_invitations')
          .insert({
            'family_id': familyId,
            'email': normalizedEmail,
            'role': role.name,
            'status': AdultInvitationStatus.pending.name,
            'invited_by_user_id': currentUserId,
          })
          .select()
          .single();
      final invitation = _adultInvitationFromRow(row);
      _debugLog('INVITATION RESULT: OK');
      _debugLog('id: ${invitation.metadata.id}');
      return invitation;
    } on PostgrestException catch (error) {
      _debugLog('INVITATION RESULT: ERROR');
      _logPostgrestError(error);
      rethrow;
    }
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
  Future<List<PendingFamilyInvitation>> pendingInvitationsForEmail(
      String authenticatedEmail) async {
    final currentEmail = client.auth.currentUser?.email?.trim().toLowerCase();
    _debugLog('PENDING INVITATIONS RPC: START');
    _debugLog(
        'authenticated email: ${authenticatedEmail.trim().toLowerCase()}');
    _debugLog('auth current email: $currentEmail');
    if (currentEmail == null ||
        currentEmail.isEmpty ||
        currentEmail != authenticatedEmail.trim().toLowerCase()) {
      _debugLog('PENDING INVITATIONS RPC: RESULT COUNT: 0');
      return const [];
    }
    try {
      final rows = await client.rpc(
        'pending_family_invitations_for_current_user',
      ) as List<dynamic>;
      _debugLog('PENDING INVITATIONS RPC: RESULT COUNT: ${rows.length}');
      return rows.map((row) {
        final data = (row as Map).cast<String, dynamic>();
        return PendingFamilyInvitation(
          familyName: data['family_name'] as String? ?? 'Familia',
          invitation: _adultInvitationFromRow(data),
        );
      }).toList(growable: false);
    } on PostgrestException catch (error) {
      _debugLog('PENDING INVITATIONS RPC: ERROR');
      _logPostgrestError(error);
      rethrow;
    }
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
    final status = row['status'] as String?;
    if (status == 'expired') {
      throw StateError('Invitation has expired.');
    }
    if (status != 'accepted') {
      throw StateError('Invitation could not be accepted.');
    }
    return _familyMemberFromRow(row['member'] as Map<String, dynamic>);
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
    if (stepTitles.length < 3) {
      throw ArgumentError.value(
          stepTitles.length, 'stepTitles', 'A routine needs at least 3 steps.');
    }
    final userId = _currentUserId(client);
    try {
      _debugLog('ROUTINE SAVE: CREATE START');
      _debugLog('ROUTINE SAVE payload: profile_id=$profileId');
      _debugLog('ROUTINE SAVE payload: title_length=${title.trim().length}');
      _debugLog('ROUTINE SAVE payload: step_count=${stepTitles.length}');
      _debugLog('ROUTINE SAVE payload: weekdays=${weekdays.join(',')}');
      _debugLog('ROUTINE SAVE payload: scheduled_hour=$scheduledHour');
      _debugLog('ROUTINE SAVE payload: scheduled_minute=$scheduledMinute');
      _debugLog(
          'ROUTINE SAVE payload: estimated_duration_minutes=$estimatedDurationMinutes');
      _debugLog('ROUTINE SAVE payload: repeat_policy=${repeatPolicy.name}');
      _debugLog(
          'ROUTINE SAVE payload: responsible_adult_profile_id=$responsibleAdultProfileId');
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
      _debugLog('ROUTINE SAVE: ROUTINE INSERT OK routine_id=$routineId');
      for (var index = 0; index < stepTitles.length; index += 1) {
        _debugLog(
            'ROUTINE SAVE: STEP INSERT START routine_id=$routineId order=${index + 1}');
        await client.from('routine_steps').insert({
          'owner': userId,
          'routine_id': routineId,
          'title': stepTitles[index],
          'step_order': index + 1,
          'estimated_minutes': 5,
          'access_rules': <Object?>[],
        });
      }
      _debugLog(
          'ROUTINE SAVE: STEPS INSERT OK routine_id=$routineId count=${stepTitles.length}');
      final steps = await stepsForRoutine(routineId);
      _debugLog(
          'ROUTINE SAVE: STEPS READ OK routine_id=$routineId count=${steps.length}');
      return _routineFromRow(
        routineRow,
        stepIds: steps.map((step) => step.metadata.id).toList(growable: false),
      );
    } on PostgrestException catch (error) {
      _debugLog('ROUTINE SAVE: POSTGREST ERROR');
      _logPostgrestError(error);
      rethrow;
    }
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
    Map<String, dynamic> row;
    try {
      _debugLog('ROUTINE SAVE: UPDATE START');
      _debugLog('ROUTINE SAVE payload: routine_id=${routine.metadata.id}');
      _debugLog('ROUTINE SAVE payload: profile_id=${routine.profileId}');
      _debugLog('ROUTINE SAVE payload: title_length=${routine.title.length}');
      _debugLog('ROUTINE SAVE payload: step_count=${stepTitles.length}');
      row = await client
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
      _debugLog('ROUTINE SAVE: ROUTINE UPDATE OK');
    } on PostgrestException catch (error) {
      _debugLog('ROUTINE SAVE: POSTGREST ERROR');
      _logPostgrestError(error);
      rethrow;
    }
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
        .order('step_order', ascending: true);
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

class SupabaseRoutineSessionRepository implements RoutineSessionRepository {
  const SupabaseRoutineSessionRepository(this.client);

  final SupabaseClient client;

  @override
  Future<RoutineSession?> activeSessionForProfile(String profileId) async {
    final routineRows = await client
        .from('routines')
        .select('id')
        .eq('profile_id', profileId)
        .neq('status', 'deleted');
    final routineIds =
        routineRows.map((row) => row['id'] as String).toList(growable: false);
    if (routineIds.isEmpty) {
      return null;
    }
    final rows = await client
        .from('routine_sessions')
        .select()
        .inFilter('routine_id', routineIds)
        .inFilter('session_status', [
          RoutineSessionStatus.running.name,
          RoutineSessionStatus.paused.name,
          RoutineSessionStatus.postponed.name,
        ])
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return _sessionFromRow(rows.first);
  }

  @override
  Future<RoutineSession?> activeSessionForRoutineToday({
    required String routineId,
    required DateTime localDate,
  }) async {
    final range = _asuncionUtcRange(localDate);
    final rows = await client
        .from('routine_sessions')
        .select()
        .eq('routine_id', routineId)
        .gte('created_at', range.start.toIso8601String())
        .lt('created_at', range.end.toIso8601String())
        .inFilter('session_status', [
          RoutineSessionStatus.running.name,
          RoutineSessionStatus.paused.name,
          RoutineSessionStatus.postponed.name,
        ])
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return _sessionFromRow(rows.first);
  }

  @override
  Future<List<RoutineSession>> sessionsForProfileDate({
    required String profileId,
    required DateTime localDate,
  }) async {
    final routineRows = await client
        .from('routines')
        .select('id')
        .eq('profile_id', profileId)
        .neq('status', 'deleted');
    final routineIds =
        routineRows.map((row) => row['id'] as String).toList(growable: false);
    if (routineIds.isEmpty) {
      return const [];
    }
    final range = _asuncionUtcRange(localDate);
    final rows = await client
        .from('routine_sessions')
        .select()
        .inFilter('routine_id', routineIds)
        .gte('created_at', range.start.toIso8601String())
        .lt('created_at', range.end.toIso8601String())
        .order('updated_at', ascending: false);
    return Future.wait(rows.map(_sessionFromRow));
  }

  @override
  Future<RoutineSession?> latestSessionForRoutineDate({
    required String routineId,
    required DateTime localDate,
  }) async {
    final range = _asuncionUtcRange(localDate);
    final rows = await client
        .from('routine_sessions')
        .select()
        .eq('routine_id', routineId)
        .gte('created_at', range.start.toIso8601String())
        .lt('created_at', range.end.toIso8601String())
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return _sessionFromRow(rows.first);
  }

  @override
  Future<RoutineSession?> byId(String sessionId) async {
    final row = await client
        .from('routine_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    return row == null ? null : _sessionFromRow(row);
  }

  @override
  Future<void> save(RoutineSession session) async {
    try {
      await client.from('routine_sessions').upsert({
        'id': session.id,
        'owner': _currentUserId(client),
        'routine_id': session.routine.metadata.id,
        'status': EntityStatus.active.name,
        'access_rules': <Object?>[],
        'active_step_index': session.activeStepIndex,
        'session_status': session.status.name,
        'completed_step_ids': session.completedStepIds,
        'skipped_step_ids': session.skippedStepIds,
        'extra_minutes_by_step_id': session.extraMinutesByStepId,
        'pause_reason': session.pauseReason?.name,
        'help_requested': session.helpRequested,
        'postponed_until': session.postponedUntil?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (error) {
      final details = error.details?.toString();
      if (error.code == '23505' &&
          (error.message
                  .contains('routine_sessions_unique_routine_session_date') ||
              details?.contains(
                    'routine_sessions_unique_routine_session_date',
                  ) ==
                  true)) {
        throw StateError('ROUTINE_SESSION_ALREADY_EXISTS_TODAY');
      }
      rethrow;
    }
  }

  Future<RoutineSession> _sessionFromRow(Map<String, dynamic> row) async {
    final routineId = row['routine_id'] as String;
    final routine =
        await SupabaseRoutineRepository(client).routineById(routineId);
    if (routine == null) {
      throw StateError('Routine not found for session: $routineId');
    }
    final steps =
        await SupabaseRoutineRepository(client).stepsForRoutine(routineId);
    final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
    final sessionDateValue = row['session_date'];
    final sessionDate = sessionDateValue == null
        ? habitarFunctionalDate(createdAt)
        : DateTime.parse(sessionDateValue as String);
    return RoutineSession(
      id: row['id'] as String,
      routine: routine,
      steps: steps,
      activeStepIndex: row['active_step_index'] as int? ?? 0,
      startedAt: createdAt,
      updatedAt: DateTime.parse(
        (row['updated_at'] ?? row['created_at']) as String,
      ).toLocal(),
      sessionDate: sessionDate,
      status: RoutineSessionStatus.values.byName(
        row['session_status'] as String? ?? RoutineSessionStatus.running.name,
      ),
      completedStepIds: _stringList(row['completed_step_ids']),
      skippedStepIds: _stringList(row['skipped_step_ids']),
      extraMinutesByStepId: _intMap(row['extra_minutes_by_step_id']),
      pauseReason: _nullableRoutinePauseReason(row['pause_reason'] as String?),
      helpRequested: row['help_requested'] as bool? ?? false,
      postponedUntil: row['postponed_until'] == null
          ? null
          : DateTime.parse(row['postponed_until'] as String).toLocal(),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String).toLocal(),
    );
  }
}

class _UtcDateRange {
  const _UtcDateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

_UtcDateRange _asuncionUtcRange(DateTime date) {
  final functionalDate = habitarFunctionalDate(date);
  final start = DateTime.utc(
    functionalDate.year,
    functionalDate.month,
    functionalDate.day,
    3,
  );
  return _UtcDateRange(start, start.add(const Duration(days: 1)));
}

class SupabaseTimeBankRepository implements TimeBankRepository {
  const SupabaseTimeBankRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<TimeBankBenefit>> benefitsForProfile(String profileId) async {
    final rows = await client
        .from('time_bank_benefits')
        .select()
        .eq('profile_id', profileId)
        .order('created_at');
    return rows.map(_timeBankBenefitFromRow).toList(growable: false);
  }

  @override
  Future<TimeBankBenefit> saveBenefit(TimeBankBenefit benefit) async {
    final currentUserId = _currentUserId(client);
    final row = await client
        .from('time_bank_benefits')
        .upsert({
          'id': benefit.metadata.id,
          'profile_id': benefit.profileId,
          'routine_id': benefit.routineId,
          'habit_id': benefit.habitId,
          'kind': benefit.kind.name,
          'description': benefit.description,
          'minutes_earned': benefit.minutesEarned,
          'minutes_used': benefit.minutesUsed,
          'daily_limit_minutes': benefit.dailyLimitMinutes,
          'expires_at': benefit.expiresAt?.toUtc().toIso8601String(),
          'accumulation_allowed': benefit.accumulationAllowed,
          'status': benefit.status.name,
          'source_action': benefit.sourceAction,
          'idempotency_key': benefit.idempotencyKey,
          'approved_by_adult_id':
              benefit.approvedByAdultId == null ? null : currentUserId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'owner_id': null,
        })
        .select()
        .single();
    return _timeBankBenefitFromRow(row);
  }
}

class SupabaseHabitRepository implements HabitRepository {
  const SupabaseHabitRepository(this.client);

  final SupabaseClient client;

  @override
  Future<Habit> proposeHabit({
    required String profileId,
    required String title,
    required String minimumVersion,
    required HabitStatus status,
  }) async {
    final now = DateTime.now().toUtc();
    final row = await client
        .from('habits')
        .insert({
          'profile_id': profileId,
          'title': title,
          'minimum_version': minimumVersion,
          'habit_status': _habitStatusToDb(status),
          'owner': _currentUserId(client),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();
    return _habitFromRow(row);
  }

  @override
  Future<Habit> saveHabit(Habit habit) async {
    final row = await client
        .from('habits')
        .upsert({
          'id': habit.metadata.id,
          'profile_id': habit.profileId,
          'title': habit.title,
          'minimum_version': habit.minimumVersion,
          'habit_status': _habitStatusToDb(habit.status),
          'owner': _currentUserId(client),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    return _habitFromRow(row);
  }

  @override
  Future<List<Habit>> habitsForProfile(String profileId) async {
    final rows = await client
        .from('habits')
        .select()
        .eq('profile_id', profileId)
        .neq('status', 'deleted')
        .order('created_at');
    return rows.map(_habitFromRow).toList(growable: false);
  }
}

class SupabaseHabitProgressRepository implements HabitProgressRepository {
  const SupabaseHabitProgressRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> record(HabitProgressEntry entry) async {
    await client.from('habit_progress').insert({
      'habit_id': entry.habitId,
      'recorded_at': entry.recordedAt.toUtc().toIso8601String(),
      'completed_minimum_version': entry.completedMinimumVersion,
      'help_level': entry.helpLevel,
      'ease': entry.ease,
      'note': entry.note,
      'owner': _currentUserId(client),
    });
  }

  @override
  Future<List<HabitProgressEntry>> entriesForHabit(String habitId) async {
    final rows = await client
        .from('habit_progress')
        .select()
        .eq('habit_id', habitId)
        .neq('status', 'deleted')
        .order('recorded_at');
    return rows.map(_habitProgressFromRow).toList(growable: false);
  }
}

class SupabaseSupportRequestRepository implements SupportRequestRepository {
  const SupabaseSupportRequestRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<SupportRequest>> requestsForProfile(String profileId) async {
    final rows = await client
        .from('support_requests')
        .select()
        .eq('profile_id', profileId)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);
    return rows.map(_supportRequestFromRow).toList(growable: false);
  }

  @override
  Future<SupportRequest> save(SupportRequest request) async {
    final row = await client
        .from('support_requests')
        .upsert({
          'id': request.metadata.id,
          'owner': _currentUserId(client),
          'profile_id': request.profileId,
          'kind': request.kind,
          'note': request.note,
          'status': request.metadata.status.name,
          'access_rules': <Object?>[],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    return _supportRequestFromRow(row);
  }
}

String _currentUserId(SupabaseClient client) {
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError('No hay una sesión adulta activa.');
  }
  return userId;
}

SupportRequest _supportRequestFromRow(Map<String, dynamic> row) {
  return SupportRequest(
    metadata: _metadataFromRow(row),
    profileId: row['profile_id'] as String,
    kind: row['kind'] as String,
    note: row['note'] as String?,
  );
}

void _debugLog(String message) {
  assert(() {
    // Development-only diagnostics. Do not log passwords, tokens or secrets.
    // ignore: avoid_print
    print(message);
    return true;
  }());
}

void _logPostgrestError(PostgrestException error) {
  assert(() {
    // ignore: avoid_print
    print('PostgREST code: ${error.code}');
    // ignore: avoid_print
    print('PostgREST message: ${error.message}');
    // ignore: avoid_print
    print('PostgREST details: ${error.details}');
    // ignore: avoid_print
    print('PostgREST hint: ${error.hint}');
    return true;
  }());
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

Habit _habitFromRow(Map<String, dynamic> row) {
  return Habit(
    metadata: _metadataFromRow(row),
    profileId: row['profile_id'] as String,
    title: row['title'] as String,
    status: _habitStatusFromDb(row['habit_status'] as String?),
    minimumVersion: row['minimum_version'] as String?,
  );
}

HabitProgressEntry _habitProgressFromRow(Map<String, dynamic> row) {
  return HabitProgressEntry(
    habitId: row['habit_id'] as String,
    recordedAt: DateTime.parse(row['recorded_at'] as String),
    completedMinimumVersion: row['completed_minimum_version'] as bool? ?? false,
    helpLevel: row['help_level'] as int? ?? 0,
    ease: row['ease'] as int? ?? 0,
    note: row['note'] as String?,
  );
}

TimeBankBenefit _timeBankBenefitFromRow(Map<String, dynamic> row) {
  return TimeBankBenefit(
    metadata: _metadataFromRow(row),
    profileId: row['profile_id'] as String,
    routineId: row['routine_id'] as String?,
    habitId: row['habit_id'] as String?,
    kind: BenefitKind.values.byName(
      row['kind'] as String? ?? BenefitKind.digitalTime.name,
    ),
    description: row['description'] as String,
    minutesEarned: row['minutes_earned'] as int,
    minutesUsed: row['minutes_used'] as int? ?? 0,
    dailyLimitMinutes: row['daily_limit_minutes'] as int?,
    expiresAt: _dateTimeOrNull(row['expires_at']),
    accumulationAllowed: row['accumulation_allowed'] as bool? ?? true,
    status: BenefitStatus.values.byName(
      row['status'] as String? ?? BenefitStatus.available.name,
    ),
    sourceAction: row['source_action'] as String?,
    idempotencyKey: row['idempotency_key'] as String?,
    approvedByAdultId: row['approved_by_adult_id'] as String?,
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
        row['owner_id'] ??
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
    null || 'pending' => AdultInvitationStatus.pending,
    'accepted' => AdultInvitationStatus.accepted,
    'revoked' => AdultInvitationStatus.revoked,
    'expired' => AdultInvitationStatus.expired,
    _ => throw StateError('Unknown adult invitation status: $status'),
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

String _habitStatusToDb(HabitStatus status) {
  return switch (status) {
    HabitStatus.newHabit => 'new_habit',
    HabitStatus.proposed => 'proposed',
    HabitStatus.practicing => 'practicing',
    HabitStatus.stable => 'stable',
    HabitStatus.paused => 'paused',
    HabitStatus.archived => 'archived',
  };
}

HabitStatus _habitStatusFromDb(String? status) {
  return switch (status) {
    'new_habit' => HabitStatus.newHabit,
    'practicing' => HabitStatus.practicing,
    'stable' => HabitStatus.stable,
    'paused' => HabitStatus.paused,
    'archived' => HabitStatus.archived,
    _ => HabitStatus.proposed,
  };
}

String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? _dateTimeOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.parse(value as String);
}

List<int> _intList(Object? value) {
  return (value as List? ?? const []).map((item) => item as int).toList();
}

List<String> _stringList(Object? value) {
  return (value as List? ?? const [])
      .map((item) => item.toString())
      .toList(growable: false);
}

Map<String, int> _intMap(Object? value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num).toInt()),
    );
  }
  return const {};
}

RoutinePauseReason? _nullableRoutinePauseReason(String? value) {
  return switch (value) {
    'sensory' => RoutinePauseReason.sensory,
    'interruption' => RoutinePauseReason.interruption,
    _ => null,
  };
}
