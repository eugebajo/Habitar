import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitarColors {
  static const ink = Color(0xFF1F2A2E);
  static const surface = Color(0xFFFAFAF6);
  static const surfaceWarm = Color(0xFFFFF4DF);
  static const sunlit = Color(0xFFFFE7B8);
  static const deepGreen = Color(0xFF237657);
  static const calmGreen = Color(0xFF7DAA92);
  static const warmGold = Color(0xFFE2B66D);
  static const softBlue = Color(0xFF7EA7C7);
  static const supportRose = Color(0xFFD9928F);
}

class HabitarSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

ThemeData buildHabitarTheme({bool lowStimulation = false}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HabitarColors.calmGreen,
    brightness: Brightness.light,
    surface: HabitarColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: HabitarColors.surface,
    textTheme: const TextTheme(
      displaySmall:
          TextStyle(fontWeight: FontWeight.w800, color: HabitarColors.ink),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.25),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HabitarColors.surface,
      foregroundColor: HabitarColors.ink,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: HabitarColors.deepGreen, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HabitarColors.deepGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HabitarColors.deepGreen,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: HabitarColors.deepGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    pageTransitionsTheme: lowStimulation
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          )
        : null,
  );
}
