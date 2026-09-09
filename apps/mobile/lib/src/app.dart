import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'dependencies.dart';
import 'features/adult_registration/adult_registration_screen.dart';
import 'features/family_dashboard/family_dashboard_screen.dart';
import 'features/habit_setup/habit_setup_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/login/login_screen.dart';
import 'features/login/pending_invitation_screen.dart';
import 'features/login/password_recovery_screen.dart';
import 'features/login/redeem_invitation_code_screen.dart';
import 'features/notification_settings/notification_settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profiles/profiles_screen.dart';
import 'features/profile_setup/profile_setup_screen.dart';
import 'features/portal/portal_screens.dart';
import 'features/account/account_screen.dart';
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
        builder: (context, state) => const PasswordRecoveryScreen()),
    GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen()),
    GoRoute(
        path: '/register',
        builder: (context, state) => const AdultRegistrationScreen()),
    GoRoute(
        path: '/invitation',
        builder: (context, state) => const PendingInvitationScreen()),
    GoRoute(
        path: '/invitation/redeem',
        builder: (context, state) => const RedeemInvitationCodeScreen()),
    GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(
        path: '/profiles', builder: (context, state) => const ProfilesScreen()),
    GoRoute(path: '/adult-pin', redirect: (context, state) => '/login'),
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
    GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
    GoRoute(
        path: '/habits', builder: (context, state) => const HabitSetupScreen()),
    GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationSettingsScreen()),
    GoRoute(
        path: '/routine/create',
        builder: (context, state) => RoutineSetupScreen(
              routineId: state.uri.queryParameters['edit'],
            )),
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

class HabitarMobileApp extends ConsumerStatefulWidget {
  const HabitarMobileApp({super.key});

  @override
  ConsumerState<HabitarMobileApp> createState() => _HabitarMobileAppState();
}

class _HabitarMobileAppState extends ConsumerState<HabitarMobileApp> {
  StreamSubscription<supabase.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenForPasswordRecovery();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenForPasswordRecovery() {
    try {
      final auth = supabase.Supabase.instance.client.auth;
      _authSubscription = auth.onAuthStateChange.listen((data) {
        if (data.event != supabase.AuthChangeEvent.passwordRecovery) {
          return;
        }
        ref.read(passwordRecoveryActiveProvider.notifier).state = true;
        appRouter.go('/reset-password');
      });
    } catch (_) {
      // Supabase is not initialized in local-only development/test overrides.
    }
  }

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
    return ValueListenableBuilder(
      valueListenable: appRouter.routeInformationProvider,
      builder: (context, routeInformation, _) {
        final location = routeInformation.uri.path;
        return PopScope(
          canPop: _isExitRoot(location),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            final target = _safeBackTarget(location);
            if (target != null && target != location) {
              appRouter.go(target);
            }
          },
          child: child,
        );
      },
    );
  }

  bool _isExitRoot(String location) {
    return location == '/' ||
        location == '/onboarding' ||
        location == '/dashboard';
  }

  String? _safeBackTarget(String location) {
    if (_isExitRoot(location)) return null;
    if (location == '/recover' || location == '/reset-password') {
      return '/login';
    }
    if (location == '/login' || location == '/register') {
      return '/onboarding';
    }
    if (location == '/invitation' || location == '/invitation/redeem') {
      return '/onboarding';
    }
    if (location == '/profile' || location == '/profiles') return '/dashboard';
    if (location == '/routine/create' || location == '/habits') {
      return '/routines';
    }
    if (location == '/routine/player') return '/child';
    if (location.startsWith('/child') || location.startsWith('/teen')) {
      return '/profiles';
    }
    return '/dashboard';
  }
}
