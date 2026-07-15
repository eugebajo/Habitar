import 'package:habitar_routine_engine/routine_engine.dart';

import 'repositories.dart';

class CreateRoutineInput {
  const CreateRoutineInput({required this.profileId, required this.title, required this.stepTitles});

  final String profileId;
  final String title;
  final List<String> stepTitles;
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

  Future<RoutineSession> requestMoreTime(RoutineSession session, {int minutes = 5}) async {
    final updated = engine.requestMoreTime(session, minutes: minutes, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> pause(RoutineSession session, RoutinePauseReason reason) async {
    final updated = engine.pause(session, reason: reason, now: DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> resume(RoutineSession session) async {
    final updated = engine.resume(session, DateTime.now());
    await sessionRepository.save(updated);
    return updated;
  }

  Future<RoutineSession> postpone(RoutineSession session, Duration duration) async {
    final updated = engine.postpone(session, duration: duration, now: DateTime.now());
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
