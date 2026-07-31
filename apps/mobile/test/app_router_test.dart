import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_mobile/src/app.dart';

void main() {
  test('keeps the public route inventory stable', () {
    final paths = appRouter.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    expect(paths, <String>[
      '/',
      '/onboarding',
      '/login',
      '/privacy',
      '/terms',
      '/recover',
      '/register',
      '/profile',
      '/profiles',
      '/adult-pin',
      '/dashboard',
      '/routines',
      '/progress',
      '/habits/list',
      '/rewards',
      '/settings',
      '/habits',
      '/notifications',
      '/routine/create',
      '/routine/player',
      '/wellbeing',
      '/stories',
      '/wearables',
      '/child',
      '/kid',
      '/child/achievements',
      '/child/stories',
      '/child/emotions',
      '/teen',
      '/teen/habits',
      '/teen/progress',
      '/teen/reflection',
      '/teen/privacy',
    ]);
  });
}
