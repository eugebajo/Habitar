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
    this.engine = const RoutineEngine(),
  });

  final RoutineRepository routineRepository;
  final RoutineSessionRepository sessionRepository;
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
      sessionId: '${routine.metadata.id}-session',
      routine: routine,
      steps: steps,
      now: DateTime.now(),
    );
    await sessionRepository.save(session);
    return session;
  }

  Future<RoutineSession?> activeSessionForProfile(String profileId) {
    return sessionRepository.activeSessionForProfile(profileId);
  }

  Future<RoutineSession> completeStep(RoutineSession session) async {
    final updated = engine.completeActiveStep(session, DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> requestMoreTime(RoutineSession session,
      {int minutes = 5}) async {
    final updated =
        engine.requestMoreTime(session, minutes: minutes, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> pause(
      RoutineSession session, RoutinePauseReason reason) async {
    final updated = engine.pause(session, reason: reason, now: DateTime.now());
    await sessionRepository.save(updated);
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
    return updated;
  }

  Future<RoutineSession> skipStep(RoutineSession session) async {
    final updated = engine.skipActiveStep(session, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }
}
