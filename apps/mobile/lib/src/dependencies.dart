import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';

import 'platform/push_messaging_gateway.dart';
import 'push_notifications.dart';

final localStoreProvider = Provider<LocalStore?>((ref) => null);
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => InMemoryAuthRepository());
final familyRepositoryProvider =
    Provider<FamilyRepository>((ref) => InMemoryFamilyRepository());
final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => InMemoryProfileRepository());
final routineRepositoryProvider =
    Provider<RoutineRepository>((ref) => InMemoryRoutineRepository());
final adultProfileRepositoryProvider =
    Provider<AdultProfileRepository>((ref) => InMemoryAdultProfileRepository());
final familyActivityEventRepositoryProvider =
    Provider<FamilyActivityEventRepository>(
        (ref) => InMemoryFamilyActivityEventRepository());

final routineSessionRepositoryProvider = Provider<RoutineSessionRepository>(
    (ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final activityEvents = ref.watch(familyActivityEventRepositoryProvider);
  return InMemoryRoutineSessionRepository(
    profileRepository:
        profileRepository is InMemoryProfileRepository ? profileRepository : null,
    activityEvents: activityEvents is InMemoryFamilyActivityEventRepository
        ? activityEvents
        : null,
  );
});
final routineOverrideRepositoryProvider = Provider<RoutineOverrideRepository>(
    (ref) => InMemoryRoutineOverrideRepository());
final habitRepositoryProvider =
    Provider<HabitRepository>((ref) => InMemoryHabitRepository());
final habitProgressRepositoryProvider = Provider<HabitProgressRepository>(
    (ref) => InMemoryHabitProgressRepository());
final timeBankRepositoryProvider =
    Provider<TimeBankRepository>((ref) => InMemoryTimeBankRepository());
final notificationPreferenceRepositoryProvider =
    Provider<NotificationPreferenceRepository>(
        (ref) => InMemoryNotificationPreferenceRepository());
final reminderSchedulerProvider =
    Provider<LocalReminderScheduler>((ref) => InMemoryReminderScheduler());
final emotionCheckInRepositoryProvider = Provider<EmotionCheckInRepository>(
    (ref) => InMemoryEmotionCheckInRepository());
final supportRequestRepositoryProvider = Provider<SupportRequestRepository>(
    (ref) => InMemorySupportRequestRepository());
final storyProgressRepositoryProvider = Provider<StoryProgressRepository>(
    (ref) => InMemoryStoryProgressRepository());
final wearableGatewayRepositoryProvider = Provider<WearableGatewayRepository>(
    (ref) => InMemoryWearableGatewayRepository());
final syncQueueRepositoryProvider =
    Provider<SyncQueueRepository>((ref) => InMemorySyncQueueRepository());

// Etapa 3 (notificaciones push).
final deviceTokenRepositoryProvider =
    Provider<DeviceTokenRepository>((ref) => InMemoryDeviceTokenRepository());
final pushNotificationPreferenceRepositoryProvider =
    Provider<PushNotificationPreferenceRepository>(
        (ref) => InMemoryPushNotificationPreferenceRepository());
// NoOp por default: solo app_environment_io.dart lo reemplaza por el
// gateway real de Firebase, y solo en Android/iOS - web y escritorio
// (sin configuracion de Firebase) siguen con este, que nunca falla ni
// entrega nada.
final pushMessagingGatewayProvider =
    Provider<PushMessagingGateway>((ref) => const NoOpPushMessagingGateway());
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    gateway: ref.watch(pushMessagingGatewayProvider),
    deviceTokenRepository: ref.watch(deviceTokenRepositoryProvider),
    reminderScheduler: ref.watch(reminderSchedulerProvider),
    localStore: ref.watch(localStoreProvider),
  );
});

final adultRegistrationServiceProvider =
    Provider<AdultRegistrationService>((ref) {
  return AdultRegistrationService(
    authRepository: ref.watch(authRepositoryProvider),
    familyRepository: ref.watch(familyRepositoryProvider),
  );
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(authRepositoryProvider));
});

final passwordRecoveryServiceProvider =
    Provider<PasswordRecoveryService>((ref) {
  return PasswordRecoveryService(ref.watch(authRepositoryProvider));
});

final adultProfileServiceProvider = Provider<AdultProfileService>((ref) {
  return AdultProfileService(
    repository: ref.watch(adultProfileRepositoryProvider),
  );
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    repository: ref.watch(profileRepositoryProvider),
    routineRepository: ref.watch(routineRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
    habitRepository: ref.watch(habitRepositoryProvider),
    progressRepository: ref.watch(habitProgressRepositoryProvider),
  );
});

final currentFamilyIdProvider = StateProvider<String?>((ref) => null);
final currentProfileIdProvider = StateProvider<String?>((ref) => null);
final currentProfileKindProvider = StateProvider<ProfileKind?>((ref) => null);
final currentRoutineSessionIdProvider = StateProvider<String?>((ref) => null);
final passwordRecoveryActiveProvider = StateProvider<bool>((ref) => false);

final routineServiceProvider = Provider<RoutineService>((ref) {
  return RoutineService(
    routineRepository: ref.watch(routineRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
    supportRepository: ref.watch(supportRequestRepositoryProvider),
  );
});

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService(
    habitRepository: ref.watch(habitRepositoryProvider),
    progressRepository: ref.watch(habitProgressRepositoryProvider),
  );
});

final timeBankServiceProvider = Provider<TimeBankService>((ref) {
  return TimeBankService(repository: ref.watch(timeBankRepositoryProvider));
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

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(syncQueueRepositoryProvider));
});

final selectedWearablePlatformProvider =
    StateProvider<WearablePlatform>((ref) => WearablePlatform.wearOS);
