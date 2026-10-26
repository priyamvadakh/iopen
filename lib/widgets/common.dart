import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';

/// Bundled photo with a calm placeholder if the file is missing.
class Photo extends StatelessWidget {
  const Photo(
    this.name, {
    super.key,
    this.icon = Icons.image_outlined,
    this.alignment = Alignment.center,
  });

  final String name;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$name.jpg',
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFCFE6E7), Color(0xFF9CCBCD)],
          ),
        ),
        child: Center(child: Icon(icon, size: 32, color: AppColors.tealDark)),
      ),
    );
  }
}

/// Dark gradient under text placed on photos.
class Scrim extends StatelessWidget {
  const Scrim({super.key, this.top = false, this.strength = 0.72});

  final bool top;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.bottomCenter : Alignment.topCenter,
            end: top ? Alignment.topCenter : Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.ink.withValues(alpha: strength),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one back button used everywhere: 40px white circle, dark arrow.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: AppColors.ink.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Positions [AppBackButton] just below the status bar.
class TopBackButton extends StatelessWidget {
  const TopBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      child: const AppBackButton(),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.onSeeAll});

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppText.section)),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('See all'),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppText.small),
        ],
      ],
    );
  }
}

/// Horizontal intent chips: Place, Car, Property, Hotel.
class IntentChips extends StatelessWidget {
  const IntentChips({
    super.key,
    required this.onTap,
    this.selected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final ValueChanged<InspectKind> onTap;
  final InspectKind? selected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: InspectKind.values.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final kind = InspectKind.values[i];
          return ChoicePill(
            label: kind.label,
            icon: kind.icon,
            selected: kind == selected,
            onTap: () => onTap(kind),
          );
        },
      ),
    );
  }
}

class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Shows a check mark when selected, for multi-select lists.
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final fg = selected && !showCheck ? Colors.white : AppColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? (showCheck ? AppColors.tealTint : AppColors.teal)
            : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.border,
            width: selected && showCheck ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected && showCheck ? Icons.check_circle : icon,
                  size: 18,
                  color: selected && showCheck
                      ? AppColors.teal
                      : (selected ? Colors.white : AppColors.teal),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.label.copyWith(fontSize: 14, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideAvatar extends StatelessWidget {
  const GuideAvatar(
    this.guide, {
    super.key,
    this.size = 44,
    this.online = false,
  });

  final Guide guide;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: guide.color,
            child: Text(
              guide.initials,
              style: AppText.label.copyWith(fontSize: size * 0.34),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Rating extends StatelessWidget {
  const Rating(this.value, {super.key, this.reviews});

  final double value;
  final int? reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
        const SizedBox(width: 2),
        Text(
          value.toStringAsFixed(1),
          style: AppText.small.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviews != null) Text(' ($reviews)', style: AppText.small),
      ],
    );
  }
}

void showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what is not built yet.')));
}

/// Soft white-to-aqua page background used across the app.
class AquaBackground extends StatelessWidget {
  const AquaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.background, AppColors.aqua],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}

/// Primary call to action: glossy teal pill with a soft glow.
class GlossyButton extends StatelessWidget {
  const GlossyButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: enabled
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                const BoxShadow(
                  color: Color(0x66BFEAEC),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: enabled ? null : AppColors.border,
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5BAEB4),
                      AppColors.teal,
                      AppColors.tealDark,
                    ],
                    stops: [0, 0.55, 1],
                  )
                : null,
          ),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 58,
              width: double.infinity,
              child: Stack(
                children: [
                  if (enabled)
                    const Positioned.fill(
                      child: CustomPaint(painter: _GlossPainter()),
                    ),
                  Center(
                    child: DefaultTextStyle(
                      style: AppText.label.copyWith(
                        fontSize: 17,
                        color: enabled ? Colors.white : AppColors.muted,
                        shadows: enabled
                            ? const [
                                Shadow(
                                  color: Color(0x40000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top sheen plus curved highlights at both rounded ends.
class _GlossPainter extends CustomPainter {
  const _GlossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.12),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.7, w, h * 0.3)),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.75);
    final d = h - 10;
    canvas.drawArc(Rect.fromLTWH(7, 5, d, d), 3.4, 1.25, false, arc);
    canvas.drawArc(Rect.fromLTWH(w - d - 7, 5, d, d), 4.9, 0.9, false, arc);
  }

  @override
  bool shouldRepaint(_GlossPainter oldDelegate) => false;
}
