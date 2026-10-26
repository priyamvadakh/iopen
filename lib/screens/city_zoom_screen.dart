import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';
import '../widgets/skyline.dart';

/// Transition state between Home and the place view: the globe flies into
/// the city, then a stylised skyline and a bottom sheet appear.
class CityZoomScreen extends StatefulWidget {
  const CityZoomScreen({super.key, required this.city, this.initialKind});

  final City city;
  final InspectKind? initialKind;

  @override
  State<CityZoomScreen> createState() => _CityZoomScreenState();
}

class _CityZoomScreenState extends State<CityZoomScreen>
    with TickerProviderStateMixin {
  late final _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late InspectKind _kind = widget.initialKind ?? InspectKind.property;

  @override
  void dispose() {
    _zoom.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    return Scaffold(
      backgroundColor: AppColors.tealTint,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 200,
            child: AnimatedBuilder(
              animation: Listenable.merge([_zoom, _pulse]),
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_zoom.value);
                final globeOpacity = (1 - (t - 0.45) / 0.3).clamp(0.0, 1.0);
                final skylineIn = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (skylineIn > 0)
                      Opacity(
                        opacity: skylineIn,
                        child: Transform.scale(
                          scale: 1.25 - 0.25 * skylineIn,
                          child: CustomPaint(
                            painter: SkylinePainter(
                              cityId: city.id,
                              pulse: _pulse.value,
                            ),
                          ),
                        ),
                      ),
                    if (globeOpacity > 0)
                      Opacity(
                        opacity: globeOpacity,
                        child: CustomPaint(
                          painter: GlobePainter(
                            viewLat: 10 + (city.lat - 10) * t,
                            viewLng: city.lng - 40 * (1 - t),
                            zoom: 1 + 7 * t * t,
                            pulse: _pulse.value,
                            showLabels: false,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const TopBackButton(),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(
                  ((_zoom.value - 0.55) / 0.45).clamp(0.0, 1.0),
                );
                return FractionalTranslation(
                  translation: Offset(0, 1 - t),
                  child: child,
                );
              },
              child: _Sheet(
                city: city,
                kind: _kind,
                onKind: (k) => setState(() => _kind = k),
                onExplore: () => context.push('/city/${city.id}/${_kind.name}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.city,
    required this.kind,
    required this.onKind,
    required this.onExplore,
  });

  final City city;
  final InspectKind kind;
  final ValueChanged<InspectKind> onKind;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(city.name, style: AppText.title),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${city.guidesOnline} Guides online',
                        style: AppText.small.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('What should a Guide show you?', style: AppText.body),
          ),
          const SizedBox(height: 14),
          IntentChips(selected: kind, onTap: onKind),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlossyButton(
              onPressed: onExplore,
              child: const Text('Explore area'),
            ),
          ),
        ],
      ),
    );
  }
}
