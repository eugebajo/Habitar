import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import 'features/adult_registration/adult_registration_screen.dart';
import 'features/family_dashboard/family_dashboard_screen.dart';
import 'features/habit_setup/habit_setup_screen.dart';
import 'features/login/login_screen.dart';
import 'features/notification_settings/notification_settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profiles/profiles_screen.dart';
import 'features/profile_setup/profile_setup_screen.dart';
import 'features/routine_player/routine_player_screen.dart';
import 'features/routine_setup/routine_setup_screen.dart';
import 'features/startup/startup_screen.dart';
import 'features/story_library/story_library_screen.dart';
import 'features/wearables/wearables_screen.dart';
import 'features/wellbeing_checkin/wellbeing_checkin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register',
        builder: (context, state) => const AdultRegistrationScreen()),
    GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(
        path: '/profiles', builder: (context, state) => const ProfilesScreen()),
    GoRoute(
        path: '/dashboard',
        builder: (context, state) => const FamilyDashboardScreen()),
    GoRoute(
        path: '/habits', builder: (context, state) => const HabitSetupScreen()),
    GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationSettingsScreen()),
    GoRoute(
        path: '/routine/create',
        builder: (context, state) => const RoutineSetupScreen()),
    GoRoute(
        path: '/routine/player',
        builder: (context, state) => const RoutinePlayerScreen()),
    GoRoute(
        path: '/wellbeing',
        builder: (context, state) => const WellbeingCheckInScreen()),
    GoRoute(
        path: '/stories',
        builder: (context, state) => const StoryLibraryScreen()),
    GoRoute(
        path: '/wearables',
        builder: (context, state) => const WearablesScreen()),
  ],
);

class HabitarMobileApp extends StatelessWidget {
  const HabitarMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habitos y rutinas',
      theme: buildHabitarTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
