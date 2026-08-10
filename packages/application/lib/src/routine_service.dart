import 'dart:math';

import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

import 'repositories.dart';

class CreateRoutineInput {
  const CreateRoutineInput({
    required this.profileId,
    required this.title,
    required this.stepTitles,
    this.weekdays = const [],
    this.scheduledHour,
    this.scheduledMinute,
    this.estimatedDurationMinutes,
    this.leadReminderMinutes = 10,
    this.repeatPolicy = RoutineRepeatPolicy.weekly,
    this.responsibleAdultProfileId,
    this.contextLabel,
    this.minimumVersion,
    this.benefitDescription,
    this.maxReminderCount = 2,
    this.reminderIntervalMinutes = 5,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.silentNotification = false,
    this.canPostpone = true,
    this.canRequestHelp = true,
  });

  final String profileId;
  final String title;
  final List<String> stepTitles;
  final List<int> weekdays;
  final int? scheduledHour;
  final int? scheduledMinute;
  final int? estimatedDurationMinutes;
  final int leadReminderMinutes;
  final RoutineRepeatPolicy repeatPolicy;
  final String? responsibleAdultProfileId;
  final String? contextLabel;
  final String? minimumVersion;
  final String? benefitDescription;
  final int maxReminderCount;
  final int reminderIntervalMinutes;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool silentNotification;
  final bool canPostpone;
  final bool canRequestHelp;
}

class RoutineService {
  const RoutineService({
    required this.routineRepository,
    required this.sessionRepository,
    this.supportRepository,
    this.engine = const RoutineEngine(),
  });

  final RoutineRepository routineRepository;
  final RoutineSessionRepository sessionRepository;
  final SupportRequestRepository? supportRepository;
  final RoutineEngine engine;

  Future<RoutineSession> createAndStart(CreateRoutineInput input) async {
    final routine = await routineRepository.createRoutine(
      profileId: input.profileId,
      title: input.title,
      stepTitles: input.stepTitles,
      weekdays: input.weekdays,
      scheduledHour: input.scheduledHour,
      scheduledMinute: input.scheduledMinute,
      estimatedDurationMinutes: input.estimatedDurationMinutes,
      leadReminderMinutes: input.leadReminderMinutes,
      repeatPolicy: input.repeatPolicy,
      responsibleAdultProfileId: input.responsibleAdultProfileId,
      contextLabel: input.contextLabel,
      minimumVersion: input.minimumVersion,
      benefitDescription: input.benefitDescription,
      maxReminderCount: input.maxReminderCount,
      reminderIntervalMinutes: input.reminderIntervalMinutes,
      vibrationEnabled: input.vibrationEnabled,
      soundEnabled: input.soundEnabled,
      silentNotification: input.silentNotification,
      canPostpone: input.canPostpone,
      canRequestHelp: input.canRequestHelp,
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final session = engine.start(
      sessionId: _newUuid(),
      routine: routine,
      steps: steps,
      now: DateTime.now(),
    );
    await sessionRepository.save(session);
    _debugLog(
      'SESSION CREATED: session_id=${session.id} routine_id=${routine.metadata.id} profile_id=${routine.profileId}',
    );
    return session;
  }

  Future<RoutineSession?> activeSessionForProfile(String profileId) {
    return sessionRepository.activeSessionForProfile(profileId);
  }

  Future<RoutineSession> startExistingRoutine(
    Routine routine, {
    List<RoutineStep>? steps,
  }) async {
    final loadedSteps =
        steps ?? await routineRepository.stepsForRoutine(routine.metadata.id);
    final session = engine.start(
      sessionId: _newUuid(),
      routine: routine,
      steps: loadedSteps,
      now: DateTime.now(),
    );
    await sessionRepository.save(session);
    _debugLog(
      'SESSION CREATED: session_id=${session.id} routine_id=${routine.metadata.id} profile_id=${routine.profileId}',
    );
    return session;
  }

  Future<RoutineSession> completeStep(RoutineSession session) async {
    final stepId = session.activeStep?.metadata.id;
    final updated = engine.completeActiveStep(session, DateTime.now());
    await sessionRepository.save(updated);
    _debugLog(
      'STEP COMPLETED: session_id=${updated.id} step_id=${stepId ?? 'none'} persisted YES',
    );
    if (updated.status == RoutineSessionStatus.completed) {
      _debugLog(
        'FINAL STEP COMPLETED: session_id=${updated.id} step_id=${stepId ?? 'none'} completed_count=${updated.completedStepIds.length} total_steps=${updated.steps.length}',
      );
      _debugLog(
        'SESSION COMPLETED: session_id=${updated.id} status=${updated.status.name} persisted YES',
      );
    }
    return updated;
  }

  Future<RoutineSession> requestMoreTime(RoutineSession session,
      {int minutes = 5}) async {
    final updated =
        engine.requestMoreTime(session, minutes: minutes, now: DateTime.now());
    await sessionRepository.save(updated);
    await _saveSupportRequest(
      updated,
      kind: 'extra_time',
      note: _sessionNote(updated, stepId: session.activeStep?.metadata.id),
    );
    return updated;
  }

  Future<RoutineSession> pause(
      RoutineSession session, RoutinePauseReason reason) async {
    final updated = engine.pause(session, reason: reason, now: DateTime.now());
    await sessionRepository.save(updated);
    await _saveSupportRequest(
      updated,
      kind: 'pause',
      note: _sessionNote(updated, stepId: session.activeStep?.metadata.id),
    );
    return updated;
  }

  Future<RoutineSession> resume(RoutineSession session) async {
    final updated = engine.resume(session, DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> postpone(
      RoutineSession session, Duration duration) async {
    final updated =
        engine.postpone(session, duration: duration, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> requestHelp(RoutineSession session) async {
    final updated = engine.requestHelp(session, DateTime.now());
    await sessionRepository.save(updated);
    await _saveSupportRequest(
      updated,
      kind: 'help',
      note: _sessionNote(updated, stepId: session.activeStep?.metadata.id),
    );
    return updated;
  }

  Future<RoutineSession> skipStep(RoutineSession session) async {
    final updated = engine.skipActiveStep(session, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<void> _saveSupportRequest(
    RoutineSession session, {
    required String kind,
    required String note,
  }) async {
    final repository = supportRepository;
    if (repository == null) {
      return;
    }
    final request = await repository.save(
      SupportRequest(
        metadata: EntityMetadata(
          id: _newUuid(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ownerId: session.routine.metadata.ownerId,
        ),
        profileId: session.routine.profileId,
        kind: kind,
        note: note,
      ),
    );
    _debugLog(
      'SUPPORT REQUEST CREATED: request_id=${request.metadata.id} type=$kind profile_id=${request.profileId} session_id=${session.id}',
    );
  }
}

String _sessionNote(RoutineSession session, {String? stepId}) {
  final parts = [
    'session_id=${session.id}',
    'routine_id=${session.routine.metadata.id}',
    if (stepId != null) 'step_id=$stepId',
  ];
  return parts.join('; ');
}

String _newUuid() {
  final random = Random();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final chars = bytes.map(hex).join();
  return '${chars.substring(0, 8)}-'
      '${chars.substring(8, 12)}-'
      '${chars.substring(12, 16)}-'
      '${chars.substring(16, 20)}-'
      '${chars.substring(20)}';
}

void _debugLog(String message) {
  assert(() {
    // Development-only diagnostics. Do not log passwords, tokens or secrets.
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
