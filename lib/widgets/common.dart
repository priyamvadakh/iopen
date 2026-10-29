import 'package:flutter/cupertino.dart';
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

/// Frosted "crystal" surface: milky white fading to aqua, a bright rim and
/// a soft teal glow underneath.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    this.glow = 1,
    this.gloss = false,
  });

  /// Adds a bright sheen over the top half, for buttons and chips.
  final bool gloss;

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final BoxShape shape;

  /// Strength of the shadow and glow; 0 for a flat glass panel.
  final double glow;

  static List<Color> get fill => AppColors.dark
      ? [
          const Color(0xFF1E3940).withValues(alpha: 0.92),
          const Color(0xFF15282E).withValues(alpha: 0.9),
        ]
      : [
          Colors.white.withValues(alpha: 0.94),
          const Color(0xFFEAF8F8).withValues(alpha: 0.9),
        ];

  static Color get rim =>
      AppColors.dark ? Colors.white.withValues(alpha: 0.12) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fill,
        ),
        border: Border.all(color: rim, width: 1.4),
        boxShadow: glow == 0
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F1B3D).withValues(alpha: 0.06 * glow),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF3CC7D0).withValues(alpha: 0.16 * glow),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
      ),
      foregroundDecoration: gloss
          ? BoxDecoration(
              shape: shape,
              borderRadius: shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: AppColors.dark ? 0.18 : 0.75),
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0),
                  const Color(0xFF7FE0E4).withValues(alpha: 0.18),
                ],
                stops: const [0, 0.48, 0.75, 1],
              ),
            )
          : null,
      child: child,
    );
  }
}

/// Round glass button with a dark icon, e.g. back or "my location".
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 44,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Glass(
          shape: BoxShape.circle,
          gloss: true,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: iconColor ?? AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The one back button used everywhere: glass circle, dark chevron.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Defaults to going back, or Home when there is nowhere to go back to.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: Icons.chevron_left_rounded,
      label: 'Back',
      onPressed:
          onPressed ??
          () => context.canPop() ? context.pop() : context.go('/home'),
    );
  }
}

/// Glossy teal circle with a white chevron, on the card in focus.
class GlossyArrow extends StatelessWidget {
  const GlossyArrow({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3FB3BB), AppColors.teal, Color(0xFF145A63)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x99A6F4F7), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.5],
        ),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white,
        size: size * 0.66,
      ),
    );
  }
}

/// Small glass circle with a teal chevron, at the end of a card.
class ArrowChip extends StatelessWidget {
  const ArrowChip({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Glass(
      shape: BoxShape.circle,
      glow: 0.6,
      gloss: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.chevron_right_rounded,
          size: size * 0.7,
          color: AppColors.dark ? const Color(0xFF8EE3E8) : AppColors.tealDark,
        ),
      ),
    );
  }
}

/// Glass search pill. Opens [onTap] when given, otherwise a live field.
class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    super.key,
    required this.hint,
    this.onTap,
    this.onChanged,
  });

  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    final field = Row(
      children: [
        const SizedBox(width: 16),
        Icon(
          CupertinoIcons.search,
          color: dark ? AppColors.ink : const Color(0xFF1B2433),
          size: 23,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            readOnly: onTap != null,
            onTap: onTap,
            onChanged: onChanged,
            style: AppText.label.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppText.body.copyWith(
                color: dark ? null : const Color(0xFF8C97A6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
    return Glass(radius: 30, child: SizedBox(height: 50, child: field));
  }
}

/// Photo whose bottom edge rolls into a soft wave, like a glass sheet
/// laid over it.
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper({this.depth = 14});

  final double depth;

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..lineTo(0, h - depth * 0.4)
      ..cubicTo(
        w * 0.3,
        h + depth * 0.3,
        w * 0.55,
        h - depth * 1.6,
        w,
        h - depth,
      )
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => oldClipper.depth != depth;
}

/// Back button, title and subtitle, with a glass globe glowing top right.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBackButton(),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title.copyWith(fontSize: 23)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.small.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The glowing globe corner behind [PageHeader].
class GlobeCorner extends StatelessWidget {
  const GlobeCorner({super.key, this.width = 170});

  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ShaderMask(
        // Fades the photo's left and bottom edges into the page.
        shaderCallback: (rect) => const RadialGradient(
          center: Alignment.topRight,
          radius: 1.15,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.55, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Opacity(
          opacity: AppColors.dark ? 0.45 : 0.9,
          child: Image.asset(
            'assets/images/decor_globe.jpg',
            width: width,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// White-to-aqua page with faint cyan glows, the "crystal" backdrop.
class CrystalBackground extends StatelessWidget {
  const CrystalBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppColors.dark) return AquaBackground(child: child);
    // Plain white, like the app.
    return ColoredBox(color: Colors.white, child: child);
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
            Expanded(
              child: Text(title, style: AppText.title.copyWith(fontSize: 18)),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dark
                      ? const Color(0xFF8EE3E8)
                      : AppColors.tealDark,
                  padding: const EdgeInsets.only(left: 8),
                  textStyle: AppText.label.copyWith(fontSize: 13),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See all'),
                    SizedBox(width: 1),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          // Always one line: long subtitles shrink to fit.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle!,
              maxLines: 1,
              style: AppText.small.copyWith(fontSize: 12),
            ),
          ),
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
            : AppColors.surface,
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

/// Page background used across the app: white, or a soft aqua fade in the
/// dark theme.
class AquaBackground extends StatelessWidget {
  const AquaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Plain white in the light theme, like the app.
    if (!AppColors.dark) return ColoredBox(color: Colors.white, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.background, AppColors.aqua],
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
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xCCA6F4F7), width: 1.5),
        ),
        shadows: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF3CC7D0).withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF0B4F57).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
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
                      Color(0xFF2E9AA2),
                      Color(0xFF136B74),
                      Color(0xFF0A4D55),
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

/// The primary button's glossy teal pill on its own, for selected states
/// such as the filter dial's lens.
class GlossyPill extends StatelessWidget {
  const GlossyPill({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xCCA6F4F7), width: 1.2),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FAEB4), Color(0xFF2E6E77), Color(0xFF1C4F57)],
          stops: [0, 0.55, 1],
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF3CC7D0).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF0B4F57).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const CustomPaint(painter: _GlossPainter()),
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

/// Glass column of zoom in / zoom out (and optional expand) buttons.
class ZoomControls extends StatelessWidget {
  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onExpand,
    this.expanded = false,
  });

  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onExpand;

  /// Shows a "close full screen" icon instead of "expand".
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String label, VoidCallback? onTap) =>
        Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 22,
                color: onTap == null
                    ? AppColors.muted.withValues(alpha: 0.4)
                    : AppColors.ink,
              ),
            ),
          ),
        );

    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.surface.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onExpand != null) ...[
              button(
                expanded ? Icons.close_fullscreen : Icons.open_in_full,
                expanded ? 'Exit full screen' : 'Full screen',
                onExpand,
              ),
              Container(width: 22, height: 1, color: AppColors.border),
            ],
            button(Icons.add, 'Zoom in', onZoomIn),
            Container(width: 22, height: 1, color: AppColors.border),
            button(Icons.remove, 'Zoom out', onZoomOut),
          ],
        ),
      ),
    );
  }
}
