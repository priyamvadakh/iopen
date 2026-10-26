import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../screens/map_screen.dart';
import 'globe.dart';

/// "Space to street" fly-in shown when a place opens: the globe dives
/// towards the city, the real street map takes over and zooms onto the
/// area, a pin drops, then everything fades to reveal the live view.
/// Tap to skip.
class CityIntro extends StatefulWidget {
  const CityIntro({
    super.key,
    required this.city,
    required this.area,
    required this.onDone,
  });

  final City city;
  final Area area;
  final VoidCallback onDone;

  @override
  State<CityIntro> createState() => _CityIntroState();
}

class _CityIntroState extends State<CityIntro> with TickerProviderStateMixin {
  // Timeline (fractions of the whole):
  //   0.00–0.40 globe dives in
  //   0.32–0.42 globe hands over to the map
  //   0.35–0.80 map zooms from country to street level
  //   0.72–0.82 pin drops
  //   0.86–1.00 fade to the live view
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..addListener(_moveMap);
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  final _map = MapController();
  bool _mapReady = false;
  GlobeAssets? _assets = GlobeAssets.loaded;
  late ui.FragmentShader? _shader = _assets?.program.fragmentShader();

  LatLng get _target => LatLng(
    widget.area.lat ?? widget.city.lat,
    widget.area.lng ?? widget.city.lng,
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
    if (_assets == null) {
      GlobeAssets.load().then((a) {
        if (mounted) {
          setState(() {
            _assets = a;
            _shader = a.program.fragmentShader();
          });
        }
      });
    }
  }

  void _moveMap() {
    if (!_mapReady) return;
    final t = Curves.easeInOutCubic.transform(
      ((_c.value - 0.35) / 0.45).clamp(0.0, 1.0),
    );
    // Zoom feels linear to the eye when interpolated this way.
    final zoom = ui.lerpDouble(5, widget.area.lat == null ? 11 : 14.5, t)!;
    _map.move(_target, zoom);
  }

  @override
  void dispose() {
    _c.dispose();
    _pulse.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city, area = widget.area;
    final light = globeLight.value;
    // Material gives the text proper styling; this sits above the page.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.onDone,
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _pulse]),
          builder: (context, _) {
            final v = _c.value;
            final dive = Curves.easeInCubic.transform(
              (v / 0.4).clamp(0.0, 1.0),
            );
            final mapIn = ((v - 0.32) / 0.1).clamp(0.0, 1.0);
            final pin = Curves.elasticOut.transform(
              ((v - 0.72) / 0.18).clamp(0.0, 1.0),
            );
            final fadeOut = 1 - ((v - 0.86) / 0.14).clamp(0.0, 1.0);

            return Opacity(
              opacity: fadeOut,
              child: ColoredBox(
                // Matches the globe style: white with the mint globe, or
                // deep space with the dark one.
                color: light
                    ? const Color(0xFFF3FAF8)
                    : const Color(0xFF061C22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The street map, zooming onto the area.
                    Opacity(
                      opacity: mapIn,
                      child: IgnorePointer(
                        child: FlutterMap(
                          mapController: _map,
                          options: MapOptions(
                            initialCenter: _target,
                            initialZoom: 5,
                            backgroundColor: light
                                ? const Color(0xFFEAF5F2)
                                : const Color(0xFF0B3640),
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                            onMapReady: () => _mapReady = true,
                          ),
                          children: [brandTileLayer()],
                        ),
                      ),
                    ),
                    // The globe diving in, fading as the map takes over.
                    if (mapIn < 1)
                      Opacity(
                        opacity: 1 - mapIn,
                        child: CustomPaint(
                          painter: GlobePainter(
                            assets: _assets,
                            shader: _shader,
                            viewLat: 10 + (city.lat - 10) * dive,
                            viewLng: city.lng - 50 * (1 - dive),
                            zoom: 1 + 9 * dive * dive,
                            time: _pulse.value * 1.8,
                            showLabels: false,
                            showArcs: false,
                            light: light ? 1 : 0,
                          ),
                        ),
                      ),
                    // Pin dropping onto the exact spot.
                    if (pin > 0)
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, -26 - 30 * (1 - pin)),
                          child: Transform.scale(
                            scale: math.max(0.01, pin),
                            child: const _DropPin(),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.paddingOf(context).bottom + 40,
                      child: _Caption(
                        title: '${area.name}, ${city.name}',
                        subtitle: v < 0.72
                            ? 'Flying you there…'
                            : '${city.guidesOnline} Guides online nearby',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5BAEB4), AppColors.teal, AppColors.tealDark],
            ),
          ),
          child: const Icon(Icons.threesixty, color: Colors.white, size: 20),
        ),
        Container(width: 3, height: 12, color: Colors.white),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, textAlign: TextAlign.center, style: AppText.section),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              textAlign: TextAlign.center,
              style: AppText.small,
            ),
          ),
        ],
      ),
    );
  }
}
