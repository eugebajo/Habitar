import 'dart:convert';
import 'dart:io';

abstract interface class LocalStore {
  Future<void> put(String collection, String id, Map<String, Object?> value);

  Future<Map<String, Object?>?> get(String collection, String id);

  Future<List<Map<String, Object?>>> list(String collection);
}

class FileLocalStore implements LocalStore {
  FileLocalStore(this.file);

  final File file;

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final data = await _read();
    return data[collection]?[id];
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) async {
    final data = await _read();
    final values = data[collection]?.values ??
        const Iterable<Map<String, Object?>>.empty();
    return values.map(Map<String, Object?>.of).toList(growable: false);
  }

  @override
  Future<void> put(
      String collection, String id, Map<String, Object?> value) async {
    final data = await _read();
    final bucket =
        data.putIfAbsent(collection, () => <String, Map<String, Object?>>{});
    bucket[id] = Map<String, Object?>.of(value);
    await _write(data);
  }

  Future<Map<String, Map<String, Map<String, Object?>>>> _read() async {
    if (!await file.exists()) {
      return {};
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return decoded.map((collection, value) {
      final records = (value as Map<String, Object?>).map((id, record) {
        return MapEntry(id, (record as Map).cast<String, Object?>());
      });
      return MapEntry(collection, records);
    });
  }

  Future<void> _write(
      Map<String, Map<String, Map<String, Object?>>> data) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }
}

class LocalStoreCollections {
  static const users = 'users';
  static const families = 'families';
  static const childProfiles = 'child_profiles';
  static const teenProfiles = 'teen_profiles';
  static const routines = 'routines';
  static const routineSteps = 'routine_steps';
  static const routineSessions = 'routine_sessions';
  static const habits = 'habits';
  static const habitProgress = 'habit_progress';
  static const notificationPreferences = 'notification_preferences';
  static const emotionCheckIns = 'emotion_check_ins';
  static const supportRequests = 'support_requests';
  static const storyProgress = 'story_progress';
  static const wearableSnapshots = 'wearable_snapshots';
  static const wearableCommands = 'wearable_commands';
  static const authState = 'auth_state';
}
