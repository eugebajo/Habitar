import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import 'features/adult_registration/adult_registration_screen.dart';
import 'features/family_dashboard/family_dashboard_screen.dart';
import 'features/habit_setup/habit_setup_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/login/login_screen.dart';
import 'features/notification_settings/notification_settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profiles/profiles_screen.dart';
import 'features/profile_setup/profile_setup_screen.dart';
import 'features/portal/portal_screens.dart';
import 'features/routine_player/routine_player_screen.dart';
import 'features/rewards/rewards_screen.dart';
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
        path: '/privacy',
        builder: (context, state) => const LegalScreen(
              title: 'Política de privacidad',
              kind: LegalDocumentKind.privacy,
            )),
    GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(
              title: 'Términos de uso',
              kind: LegalDocumentKind.terms,
            )),
    GoRoute(
        path: '/recover',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Recuperar contraseña',
            message:
                'Escribí a soporte@habitarpy.com desde el correo de tu cuenta.')),
    GoRoute(
        path: '/register',
        builder: (context, state) => const AdultRegistrationScreen()),
    GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(
        path: '/profiles', builder: (context, state) => const ProfilesScreen()),
    GoRoute(
        path: '/adult-pin',
        builder: (context, state) => const AdultPinScreen()),
    GoRoute(
        path: '/dashboard',
        builder: (context, state) => const FamilyDashboardScreen()),
    GoRoute(
        path: '/routines',
        builder: (context, state) =>
            const AdultSectionScreen(kind: 'routines')),
    GoRoute(
        path: '/progress',
        builder: (context, state) =>
            const AdultSectionScreen(kind: 'progress')),
    GoRoute(
        path: '/habits/list',
        builder: (context, state) => const AdultSectionScreen(kind: 'habits')),
    GoRoute(
        path: '/rewards', builder: (context, state) => const RewardsScreen()),
    GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const AdultSectionScreen(kind: 'settings')),
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
    GoRoute(
        path: '/child', builder: (context, state) => const ChildHomeScreen()),
    GoRoute(path: '/kid', builder: (context, state) => const ChildHomeScreen()),
    GoRoute(
        path: '/child/achievements',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Mis logros',
            message: 'Cada paso cuenta. Aquí aparecen tus avances recientes.')),
    GoRoute(
        path: '/child/stories',
        builder: (context, state) => const StoryLibraryScreen()),
    GoRoute(
        path: '/child/emotions',
        builder: (context, state) => const WellbeingCheckInScreen()),
    GoRoute(path: '/teen', builder: (context, state) => const TeenHomeScreen()),
    GoRoute(
        path: '/teen/habits',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Mis hábitos',
            message: 'Elegí una versión pequeña y posible para hoy.',
            teen: true)),
    GoRoute(
        path: '/teen/progress',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Mi progreso',
            message: 'Observá lo que funcionó sin compararte.',
            teen: true)),
    GoRoute(
        path: '/teen/reflection',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Reflexión diaria',
            message: 'Este espacio es privado. Escribí solo si te ayuda.',
            teen: true)),
    GoRoute(
        path: '/teen/privacy',
        builder: (context, state) => const SimpleModeScreen(
            title: 'Privacidad',
            message: 'Vos decidís qué reflexiones compartir.',
            teen: true)),
  ],
);

class HabitarMobileApp extends StatelessWidget {
  const HabitarMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hábitos y rutinas',
      theme: buildHabitarTheme(),
      routerConfig: appRouter,
      builder: (context, child) => _AppBackGuard(
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppBackGuard extends StatelessWidget {
  const _AppBackGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final location = appRouter.routeInformationProvider.value.uri.path;
        final target = _safeBackTarget(location);
        if (target != null && target != location) {
          appRouter.go(target);
        }
      },
      child: child,
    );
  }

  String? _safeBackTarget(String location) {
    if (location == '/' || location == '/onboarding') return null;
    if (location == '/login' ||
        location == '/register' ||
        location == '/recover') {
      return '/onboarding';
    }
    if (location == '/profile' || location == '/profiles') return '/dashboard';
    if (location.startsWith('/child') || location.startsWith('/teen')) {
      return '/profiles';
    }
    return '/dashboard';
  }
}
