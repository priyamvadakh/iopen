import 'package:flutter/material.dart';

import 'nav_icons.dart';
import 'teal_liquid_glass.dart';

/// Teal-green liquid-glass tab bar: [TealLiquidGlass] with a glossy bubble
/// that slides to the selected tab.
class LiquidGlassNav extends StatelessWidget {
  const LiquidGlassNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const items = navItems;

  static const teal = Color(0xFF57D1C7);
  static const aqua = Color(0xFF57D1C7);
  static const mint = Color(0xFF9FFFF1);
  static const deepTeal = Color(0xFF006D73);

  static const double height = 82;

  /// Room between the bar's edge and the bubble.
  static const double inset = 7;

  @override
  Widget build(BuildContext context) {
    return TealLiquidGlass(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - inset * 2) / items.length;
          return Stack(
            children: [
              // Glossy bubble, sliding to the selected tab.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                // A pill inside its own tab, so it never touches the next
                // tab or the glass rim; short enough to read as a pill.
                left: inset + selectedIndex * tabWidth + 2,
                top: inset + 8,
                bottom: inset + 8,
                width: tabWidth - 4,
                child: const _ActiveBubble(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: inset),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _Tab(
                          item: items[i],
                          active: i == selectedIndex,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Dark teal; the selected tab is bolder and sits in the bubble.
    final ink = active ? LiquidGlassNav.deepTeal : const Color(0xFF1F5E63);
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: const Duration(milliseconds: 250),
                child: NavIcon(item, size: 25, color: ink),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The selected tab's bubble: translucent aqua glass with a bright rim, a
/// soft cyan glow and a curved highlight across its top.
class _ActiveBubble extends StatelessWidget {
  const _ActiveBubble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.4,
          ),
        ),
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.7),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFFC6F7F2).withValues(alpha: 0.72),
            const Color(0xFF7FE6E0).withValues(alpha: 0.6),
            const Color(0xFFB5F3EE).withValues(alpha: 0.7),
          ],
        ),
        shadows: [
          BoxShadow(
            color: LiquidGlassNav.aqua.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 3, 9, 0),
        child: Align(
          alignment: Alignment.topCenter,
          // Curved highlight hugging the top of the bubble.
          child: Container(
            height: 15,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
                bottom: Radius.circular(14),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
