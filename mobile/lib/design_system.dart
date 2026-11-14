import 'package:flutter/material.dart';

/// Smart Finance design system.
///
/// One shared kit for every screen: brand palette, typography, themes and the
/// reusable building blocks (panels, stat cards, progress bars, rings,
/// category tiles, buttons). Dark-first violet/mint aesthetic mirroring the
/// browser dashboard — deep navy surfaces, gradient glows, vivid categories.

/// ---------- Palette ----------
/// Modern classic, quietly expensive: graphite ink, champagne gold accents,
/// deep emerald for money-positive moments. Private-banking restraint.
abstract final class SFColors {
  // Brand — champagne gold.
  static const brand = Color(0xFF2E9E7B);
  static const brandStrong = Color(0xFF5FC49C);
  static const brandDeep = Color(0xFF0F6F55);
  static const brandSoft = Color(0x2B2E9E7B);

  // Surfaces — warm graphite.
  static const bg = Color(0xFF0C0E12);
  static const surface = Color(0xFF151820);
  static const surfaceAlt = Color(0xFF1C2027);
  static const ink = Color(0xFFF0EDE6);
  static const muted = Color(0xFF9C978B);
  static const faint = Color(0xFF6E6A5F);
  static const line = Color(0xFF272B33);

  // Money semantics — refined, not neon.
  static const income = Color(0xFF4CC38A);
  static const incomeSoft = Color(0x294CC38A);
  static const expense = Color(0xFFE5484D);
  static const expenseSoft = Color(0x29E5484D);
  static const warn = Color(0xFFC96F3B);
  static const warnSoft = Color(0x29C96F3B);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0x29E5484D);
  static const accent = Color(0xFFAEB8C4);

  // Charts.
  static const chartIncome = Color(0xFF4CC38A);
  static const chartExpense = Color(0xFF5C6470);

  // Gradients — deep emerald hero with graphite depth, champagne actions.
  static const gradPrimary = LinearGradient(
    colors: [Color(0xFF35B584), Color(0xFF177A58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradHero = LinearGradient(
    colors: [Color(0xFF0E3D33), Color(0xFF14614F), Color(0xFF0B2C25)],
    stops: [0, 0.52, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradAccent = LinearGradient(
    colors: [Color(0xFF4CC38A), Color(0xFF2FA3A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradWarn = LinearGradient(
    colors: [Color(0xFFC96F3B), Color(0xFFA8562B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light theme counterparts — ivory porcelain with champagne accents.
  static const lightBg = Color(0xFFF7F5F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF1B1A16);
  static const lightMuted = Color(0xFF6E6A5F);
  static const lightLine = Color(0xFFE6E2D8);
  static const lightBrand = Color(0xFF177A58);
}

/// ---------- Category vocabulary ----------
/// Every category keeps a stable accent colour and icon across all screens,
/// matching the web dashboard so a category is recognisable in both clients.
class SFCategoryStyle {
  const SFCategoryStyle(this.color, this.background, this.icon);
  final Color color;
  final Color background;
  final IconData icon;
}

SFCategoryStyle sfCategoryStyle(String? category) {
  switch (category) {
    case 'Groceries':
      return const SFCategoryStyle(
        Color(0xFF7BC98F),
        Color(0x2B7BC98F),
        Icons.shopping_cart_outlined,
      );
    case 'Transport':
      return const SFCategoryStyle(
        Color(0xFF82A8D9),
        Color(0x2B82A8D9),
        Icons.directions_car_outlined,
      );
    case 'Housing':
      return const SFCategoryStyle(
        Color(0xFF6FBFB5),
        Color(0x2B6FBFB5),
        Icons.home_outlined,
      );
    case 'Entertainment':
      return const SFCategoryStyle(
        Color(0xFFA08BDC),
        Color(0x2BA08BDC),
        Icons.movie_outlined,
      );
    case 'Health':
      return const SFCategoryStyle(
        Color(0xFFD68BA8),
        Color(0x2BD68BA8),
        Icons.favorite_outline,
      );
    case 'Cafe':
      return const SFCategoryStyle(
        Color(0xFFC08552),
        Color(0x2BC08552),
        Icons.local_cafe_outlined,
      );
    case 'Clothing':
      return const SFCategoryStyle(
        Color(0xFF8B94D6),
        Color(0x2B8B94D6),
        Icons.checkroom_outlined,
      );
    case 'Salary':
    case 'Freelance':
    case 'Bonus':
    case 'Investment':
      return const SFCategoryStyle(
        Color(0xFF4CC38A),
        Color(0x2B4CC38A),
        Icons.work_outline,
      );
    case 'Gift':
      return const SFCategoryStyle(
        Color(0xFFD68BA8),
        Color(0x2BD68BA8),
        Icons.redeem_outlined,
      );
    default:
      return const SFCategoryStyle(
        Color(0xFF8A8FA0),
        Color(0x2B8A8FA0),
        Icons.sell_outlined,
      );
  }
}

/// Progress tone for a usage percentage: calm below 75%, amber as it fills,
/// red once a limit is exceeded.
Color sfTone(num percent) {
  if (percent > 100) return SFColors.danger;
  if (percent >= 75) return SFColors.warn;
  return SFColors.income;
}

/// ---------- Money formatting ----------
String sfMoney(int minor) {
  final absolute = minor.abs();
  final whole = (absolute ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final fraction = absolute % 100;
  final sign = minor < 0 ? '−' : '';
  if (fraction == 0) return '$sign₸ $whole';
  return '$sign₸ $whole.${fraction.toString().padLeft(2, '0')}';
}

String sfCompact(int minor) {
  final amount = minor / 100;
  if (amount.abs() >= 1000000) {
    return '₸${(amount / 1000000).toStringAsFixed(1)}m';
  }
  if (amount.abs() >= 1000) {
    return '₸${(amount / 1000).toStringAsFixed(amount.abs() >= 10000 ? 0 : 1)}k';
  }
  return sfMoney(minor);
}

/// ---------- Typography ----------
TextStyle sfDisplay(
  BuildContext context, {
  double size = 24,
  Color? color,
  FontWeight weight = FontWeight.w800,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color ?? SFColors.ink,
  height: 1.2,
  letterSpacing: -0.4,
);

TextStyle sfEyebrow({Color? color}) => TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.4,
  color: color ?? SFColors.brandStrong,
);

/// ---------- Theme ----------
class SFTheme {
  /// Warm graphite theme — the primary look, matching the web dashboard.
  static ThemeData dark() => _theme(
    scheme: const ColorScheme.dark(
      primary: SFColors.brand,
      secondary: Color(0xFFAEB8C4),
      surface: SFColors.surface,
      error: SFColors.danger,
      onPrimary: Colors.white,
      onSurface: SFColors.ink,
    ),
    background: SFColors.bg,
    surface: SFColors.surface,
    ink: SFColors.ink,
    muted: SFColors.muted,
    line: SFColors.line,
    navigationBackground: SFColors.surface,
    indicator: SFColors.brandSoft,
    primaryButton: SFColors.brand,
  );

  /// Light violet-tinted counterpart.
  static ThemeData light() => _theme(
    scheme: const ColorScheme.light(
      primary: SFColors.lightBrand,
      secondary: Color(0xFF0E9DB5),
      surface: SFColors.lightSurface,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSurface: SFColors.lightInk,
    ),
    background: SFColors.lightBg,
    surface: SFColors.lightSurface,
    ink: SFColors.lightInk,
    muted: SFColors.lightMuted,
    line: SFColors.lightLine,
    navigationBackground: SFColors.lightSurface,
    indicator: Color(0x2B6C5CE7),
    primaryButton: SFColors.lightBrand,
  );

  static ThemeData _theme({
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
    required Color navigationBackground,
    required Color indicator,
    required Color primaryButton,
  }) => ThemeData(
    fontFamily: 'FinanceRoboto',
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      iconTheme: IconThemeData(color: muted),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navigationBackground,
      indicatorColor: indicator,
      height: 66,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: scheme.primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      selectedColor: SFColors.brandSoft,
      checkmarkColor: scheme.primary,
      labelStyle: TextStyle(color: ink, fontSize: 12.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SFColors.surfaceAlt,
      contentTextStyle: TextStyle(color: ink, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryButton,
        foregroundColor: Colors.white,
        disabledBackgroundColor: line,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: line,
    ),
  );
}

/// ---------- Building blocks ----------

/// Hairline panel used for every content group.
class SFPanel extends StatelessWidget {
  const SFPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.gradient,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    final base = Theme.of(context).cardTheme.shape as RoundedRectangleBorder?;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? Theme.of(context).cardTheme.color)
            : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: base?.side.color ?? SFColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Eyebrow + title + subtitle block opening each screen.
class SFPageHeader extends StatelessWidget {
  const SFPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(eyebrow, style: sfEyebrow()),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: SFColors.muted)),
    ],
  );
}

/// Section title inside a panel, with optional trailing action.
class SFSectionHeader extends StatelessWidget {
  const SFSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: SFColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

/// Rounded icon tile tinted with the category accent colour.
class SFCategoryIcon extends StatelessWidget {
  const SFCategoryIcon({
    super.key,
    required this.category,
    this.size = 38,
    this.icon,
  });
  final String? category;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = sfCategoryStyle(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon ?? style.icon, size: size * 0.5, color: style.color),
    );
  }
}

/// Small rounded label pill tinted with the category accent colour.
class SFPill extends StatelessWidget {
  const SFPill({super.key, required this.label, this.color, this.background});
  final String label;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final style = sfCategoryStyle(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color ?? style.color,
        ),
      ),
    );
  }
}

/// Track-and-fill progress bar with calm/amber/red tones.
class SFProgressBar extends StatelessWidget {
  const SFProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.track,
  });
  final double value; // 0..1 already clamped
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final percent = value * 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: height, color: track ?? SFColors.line),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1).toDouble(),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: percent > 100
                    ? const LinearGradient(
                        colors: [SFColors.danger, SFColors.danger],
                      )
                    : percent >= 75
                    ? SFColors.gradWarn
                    : SFColors.gradAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular progress ring used for savings goals.
class SFRing extends StatelessWidget {
  const SFRing({super.key, required this.value, this.size = 44});
  final double value; // 0..1
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _RingPainter(
        value: value.clamp(0, 1).toDouble(),
        trackColor: SFColors.line,
        progressColor: value >= 1
            ? SFColors.income
            : Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
  });
  final double value;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset.zero & size;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(rect.deflate(stroke), 0, math2Pi, false, track);
    canvas.drawArc(
      rect.deflate(stroke),
      -math2Pi / 4,
      value * math2Pi,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}

const math2Pi = 6.283185307179586;

/// Tiny legend dot.
class SFDot extends StatelessWidget {
  const SFDot({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Empty state with a soft icon tile, title, subtitle and optional action.
class SFEmpty extends StatelessWidget {
  const SFEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: SFColors.brandSoft,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, size: 24, color: SFColors.brandStrong),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SFColors.muted, fontSize: 12.5),
        ),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    ),
  );
}

/// Wraps a child and scales it down while pressed — buttons should feel
/// responsive, not just change colour.
class SFPressable extends StatefulWidget {
  const SFPressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<SFPressable> createState() => _SFPressableState();
}

class _SFPressableState extends State<SFPressable> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap == null
        ? null
        : (_) => setState(() => pressed = true),
    onTapUp: (_) => setState(() => pressed = false),
    onTapCancel: () => setState(() => pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Primary gradient button with press feedback.
class SFButton extends StatelessWidget {
  const SFButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: SFColors.brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    if (expanded) return SizedBox(width: double.infinity, child: button);
    return SFPressable(onTap: onPressed == null ? null : () {}, child: button);
  }
}

/// Staggered fade-and-rise entrance. Wrap list sections with an increasing
/// index so a screen visibly builds up instead of appearing at once.
class SFEntrance extends StatelessWidget {
  const SFEntrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const step = Duration(milliseconds: 70);
    const base = Duration(milliseconds: 380);
    final delay = step * index;
    final total = base + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, _) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Decorative drifting glow circles for the gradient hero card.
class SFHeroGlow extends StatelessWidget {
  const SFHeroGlow({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: Stack(
      children: [
        Positioned(
          right: -40,
          top: -50,
          child: _GlowCircle(size: 180, color: Color(0x24FFFFFF)),
        ),
        Positioned(
          left: -30,
          bottom: -70,
          child: _GlowCircle(size: 150, color: Color(0x335FC49C)),
        ),
      ],
    ),
  );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}
