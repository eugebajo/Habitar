abstract interface class LocalStore {
  Future<void> put(String collection, String id, Map<String, Object?> value);

  Future<Map<String, Object?>?> get(String collection, String id);

  Future<List<Map<String, Object?>>> list(String collection);
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
