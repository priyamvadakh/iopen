import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';

enum _Glyph { house, webcam, wallet }

class _NavItem {
  const _NavItem(this.label, {this.icon, this.glyph});

  final String label;
  final IconData? icon;

  /// Hand-drawn icon, for shapes the icon fonts don't have.
  final _Glyph? glyph;
}

// Same tabs, icons and colours as the app on TestFlight.
const _items = [
  _NavItem('Home', glyph: _Glyph.house),
  _NavItem('Sessions', glyph: _Glyph.webcam),
  _NavItem('Map', icon: Icons.public),
  _NavItem('Wallet', glyph: _Glyph.wallet),
  _NavItem('Profile', icon: CupertinoIcons.person),
];

/// Floating frosted-glass tab bar with a glossy teal bubble on the active tab.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = AppColors.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom > 0 ? bottom - 8 : 12),
      child: DecoratedBox(
        // Outside the clip, so the glass glows softly aqua on the page.
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: [
            BoxShadow(
              color: const Color(0xFF3CC7D0)
                  .withValues(alpha: dark ? 0.12 : 0.3),
              blurRadius: 28,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: const Color(0xFF10202A).withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            // Clear glass: the page shows through, blurred and brightened.
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          const Color(0xFF1C3439).withValues(alpha: 0.66),
                          const Color(0xFF15282E).withValues(alpha: 0.58),
                          const Color(0xFF1A3A40).withValues(alpha: 0.7),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.62),
                          const Color(0xFFEAF8F8).withValues(alpha: 0.42),
                          const Color(0xFFCFF0F1).withValues(alpha: 0.55),
                        ],
                  stops: const [0, 0.55, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.22 : 1),
                  width: 1.6,
                ),
              ),
              // Glossy glass: a bright sheen over the top half, and an aqua
              // bounce light glowing up from the bottom edge.
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: dark ? 0.16 : 0.85),
                    Colors.white.withValues(alpha: dark ? 0.04 : 0.2),
                    Colors.white.withValues(alpha: 0),
                    const Color(0xFF8FEAEE).withValues(alpha: dark ? 0.1 : 0.3),
                  ],
                  stops: const [0, 0.38, 0.62, 1],
                ),
              ),
              child: Stack(
                children: [
                  // A second, finer rim just inside the first, like the
                  // thick edge of a glass pane.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color:
                                (dark ? Colors.white : const Color(0xFF8FEAEE))
                                    .withValues(alpha: dark ? 0.08 : 0.55),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: _items[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Nudged up a touch: the label has no descenders, so centring the
        // box alone leaves the bottom gap looking thinner than the top.
        child: Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon row and label make one tight block, centred in the bar
              // so the margins above and below match.
              SizedBox(
                height: 42,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: selected ? 42 : 28,
                    height: selected ? 42 : 28,
                    decoration: selected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(0, -0.5),
                              radius: 0.9,
                              colors: [Color(0xFF3B9AA3), Color(0xFF155760)],
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3CC7D0)
                                    .withValues(alpha: 0.45),
                                blurRadius: 14,
                              ),
                              BoxShadow(
                                color: const Color(0xFF155760)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          )
                        : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Specular highlight across the top of the bubble.
                        if (selected)
                          Positioned(
                            top: 2,
                            left: 7,
                            right: 7,
                            height: 17,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                  bottom: Radius.circular(12),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        _icon(
                          item,
                          size: selected ? 21 : 22,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6F8389),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppText.small.copyWith(
                  fontSize: 11,
                  height: 1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.tealDark
                      : const Color(0xFF6F8389),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _icon(_NavItem item, {required double size, required Color color}) =>
    item.glyph == null
    ? Icon(item.icon, size: size, color: color)
    : CustomPaint(
        size: Size.square(size),
        painter: _GlyphPainter(item.glyph!, color),
      );

/// Rounded outline icons matching the app: house, webcam and wallet.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case _Glyph.house:
        // Soft-cornered house with a short line for the door step.
        final r = s * 0.1;
        final path = Path()
          ..moveTo(s * 0.14, s * 0.46)
          ..lineTo(s * 0.5, s * 0.14)
          ..lineTo(s * 0.86, s * 0.46)
          ..lineTo(s * 0.86, s * 0.86 - r)
          ..quadraticBezierTo(s * 0.86, s * 0.86, s * 0.86 - r, s * 0.86)
          ..lineTo(s * 0.14 + r, s * 0.86)
          ..quadraticBezierTo(s * 0.14, s * 0.86, s * 0.14, s * 0.86 - r)
          ..close();
        canvas.drawPath(path, line);
        canvas.drawLine(
          Offset(s * 0.4, s * 0.7),
          Offset(s * 0.6, s * 0.7),
          line,
        );
      case _Glyph.webcam:
        final head = Offset(s * 0.5, s * 0.42);
        canvas.drawCircle(head, s * 0.3, line);
        canvas.drawCircle(head, s * 0.11, line);
        canvas.drawLine(
          Offset(s * 0.5, s * 0.72),
          Offset(s * 0.5, s * 0.82),
          line,
        );
        canvas.drawLine(
          Offset(s * 0.28, s * 0.86),
          Offset(s * 0.72, s * 0.86),
          line,
        );
      case _Glyph.wallet:
        // Rounded wallet with a curved flap over the top and a clasp line.
        final body = RRect.fromLTRBR(
          s * 0.12,
          s * 0.3,
          s * 0.88,
          s * 0.84,
          Radius.circular(s * 0.14),
        );
        canvas.drawRRect(body, line);
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.24, s * 0.3)
            ..quadraticBezierTo(s * 0.5, s * 0.06, s * 0.76, s * 0.3),
          line,
        );
        canvas.drawLine(
          Offset(s * 0.4, s * 0.5),
          Offset(s * 0.6, s * 0.5),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
