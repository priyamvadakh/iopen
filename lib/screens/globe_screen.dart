import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';

/// Opens the whole globe full screen, carrying on from where Home's
/// three-quarter globe was facing.
void showFullGlobe(BuildContext context, {double lat = 20, double lng = 52}) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => _FullGlobe(lat: lat, lng: lng),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _FullGlobe extends StatelessWidget {
  const _FullGlobe({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    void close() => Navigator.of(context).pop();
    final light = globeLight.value;
    final ink = light ? AppColors.ink : Colors.white;
    final page = Stack(
      children: [
        Positioned.fill(
          top: padding.top + 56,
          bottom: padding.bottom + 70,
          child: Globe(
            initialLat: lat,
            initialLng: lng,
            onExpand: () {
              close();
              context.go('/map');
            },
            onCityTap: (c) {
              close();
              context.push('/city/${c.id}');
            },
          ),
        ),
        Positioned(
          top: padding.top + 8,
          left: 16,
          child: AppBackButton(onPressed: close),
        ),
        Positioned(
          top: padding.top + 16,
          left: 72,
          right: 72,
          child: Text(
            'Explore the world',
            textAlign: TextAlign.center,
            style: AppText.section.copyWith(color: ink),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: padding.bottom + 24,
          child: Text(
            '$totalGuidesOnline Guides online · tap a city to open it',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(
              color: light ? AppColors.muted : Colors.white70,
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: light
          ? DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, AppColors.aqua],
                ),
              ),
              child: page,
            )
          : SpaceBackdrop(radius: 0, child: page),
    );
  }
}
