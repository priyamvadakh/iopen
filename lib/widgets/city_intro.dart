import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/content.dart';
import 'globe.dart';
import 'skyline.dart';

/// Short fly-in shown when a city opens: the globe zooms into the city, the
/// stylised skyline appears, then everything fades to reveal the live view.
/// Tap to skip.
class CityIntro extends StatefulWidget {
  const CityIntro({super.key, required this.city, required this.onDone});

  final City city;
  final VoidCallback onDone;

  @override
  State<CityIntro> createState() => _CityIntroState();
}

class _CityIntroState extends State<CityIntro> with TickerProviderStateMixin {
  late final _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward().whenComplete(widget.onDone);
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _zoom.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    return GestureDetector(
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: Listenable.merge([_zoom, _pulse]),
        builder: (context, _) {
          // 0–0.55 globe flight, 0.35–0.8 skyline, 0.8–1 fade out.
          final v = _zoom.value;
          final flight = Curves.easeInOutCubic.transform(
            (v / 0.55).clamp(0.0, 1.0),
          );
          final globeOpacity = (1 - (v - 0.35) / 0.2).clamp(0.0, 1.0);
          final skylineIn = ((v - 0.35) / 0.2).clamp(0.0, 1.0);
          final fadeOut = 1 - ((v - 0.8) / 0.2).clamp(0.0, 1.0);

          return Opacity(
            opacity: fadeOut,
            child: ColoredBox(
              color: AppColors.tealTint,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (skylineIn > 0)
                    Opacity(
                      opacity: skylineIn,
                      child: Transform.scale(
                        scale:
                            1.2 -
                            0.2 * skylineIn +
                            0.15 * (v - 0.35).clamp(0, 1),
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
                          viewLat: 10 + (city.lat - 10) * flight,
                          viewLng: city.lng - 40 * (1 - flight),
                          zoom: 1 + 7 * flight * flight,
                          pulse: _pulse.value,
                          showLabels: false,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.paddingOf(context).bottom + 40,
                    child: Column(
                      children: [
                        Text(city.name, style: AppText.display),
                        const SizedBox(height: 4),
                        Text(
                          'Connecting you to ${city.area}…',
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
