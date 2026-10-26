import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme.dart';

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _items = [
  _NavItem('Home', Icons.home_outlined),
  _NavItem('Sessions', Icons.videocam_outlined),
  _NavItem('Map', Icons.public),
  _NavItem('Wallet', Icons.account_balance_wallet_outlined),
  _NavItem('Profile', Icons.person_outline),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom > 0 ? bottom - 8 : 12),
      child: DecoratedBox(
        decoration: ShapeDecoration(shape: const StadiumBorder()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            // Heavy frost: strong blur under a milky, slightly mint tint.
            filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    const Color(0xFFE6F5F3).withValues(alpha: 0.62),
                    const Color(0xFFD3EFF1).withValues(alpha: 0.7),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: selected ? 46 : 32,
                  height: selected ? 46 : 32,
                  decoration: selected
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF5BAEB4),
                              AppColors.teal,
                              AppColors.tealDark,
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        )
                      : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (selected)
                        Positioned(
                          top: 3,
                          left: 8,
                          right: 8,
                          height: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Icon(
                        item.icon,
                        size: selected ? 24 : 25,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF7D8A92),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              item.label,
              style: AppText.small.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.teal : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
