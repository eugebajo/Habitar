import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => InMemoryAuthRepository());
final familyRepositoryProvider = Provider<FamilyRepository>((ref) => InMemoryFamilyRepository());
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => InMemoryProfileRepository());
final routineRepositoryProvider = Provider<RoutineRepository>((ref) => InMemoryRoutineRepository());
final routineSessionRepositoryProvider = Provider<RoutineSessionRepository>((ref) => InMemoryRoutineSessionRepository());
final habitRepositoryProvider = Provider<HabitRepository>((ref) => InMemoryHabitRepository());
final habitProgressRepositoryProvider = Provider<HabitProgressRepository>((ref) => InMemoryHabitProgressRepository());
final notificationPreferenceRepositoryProvider = Provider<NotificationPreferenceRepository>((ref) => InMemoryNotificationPreferenceRepository());
final reminderSchedulerProvider = Provider<InMemoryReminderScheduler>((ref) => InMemoryReminderScheduler());
final emotionCheckInRepositoryProvider = Provider<EmotionCheckInRepository>((ref) => InMemoryEmotionCheckInRepository());
final supportRequestRepositoryProvider = Provider<SupportRequestRepository>((ref) => InMemorySupportRequestRepository());
final storyProgressRepositoryProvider = Provider<StoryProgressRepository>((ref) => InMemoryStoryProgressRepository());
final wearableGatewayRepositoryProvider = Provider<InMemoryWearableGatewayRepository>((ref) => InMemoryWearableGatewayRepository());

final adultRegistrationServiceProvider = Provider<AdultRegistrationService>((ref) {
  return AdultRegistrationService(
    authRepository: ref.watch(authRepositoryProvider),
    familyRepository: ref.watch(familyRepositoryProvider),
  );
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(profileRepositoryProvider));
});

final currentFamilyIdProvider = StateProvider<String?>((ref) => null);
final currentProfileIdProvider = StateProvider<String?>((ref) => null);
final currentProfileKindProvider = StateProvider<ProfileKind?>((ref) => null);
final currentRoutineSessionIdProvider = StateProvider<String?>((ref) => null);

final routineServiceProvider = Provider<RoutineService>((ref) {
  return RoutineService(
    routineRepository: ref.watch(routineRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
  );
});

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService(
    habitRepository: ref.watch(habitRepositoryProvider),
    progressRepository: ref.watch(habitProgressRepositoryProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    preferenceRepository: ref.watch(notificationPreferenceRepositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
  );
});

final wellbeingServiceProvider = Provider<WellbeingService>((ref) {
  return WellbeingService(
    emotionRepository: ref.watch(emotionCheckInRepositoryProvider),
    supportRepository: ref.watch(supportRequestRepositoryProvider),
    storyProgressRepository: ref.watch(storyProgressRepositoryProvider),
  );
});

final wearableServiceProvider = Provider<WearableService>((ref) {
  return WearableService(gateway: ref.watch(wearableGatewayRepositoryProvider));
});

final selectedWearablePlatformProvider = StateProvider<WearablePlatform>((ref) => WearablePlatform.wearOS);
