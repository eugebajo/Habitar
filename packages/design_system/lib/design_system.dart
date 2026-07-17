import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitarColors {
  static const ink = Color(0xFF1F2A2E);
  static const mutedInk = Color(0xFF657378);
  static const surface = Color(0xFFFBFAF4);
  static const surfaceWarm = Color(0xFFFFF4DF);
  static const surfaceMist = Color(0xFFEFF6F3);
  static const sunlit = Color(0xFFFFE7B8);
  static const deepGreen = Color(0xFF237657);
  static const calmGreen = Color(0xFF7DAA92);
  static const warmGold = Color(0xFFE2B66D);
  static const softBlue = Color(0xFF7EA7C7);
  static const supportRose = Color(0xFFD9928F);
  static const lavender = Color(0xFFC7BDD9);
}

class HabitarSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class HabitarRadius {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

class HabitarMotion {
  static const gentle = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
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
      displaySmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: HabitarColors.ink,
        height: 1.05,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: HabitarColors.ink,
        height: 1.15,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, height: 1.25),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.45, color: HabitarColors.ink),
      bodyMedium: TextStyle(height: 1.45, color: HabitarColors.ink),
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
        borderRadius: const BorderRadius.all(Radius.circular(HabitarRadius.md)),
        side: BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        borderSide:
            BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        borderSide:
            BorderSide(color: HabitarColors.deepGreen.withValues(alpha: 0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(HabitarRadius.md)),
        borderSide: BorderSide(color: HabitarColors.deepGreen, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HabitarColors.deepGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitarRadius.pill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HabitarColors.deepGreen,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        side: const BorderSide(color: HabitarColors.deepGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitarRadius.pill),
        ),
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

class HabitarPage extends StatelessWidget {
  const HabitarPage({
    super.key,
    required this.children,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.all(HabitarSpacing.lg),
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HabitarColors.surface,
      child: SafeArea(
        child: ListView(
          padding: padding,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitarStage extends StatelessWidget {
  const HabitarStage({
    super.key,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.eyebrow,
    this.footer,
  });

  final String? eyebrow;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: HabitarColors.deepGreen,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: HabitarSpacing.sm),
            ],
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: HabitarSpacing.md),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: HabitarColors.mutedInk),
            ),
            const SizedBox(height: HabitarSpacing.xl),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: HabitarSpacing.sm),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
            if (footer != null) ...[
              const SizedBox(height: HabitarSpacing.xl),
              footer!,
            ],
          ],
        );

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HabitarSoftIllustration(height: 220),
              const SizedBox(height: HabitarSpacing.xl),
              content,
            ],
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 620),
          child: Row(
            children: [
              Expanded(flex: 6, child: content),
              const SizedBox(width: HabitarSpacing.xxl),
              const Expanded(
                flex: 5,
                child: HabitarSoftIllustration(height: 460),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HabitarSoftIllustration extends StatelessWidget {
  const HabitarSoftIllustration({super.key, this.height = 280});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: const _HabitarSoftIllustrationPainter(),
    );
  }
}

class HabitarCompanionLayout extends StatelessWidget {
  const HabitarCompanionLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HabitarColors.deepGreen,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: HabitarSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: HabitarSpacing.md),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: HabitarColors.mutedInk),
            ),
          ],
        );

        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              intro,
              const SizedBox(height: HabitarSpacing.lg),
              child,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intro,
                  const SizedBox(height: HabitarSpacing.xl),
                  const HabitarSoftIllustration(height: 300),
                ],
              ),
            ),
            const SizedBox(width: HabitarSpacing.xxl),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _HabitarSoftIllustrationPainter extends CustomPainter {
  const _HabitarSoftIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = HabitarColors.surfaceMist;
    final sun = Paint()..color = HabitarColors.sunlit;
    final hill = Paint()..color = HabitarColors.calmGreen.withValues(alpha: 0.32);
    final hillDeep = Paint()..color = HabitarColors.deepGreen.withValues(alpha: 0.16);
    final path = Paint()..color = HabitarColors.surfaceWarm;
    final home = Paint()..color = Colors.white;
    final roof = Paint()..color = HabitarColors.supportRose.withValues(alpha: 0.8);
    final door = Paint()..color = HabitarColors.deepGreen;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(HabitarRadius.lg),
    );
    canvas.drawRRect(r, sky);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.2), size.shortestSide * 0.16, sun);

    final backHill = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.36, size.width * 0.62, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.83, size.height * 0.72, size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backHill, hillDeep);

    final frontHill = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.48, size.width, size.height * 0.68)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontHill, hill);

    final road = Path()
      ..moveTo(size.width * 0.42, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.78, size.width * 0.55, size.height * 0.58)
      ..lineTo(size.width * 0.67, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.59, size.height * 0.78, size.width * 0.62, size.height)
      ..close();
    canvas.drawPath(road, path);

    final houseBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.42, size.width * 0.26, size.height * 0.22),
      const Radius.circular(18),
    );
    canvas.drawRRect(houseBase, home);

    final roofPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.44)
      ..lineTo(size.width * 0.31, size.height * 0.29)
      ..lineTo(size.width * 0.47, size.height * 0.44)
      ..close();
    canvas.drawPath(roofPath, roof);

    final doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.29, size.height * 0.52, size.width * 0.06, size.height * 0.12),
      const Radius.circular(10),
    );
    canvas.drawRRect(doorRect, door);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HabitarMoment extends StatelessWidget {
  const HabitarMoment({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.color = HabitarColors.sunlit,
    this.trailing,
  });

  final String? eyebrow;
  final String title;
  final String body;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(HabitarRadius.lg),
      ),
      padding: const EdgeInsets.all(HabitarSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HabitarColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: HabitarSpacing.sm),
          ],
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: HabitarSpacing.sm),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          if (trailing != null) ...[
            const SizedBox(height: HabitarSpacing.lg),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class HabitarConversationCard extends StatelessWidget {
  const HabitarConversationCard({
    super.key,
    required this.title,
    required this.body,
    this.color = Colors.white,
    this.leading,
    this.child,
  });

  final String title;
  final String body;
  final Color color;
  final Widget? leading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HabitarSpacing.md),
      padding: const EdgeInsets.all(HabitarSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        border:
            Border.all(color: HabitarColors.deepGreen.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: HabitarSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: HabitarSpacing.xs),
                Text(body),
                if (child != null) ...[
                  const SizedBox(height: HabitarSpacing.md),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HabitarAvatar extends StatelessWidget {
  const HabitarAvatar({
    super.key,
    required this.label,
    this.color = HabitarColors.calmGreen,
    this.size = 72,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? 'H' : trimmed[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(HabitarRadius.lg),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: HabitarColors.deepGreen,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
