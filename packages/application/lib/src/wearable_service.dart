import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';

import 'repositories.dart';

class WearableService {
  const WearableService({
    required this.gateway,
    this.mapper = const WearableSnapshotMapper(),
    this.planner = const WearablePlatformPlanner(),
  });

  final WearableGatewayRepository gateway;
  final WearableSnapshotMapper mapper;
  final WearablePlatformPlanner planner;

  WearableCapabilitySet capabilitiesFor(WearablePlatform platform) {
    return planner.capabilitiesFor(platform);
  }

  Future<WearableConnectionStatus> status(WearablePlatform platform) {
    return gateway.status(platform);
  }

  Future<WearableRoutineSnapshot> publishRoutineSession(
      WearablePlatform platform, RoutineSession session) async {
    final snapshot = mapper.fromRoutineSession(session);
    await gateway.publishSnapshot(platform, snapshot);
    return snapshot;
  }

  Future<List<WearableCommand>> pendingCommands(
      WearablePlatform platform, String sessionId) {
    return gateway.pendingCommands(platform, sessionId);
  }
}
