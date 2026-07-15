import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitarColors {
  static const ink = Color(0xFF1F2A2E);
  static const surface = Color(0xFFF7F8F5);
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
      headlineSmall: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
    cardTheme: const CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
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
