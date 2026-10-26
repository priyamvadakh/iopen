import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../data/land_dots.dart';

/// Orthographic projection of a lat/lng (degrees) onto a sphere of [radius]
/// centred at [center], looking at [viewLat]/[viewLng].
/// Returns null for points on the far side.
({Offset offset, double depth})? projectPoint({
  required double lat,
  required double lng,
  required double viewLat,
  required double viewLng,
  required Offset center,
  required double radius,
}) {
  const d = math.pi / 180;
  final phi = lat * d, lambda = (lng - viewLng) * d, phi0 = viewLat * d;
  final cosc =
      math.sin(phi0) * math.sin(phi) +
      math.cos(phi0) * math.cos(phi) * math.cos(lambda);
  if (cosc <= 0) return null;
  final x = math.cos(phi) * math.sin(lambda);
  final y =
      math.cos(phi0) * math.sin(phi) -
      math.sin(phi0) * math.cos(phi) * math.cos(lambda);
  return (offset: center + Offset(x, -y) * radius, depth: cosc);
}

/// Interactive dotted globe with pulsing pins where Guides are online.
/// Drag to rotate, tap a pin to open the city.
class Globe extends StatefulWidget {
  const Globe({super.key, this.onCityTap, this.initialLng = 48});

  final ValueChanged<City>? onCityTap;
  final double initialLng;

  @override
  State<Globe> createState() => _GlobeState();
}

class _GlobeState extends State<Globe> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late double _lng = widget.initialLng;
  double _lat = 18;
  double _pulse = 0;
  Duration _last = Duration.zero;
  Duration _resumeAt = Duration.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    setState(() {
      _pulse = (elapsed.inMilliseconds % 1800) / 1800;
      if (!_dragging && elapsed > _resumeAt) _lng += dt * 6;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  City? _hitTest(Offset pos, Size size) {
    final geometry = GlobePainter.geometry(size);
    City? best;
    var bestDist = 26.0;
    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: _lat,
        viewLng: _lng,
        center: geometry.center,
        radius: geometry.radius,
      );
      if (p == null) continue;
      final dist = (p.offset - pos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = city;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          onPanStart: (_) => _dragging = true,
          onPanUpdate: (d) => setState(() {
            _lng -= d.delta.dx * 0.35;
            _lat = (_lat + d.delta.dy * 0.3).clamp(-50.0, 60.0);
          }),
          onPanEnd: (_) {
            _dragging = false;
            _resumeAt = _last + const Duration(seconds: 3);
          },
          onTapUp: (d) {
            final city = _hitTest(d.localPosition, size);
            if (city != null) widget.onCityTap?.call(city);
          },
          child: CustomPaint(
            size: size,
            painter: GlobePainter(viewLat: _lat, viewLng: _lng, pulse: _pulse),
          ),
        );
      },
    );
  }
}

class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.viewLat,
    required this.viewLng,
    required this.pulse,
    this.zoom = 1,
    this.showLabels = true,
  });

  final double viewLat;
  final double viewLng;

  /// 0..1, drives the pin pulse.
  final double pulse;

  /// Scales the sphere radius; used by the city zoom transition.
  final double zoom;
  final bool showLabels;

  // Nearby Gulf pins overlap, so only some get a name.
  static const _labelled = {'dubai', 'beirut', 'tokyo', 'bangkok'};

  static ({Offset center, double radius}) geometry(Size size) => (
    center: size.center(Offset.zero),
    radius: math.min(size.width, size.height) * 0.42,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry(size);
    final center = g.center;
    final r = g.radius * zoom;

    // Soft halo.
    canvas.drawCircle(
      center,
      r * 1.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.16),
            AppColors.teal.withValues(alpha: 0),
          ],
          stops: const [0.82, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.12)),
    );

    // Sphere, lit from the top left.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: const [Colors.white, Color(0xFFE3F2F2), Color(0xFFBFDEDF)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Land as dots, fainter towards the edge for depth.
    final buckets = List.generate(4, (_) => <Offset>[]);
    for (var i = 0; i < landDots.length; i += 2) {
      final p = projectPoint(
        lat: landDots[i],
        lng: landDots[i + 1],
        viewLat: viewLat,
        viewLng: viewLng,
        center: center,
        radius: r,
      );
      if (p == null) continue;
      buckets[math.min(3, (p.depth * 4).floor())].add(p.offset);
    }
    final dotSize = math.max(2.0, r / 70);
    for (var b = 0; b < 4; b++) {
      canvas.drawPoints(
        PointMode.points,
        buckets[b],
        Paint()
          ..color = AppColors.teal.withValues(alpha: 0.18 + b * 0.14)
          ..strokeWidth = dotSize
          ..strokeCap = StrokeCap.round,
      );
    }

    // Guide pins.
    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: viewLat,
        viewLng: viewLng,
        center: center,
        radius: r,
      );
      if (p == null || p.depth < 0.12) continue;
      final o = p.offset;
      final fade = math.min(1.0, p.depth * 2.5);
      canvas.drawCircle(
        o,
        6 + 14 * pulse,
        Paint()
          ..color = AppColors.teal.withValues(alpha: 0.35 * (1 - pulse) * fade),
      );
      canvas.drawCircle(
        o,
        9,
        Paint()
          ..color = AppColors.teal.withValues(alpha: 0.35 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        o,
        5.5,
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
      canvas.drawCircle(
        o,
        3.8,
        Paint()..color = AppColors.teal.withValues(alpha: fade),
      );
      if (showLabels && _labelled.contains(city.id) && p.depth > 0.45) {
        final tp = TextPainter(
          text: TextSpan(
            text: city.name,
            style: AppText.small.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withValues(alpha: fade),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, o + Offset(8, -tp.height - 2));
      }
    }
  }

  @override
  bool shouldRepaint(GlobePainter old) =>
      old.viewLat != viewLat ||
      old.viewLng != viewLng ||
      old.pulse != pulse ||
      old.zoom != zoom;
}
