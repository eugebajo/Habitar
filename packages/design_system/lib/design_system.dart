import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitarColors {
  static const ink = Color(0xFF243330);
  static const mutedInk = Color(0xFF65746F);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceWarm = Color(0xFFFFF5DE);
  static const surfaceMist = Color(0xFFEAF3EA);
  static const card = Color(0xFFFFFEFA);
  static const line = Color(0xFFE7DAC7);
  static const sunlit = Color(0xFFE7B747);
  static const deepGreen = Color(0xFF315E41);
  static const primaryGreen = Color(0xFF537E5A);
  static const calmGreen = Color(0xFF8EA787);
  static const warmGold = Color(0xFFE5B857);
  static const softBlue = Color(0xFF9DB6C7);
  static const supportRose = Color(0xFFEAA17E);
  static const lavender = Color(0xFFC7BDD9);
  static const danger = Color(0xFFC96055);
}

class HabitarSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class HabitarRadius {
  static const sm = 8.0;
  static const md = 18.0;
  static const lg = 28.0;
  static const xl = 36.0;
  static const pill = 999.0;
}

class HabitarMotion {
  static const gentle = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}

ThemeData buildHabitarTheme({bool lowStimulation = false}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HabitarColors.primaryGreen,
    brightness: Brightness.light,
    surface: HabitarColors.surface,
    primary: HabitarColors.deepGreen,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: HabitarColors.surface,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: HabitarColors.deepGreen,
        height: 1.02,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: HabitarColors.deepGreen,
        height: 1.05,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: HabitarColors.deepGreen,
        height: 1.12,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: HabitarColors.ink,
        height: 1.18,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: HabitarColors.ink,
        height: 1.25,
      ),
      bodyLarge:
          TextStyle(fontSize: 17, height: 1.45, color: HabitarColors.ink),
      bodyMedium:
          TextStyle(fontSize: 15, height: 1.45, color: HabitarColors.ink),
      labelLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HabitarColors.surface,
      foregroundColor: HabitarColors.deepGreen,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: HabitarColors.deepGreen,
        fontSize: 27,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      color: HabitarColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(HabitarRadius.lg)),
        side: BorderSide(color: HabitarColors.line.withValues(alpha: .8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HabitarColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: const TextStyle(color: HabitarColors.primaryGreen),
      prefixIconColor: HabitarColors.primaryGreen,
      suffixIconColor: HabitarColors.primaryGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        borderSide: const BorderSide(color: HabitarColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        borderSide: const BorderSide(color: HabitarColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HabitarRadius.md),
        borderSide:
            const BorderSide(color: HabitarColors.deepGreen, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HabitarColors.deepGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 58),
        elevation: 7,
        shadowColor: HabitarColors.deepGreen.withValues(alpha: .22),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitarRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HabitarColors.deepGreen,
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        side: const BorderSide(color: HabitarColors.deepGreen, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitarRadius.md),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: HabitarColors.card,
      indicatorColor: HabitarColors.surfaceMist,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .08),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? HabitarColors.deepGreen
              : HabitarColors.mutedInk,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? HabitarColors.deepGreen
              : HabitarColors.mutedInk,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF6), Color(0xFFFFF8ED)],
        ),
      ),
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

class HabitarLogo extends StatelessWidget {
  const HabitarLogo({super.key, this.size = 74, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: const _HabitarLogoPainter(),
    );
    if (!showWordmark) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 4),
        Text(
          'Habitar',
          style: TextStyle(
            color: HabitarColors.primaryGreen,
            fontSize: (size * .48).clamp(22, 40),
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class HabitarWordmark extends StatelessWidget {
  const HabitarWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: compact ? 34 : 44,
          child: const HabitarLogo(showWordmark: false),
        ),
        const SizedBox(width: 8),
        Text(
          'Habitar',
          style: TextStyle(
            color: HabitarColors.primaryGreen,
            fontSize: compact ? 25 : 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HabitarLogoPainter extends CustomPainter {
  const _HabitarLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = HabitarColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillGreen = Paint()..color = HabitarColors.primaryGreen;
    final fillGold = Paint()..color = HabitarColors.warmGold;
    final w = size.width;
    final h = size.height;
    final house = Path()
      ..moveTo(w * .24, h * .57)
      ..lineTo(w * .24, h * .28)
      ..quadraticBezierTo(w * .24, h * .2, w * .31, h * .15)
      ..lineTo(w * .5, h * .02)
      ..lineTo(w * .69, h * .15)
      ..quadraticBezierTo(w * .76, h * .2, w * .76, h * .28)
      ..lineTo(w * .76, h * .57);
    canvas.drawPath(house, stroke);
    canvas.drawCircle(Offset(w * .5, h * .28), w * .08, fillGold);
    final leftLeaf = Path()
      ..moveTo(w * .47, h * .74)
      ..cubicTo(w * .25, h * .7, w * .26, h * .44, w * .43, h * .45)
      ..cubicTo(w * .54, h * .52, w * .54, h * .66, w * .47, h * .74);
    final rightLeaf = Path()
      ..moveTo(w * .53, h * .74)
      ..cubicTo(w * .75, h * .7, w * .74, h * .44, w * .57, h * .45)
      ..cubicTo(w * .46, h * .52, w * .46, h * .66, w * .53, h * .74);
    canvas.drawPath(leftLeaf, fillGreen);
    canvas.drawPath(rightLeaf, fillGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HabitarCard extends StatelessWidget {
  const HabitarCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HabitarSpacing.lg),
    this.color = HabitarColors.card,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(HabitarRadius.lg),
        border: Border.all(color: borderColor ?? HabitarColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .055),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(HabitarRadius.lg),
      onTap: onTap,
      child: content,
    );
  }
}

class HabitarPill extends StatelessWidget {
  const HabitarPill({
    super.key,
    required this.label,
    this.icon,
    this.color = HabitarColors.surfaceMist,
    this.foreground = HabitarColors.deepGreen,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(HabitarRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class HabitarScreenHeader extends StatelessWidget {
  const HabitarScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.centerLogo = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool centerLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centerLogo ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (centerLogo) const Spacer(),
            if (centerLogo) const HabitarWordmark(compact: true),
            if (!centerLogo)
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.displaySmall)),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
            if (centerLogo) const Spacer(),
          ],
        ),
        if (centerLogo) ...[
          const SizedBox(height: 22),
          Text(title,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: HabitarColors.mutedInk),
            textAlign: centerLogo ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: HabitarLogo(size: 78)),
        const SizedBox(height: HabitarSpacing.xl),
        HabitarSoftIllustration(height: 330, label: eyebrow ?? 'familia'),
        const SizedBox(height: HabitarSpacing.lg),
        Text(title,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: HabitarSpacing.md),
        Text(body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: HabitarSpacing.lg),
        if (footer != null) ...[
          Center(child: footer!),
          const SizedBox(height: HabitarSpacing.lg),
        ],
        FilledButton.icon(
          onPressed: onPrimary,
          icon: const SizedBox.shrink(),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(primaryLabel),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: HabitarSpacing.md),
          OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}

class HabitarSoftIllustration extends StatelessWidget {
  const HabitarSoftIllustration(
      {super.key, this.height = 280, this.label = 'home'});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _HabitarSoftIllustrationPainter(label),
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
            const HabitarWordmark(compact: true),
            const SizedBox(height: HabitarSpacing.xl),
            Text(eyebrow,
                style: const TextStyle(
                    color: HabitarColors.deepGreen,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: HabitarSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: HabitarSpacing.md),
            Text(body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: HabitarColors.mutedInk)),
            const SizedBox(height: HabitarSpacing.xl),
            const HabitarSoftIllustration(height: 250, label: 'home'),
          ],
        );

        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [intro, const SizedBox(height: HabitarSpacing.lg), child],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: intro),
            const SizedBox(width: HabitarSpacing.xxl),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _HabitarSoftIllustrationPainter extends CustomPainter {
  const _HabitarSoftIllustrationPainter(this.label);

  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = HabitarColors.surfaceMist;
    final sun = Paint()..color = HabitarColors.sunlit;
    final line = Paint()
      ..color = HabitarColors.deepGreen.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = HabitarColors.calmGreen.withValues(alpha: .55);
    final warm = Paint()..color = HabitarColors.surfaceWarm;
    final card = Paint()..color = Colors.white.withValues(alpha: .9);

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(HabitarRadius.xl),
    );
    canvas.drawRRect(r, bg);
    canvas.drawCircle(Offset(size.width * .78, size.height * .22),
        size.shortestSide * .12, sun);

    final hill = Path()
      ..moveTo(0, size.height * .68)
      ..quadraticBezierTo(
          size.width * .35, size.height * .48, size.width, size.height * .65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, fill);

    if (label.contains('bag') || label.contains('mochila')) {
      final bag = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .34, size.height * .35, size.width * .28,
            size.height * .36),
        const Radius.circular(24),
      );
      canvas.drawRRect(bag, Paint()..color = HabitarColors.calmGreen);
      canvas.drawArc(
          Rect.fromLTWH(size.width * .39, size.height * .25, size.width * .18,
              size.height * .22),
          3.14,
          3.14,
          false,
          line);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * .38, size.height * .52,
                  size.width * .2, size.height * .11),
              const Radius.circular(12)),
          card);
      canvas.drawCircle(Offset(size.width * .24, size.height * .72),
          size.shortestSide * .035, Paint()..color = HabitarColors.warmGold);
      canvas.drawCircle(Offset(size.width * .73, size.height * .66),
          size.shortestSide * .045, Paint()..color = HabitarColors.supportRose);
      return;
    }

    if (label.contains('watch')) {
      final watch = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .56, size.height * .24, size.width * .22,
              size.height * .36),
          const Radius.circular(24));
      canvas.drawRRect(watch, Paint()..color = HabitarColors.ink);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * .61, size.height * .07,
                  size.width * .12, size.height * .2),
              const Radius.circular(18)),
          Paint()..color = HabitarColors.calmGreen);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width * .61, size.height * .57,
                  size.width * .12, size.height * .27),
              const Radius.circular(18)),
          Paint()..color = HabitarColors.calmGreen);
      canvas.drawCircle(Offset(size.width * .67, size.height * .42),
          size.shortestSide * .06, Paint()..color = Colors.white);
      canvas.drawLine(Offset(size.width * .25, size.height * .35),
          Offset(size.width * .39, size.height * .35), line);
      canvas.drawLine(Offset(size.width * .23, size.height * .46),
          Offset(size.width * .38, size.height * .43), line);
      return;
    }

    final houseBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .28, size.height * .43, size.width * .25,
          size.height * .24),
      const Radius.circular(20),
    );
    canvas.drawRRect(houseBase, card);
    final roof = Path()
      ..moveTo(size.width * .24, size.height * .45)
      ..lineTo(size.width * .405, size.height * .28)
      ..lineTo(size.width * .57, size.height * .45)
      ..close();
    canvas.drawPath(roof,
        Paint()..color = HabitarColors.supportRose.withValues(alpha: .78));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * .38, size.height * .55, size.width * .07,
                size.height * .12),
            const Radius.circular(12)),
        Paint()..color = HabitarColors.deepGreen);
    final road = Path()
      ..moveTo(size.width * .43, size.height)
      ..quadraticBezierTo(size.width * .52, size.height * .75, size.width * .58,
          size.height * .58)
      ..lineTo(size.width * .68, size.height * .58)
      ..quadraticBezierTo(
          size.width * .6, size.height * .78, size.width * .62, size.height)
      ..close();
    canvas.drawPath(road, warm);
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
    this.color = HabitarColors.surfaceWarm,
    this.trailing,
  });

  final String? eyebrow;
  final String title;
  final String body;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return HabitarCard(
      color: color,
      borderColor: HabitarColors.line.withValues(alpha: .55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            HabitarPill(
                label: eyebrow!, color: Colors.white.withValues(alpha: .55)),
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
    return HabitarCard(
      color: color,
      padding: const EdgeInsets.all(HabitarSpacing.md),
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
        color: color.withValues(alpha: .25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: HabitarColors.deepGreen,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 72});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Progreso ${(value * 100).round()} por ciento',
        child: SizedBox.square(
          dimension: size,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 8,
              backgroundColor: HabitarColors.line.withValues(alpha: .55),
              color: HabitarColors.primaryGreen,
              strokeCap: StrokeCap.round,
            ),
            Text('${(value * 100).round()}%',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: HabitarColors.surfaceMist,
              child: Icon(icon, size: 32, color: HabitarColors.deepGreen),
            ),
            const SizedBox(height: HabitarSpacing.md),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: HabitarSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: HabitarColors.mutedInk)),
            if (action != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              action!,
            ],
          ]),
        ),
      );
}
