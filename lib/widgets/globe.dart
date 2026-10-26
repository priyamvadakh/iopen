import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/onboarding_state.dart';
import '../app/theme.dart';
import '../data/content.dart';
import 'common.dart';
import 'gestures.dart';

/// Orthographic projection of a lat/lng (degrees) onto a sphere of [radius]
/// centred at [center], looking at [viewLat]/[viewLng]. [altitude] lifts the
/// point above the surface (as a fraction of the radius).
/// Returns null for points hidden behind the globe.
({Offset offset, double depth})? projectPoint({
  required double lat,
  required double lng,
  required double viewLat,
  required double viewLng,
  required Offset center,
  required double radius,
  double altitude = 0,
}) {
  const d = math.pi / 180;
  final phi = lat * d, lambda = (lng - viewLng) * d, phi0 = viewLat * d;
  final cosc =
      math.sin(phi0) * math.sin(phi) +
      math.cos(phi0) * math.cos(phi) * math.cos(lambda);
  final x = math.cos(phi) * math.sin(lambda);
  final y =
      math.cos(phi0) * math.sin(phi) -
      math.sin(phi0) * math.cos(phi) * math.cos(lambda);
  final r = radius * (1 + altitude);
  // A lifted point stays visible a little past the horizon.
  final visible = altitude == 0
      ? cosc > 0
      : cosc > 0 || (x * x + y * y) * (1 + altitude) * (1 + altitude) > 1;
  if (!visible) return null;
  return (offset: center + Offset(x, -y) * r, depth: cosc);
}

/// Earth textures and shader, loaded once and shared.
class GlobeAssets {
  GlobeAssets._(this.program, this.day, this.night);

  final ui.FragmentProgram program;
  final ui.Image day;
  final ui.Image night;

  static Future<GlobeAssets>? _loading;
  static GlobeAssets? loaded;

  static Future<GlobeAssets> load() => _loading ??= () async {
    Future<ui.Image> image(String name) async {
      final data = await rootBundle.load('assets/textures/$name.jpg');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    }

    final result = GlobeAssets._(
      await ui.FragmentProgram.fromAsset('shaders/globe.frag'),
      await image('earth_day'),
      await image('earth_night'),
    );
    return loaded = result;
  }();
}

/// Deep teal "space" background with a few fixed stars.
class SpaceBackdrop extends StatelessWidget {
  const SpaceBackdrop({super.key, required this.child, this.radius = 24});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF14535C), Color(0xFF0A2E36), Color(0xFF061C22)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: CustomPaint(painter: _StarsPainter(), child: child),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      paint.color = Colors.white.withValues(
        alpha: 0.15 + rnd.nextDouble() * 0.45,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.1 + 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}

/// Globe style for the whole app: false = glass on dark space, true = white
/// mint glass on white (the default). Home has a switch to compare them.
final globeLight = ValueNotifier<bool>(true);

/// Interactive Earth with glowing pins where Guides are online and arcs
/// showing live sessions. Drag to rotate, tap a pin to open the city.
class Globe extends StatefulWidget {
  const Globe({
    super.key,
    this.onCityTap,
    this.onExpand,
    this.onZoomIn,
    this.spin,
    this.initialLat = 20,
    this.initialLng = 52,
    this.showZoomControls = true,
    this.insideScrollView = false,
  });

  final ValueChanged<City>? onCityTap;

  /// When set, zooming in (pinch, wheel or +) hands over to a bigger view
  /// instead of zooming here; it gets the current view's centre.
  final void Function(double lat, double lng)? onZoomIn;
  final double initialLat;

  /// Turns the globe on its own while true (always, when not given).
  final ValueListenable<bool>? spin;

  /// Shows a full-screen button with the zoom controls.
  final VoidCallback? onExpand;
  final double initialLng;
  final bool showZoomControls;

  /// When the globe sits in a scrolling page, one-finger vertical drags
  /// scroll the page instead of tilting the globe.
  final bool insideScrollView;

  @override
  State<Globe> createState() => _GlobeState();
}

class _GlobeState extends State<Globe> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late double _lng = widget.initialLng;
  late double _lat = widget.initialLat;
  Duration _handedOffAt = const Duration(days: -1);
  double _time = 0;
  Duration _last = Duration.zero;
  Duration _resumeAt = Duration.zero;
  bool _dragging = false;
  bool _pinching = false;
  double _zoom = 1;
  double _targetZoom = 1;
  double _zoomAtScaleStart = 1;
  GlobeAssets? _assets = GlobeAssets.loaded;
  late ui.FragmentShader? _shader = _assets?.program.fragmentShader();

  static const _minZoom = 0.8;
  static const _maxZoom = 3.5;

  void _zoomBy(double factor) {
    if (factor > 1 && _handOff()) return;
    setState(() {
      _targetZoom = (_targetZoom * factor).clamp(_minZoom, _maxZoom);
      _resumeAt = _last + const Duration(milliseconds: 1200);
    });
  }

  /// Passes a zoom-in to [Globe.onZoomIn], at most once a second.
  bool _handOff() {
    final onZoomIn = widget.onZoomIn;
    if (onZoomIn == null) return false;
    if (_last - _handedOffAt > const Duration(seconds: 1)) {
      _handedOffAt = _last;
      onZoomIn(_lat, _lng);
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
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

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    setState(() {
      _time = elapsed.inMicroseconds / 1e6;
      _zoom += (_targetZoom - _zoom) * math.min(1, dt * 10);
      final touring =
          !_dragging &&
          elapsed > _resumeAt &&
          !onboardingActive.value &&
          (widget.spin?.value ?? true);
      if (touring) {
        _glideTour(elapsed, math.min(dt, 0.05));
      } else {
        _vLat = _vLng = 0;
      }
    });
  }

  // The tour glides from one live city to the next, west to east, easing
  // in and out with a soft spring and resting a moment on each.
  static final _tour = [...cities]..sort((a, b) => a.lng.compareTo(b.lng));
  int _tourIndex = -1;
  Duration _tourNextAt = Duration.zero;
  double _vLat = 0, _vLng = 0;

  void _glideTour(Duration elapsed, double dt) {
    if (elapsed >= _tourNextAt) {
      _tourIndex = (_tourIndex + 1) % _tour.length;
      _tourNextAt = elapsed + const Duration(milliseconds: 4200);
    }
    final city = _tour[_tourIndex];
    // Look a little from the north, so the city sits just below centre.
    final targetLat = (city.lat * 0.75 + 8).clamp(-60.0, 70.0);
    final dLng = ((city.lng - _lng + 540) % 360) - 180;
    final dLat = targetLat - _lat;
    // Critically damped spring: smooth start, gentle settle, no overshoot.
    const k = 2.2;
    final damping = 2 * math.sqrt(k);
    _vLng += (k * dLng - damping * _vLng) * dt;
    _vLat += (k * dLat - damping * _vLat) * dt;
    _lng += _vLng * dt;
    _lat += _vLat * dt;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  // Finger-sized targets: a city's name pill is tappable with generous
  // padding, and the dot answers anywhere within a 72px circle around it.
  City? _hitTest(Offset pos, Size size) {
    final g = GlobePainter.geometry(size);
    City? best;
    var bestDist = 36.0;
    for (final l in GlobePainter.placeLabels(
      viewLat: _lat,
      viewLng: _lng,
      center: g.center,
      radius: g.radius * _zoom,
    )) {
      if (l.box.inflate(10).contains(pos)) return l.city;
    }
    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: _lat,
        viewLng: _lng,
        center: g.center,
        radius: g.radius * _zoom,
      );
      if (p == null || p.depth < 0.1) continue;
      final dist = (p.offset - pos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = city;
      }
    }
    return best;
  }

  // Zooms toward the fingers by turning the globe a little.
  void _pinch(double scale, Offset focalDelta, Offset focal, Size size) {
    final g = GlobePainter.geometry(size);
    final newZoom = (_zoomAtScaleStart * scale).clamp(_minZoom, _maxZoom);
    final k = newZoom / _zoom;
    final f = (focal - g.center) / (g.radius * newZoom);
    setState(() {
      _lng += f.dx * (1 - 1 / k) * 57.3 - focalDelta.dx * 0.35 / newZoom;
      _lat = (_lat - f.dy * (1 - 1 / k) * 57.3 + focalDelta.dy * 0.3 / newZoom)
          .clamp(-60.0, 70.0);
      _zoom = _targetZoom = newZoom;
    });
  }

  void _drag(Offset delta) {
    if (_pinching) return;
    setState(() {
      _lng -= delta.dx * 0.35 / _zoom;
      if (!widget.insideScrollView) {
        _lat = (_lat + delta.dy * 0.3 / _zoom).clamp(-60.0, 70.0);
      }
    });
  }

  void _settle() {
    _dragging = false;
    _resumeAt = _last + const Duration(milliseconds: 1200);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final gestures = <Type, GestureRecognizerFactory>{
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTapUp = (d) {
                  final city = _hitTest(d.localPosition, size);
                  if (city != null) widget.onCityTap?.call(city);
                },
              ),
          PinchGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PinchGestureRecognizer>(
                PinchGestureRecognizer.new,
                (r) {
                  r.onStart = () {
                    _dragging = _pinching = true;
                    _zoomAtScaleStart = _zoom;
                  };
                  r.onUpdate = (scale, delta, focal) {
                    if (scale > 1.12 && _handOff()) return;
                    _pinch(scale, delta, focal, size);
                  };
                  r.onEnd = () {
                    _pinching = false;
                    _settle();
                  };
                },
              ),
          // On a scrolling page one finger only spins sideways, so up/down
          // still scrolls the page.
          if (widget.insideScrollView)
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(HorizontalDragGestureRecognizer.new, (r) {
                  r.onStart = (_) => _dragging = true;
                  r.onUpdate = (d) => _drag(d.delta);
                  r.onEnd = (_) => _settle();
                })
          else
            PanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  PanGestureRecognizer.new,
                  (r) {
                    r.onStart = (_) => _dragging = true;
                    r.onUpdate = (d) => _drag(d.delta);
                    r.onEnd = (_) => _settle();
                  },
                ),
        };

        return Listener(
          onPointerSignal: (event) {
            // Mouse wheel / trackpad zoom; claim it so the page doesn't scroll.
            if (event is PointerScrollEvent) {
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (e) => _zoomBy(
                  math.exp(-(e as PointerScrollEvent).scrollDelta.dy * 0.0015),
                ),
              );
            }
          },
          child: RawGestureDetector(
            gestures: gestures,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: GlobePainter(
                    assets: _assets,
                    shader: _shader,
                    viewLat: _lat,
                    viewLng: _lng,
                    time: _time,
                    zoom: _zoom,
                    light: globeLight.value ? 1 : 0,
                  ),
                ),
                if (widget.showZoomControls)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: ZoomControls(
                        onZoomIn:
                            widget.onZoomIn != null ||
                                _targetZoom < _maxZoom - 0.01
                            ? () => _zoomBy(1.4)
                            : null,
                        onZoomOut: _targetZoom > _minZoom + 0.01
                            ? () => _zoomBy(1 / 1.4)
                            : null,
                        onExpand: widget.onExpand,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Arcs drawn between cities to suggest sessions happening right now.
const _arcs = [
  ('dubai', 'tokyo'),
  ('dubai', 'beirut'),
  ('riyadh', 'singapore'),
  ('doha', 'bangkok'),
  ('amman', 'dubai'),
];

class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.viewLat,
    required this.viewLng,
    required this.time,
    this.assets,
    this.shader,
    this.zoom = 1,
    this.showLabels = true,
    this.showArcs = true,
    this.flat = 0,
    this.light = 0,
    this.center,
    this.radius,
  });

  final GlobeAssets? assets;

  /// Kept alive by the owning widget: on the web the canvas is drawn after
  /// paint() returns, so the shader must not be disposed here.
  final ui.FragmentShader? shader;
  final double viewLat;
  final double viewLng;

  /// Seconds; drives pin pulses and arc motion.
  final double time;

  /// Scales the sphere radius; used by the city fly-in.
  final double zoom;
  final bool showLabels;
  final bool showArcs;

  /// 1 unrolls the globe into a full-screen flat map, 0 is the globe. Pins
  /// and arcs only show on the finished globe.
  final double flat;

  /// 0 = glass on dark, 1 = white porcelain (see [globeLight]).
  final double light;

  /// Overrides where the sphere sits on the canvas (and, while [flat] > 0,
  /// the map scale in pixels per radian).
  final Offset? center;
  final double? radius;

  static ({Offset center, double radius}) geometry(Size size) => (
    center: size.center(Offset.zero),
    radius: math.min(size.width, size.height) * 0.4,
  );

  static const _pinColor = Color(0xFF7FE6EE);

  /// Light style's accent: a soft green-teal.
  static const _mint = Color(0xFF3F8478);

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry(size);
    final center = this.center ?? g.center;
    final r = (radius ?? g.radius) * zoom;

    _paintEarth(canvas, size, center, r);
    if (flat > 0) return;
    if (showArcs) _paintArcs(canvas, center, r);
    _paintPins(canvas, center, r);
  }

  void _paintEarth(Canvas canvas, Size size, Offset center, double r) {
    final a = assets, shader = this.shader;
    if ((a == null || shader == null) && flat > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF0B3640),
      );
      return;
    }
    if (a == null || shader == null) {
      // Plain lit sphere while textures load.
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.4),
            colors: [Color(0xFF3F8FA0), Color(0xFF0B3640)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      return;
    }
    var i = 0;
    for (final v in [
      size.width,
      size.height,
      center.dx,
      center.dy,
      r,
      viewLat * math.pi / 180,
      viewLng * math.pi / 180,
      // Blend towards satellite colours as the user zooms in.
      ((zoom - 1.4) / 1.8).clamp(0.0, 1.0),
      flat,
      light,
    ]) {
      shader.setFloat(i++, v);
    }
    shader
      ..setImageSampler(0, a.day)
      ..setImageSampler(1, a.night);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintArcs(Canvas canvas, Offset center, double r) {
    for (var k = 0; k < _arcs.length; k++) {
      final from = cityById(_arcs[k].$1)!, to = cityById(_arcs[k].$2)!;
      final points = <Offset?>[];
      final a = _toVector(from.lat, from.lng), b = _toVector(to.lat, to.lng);
      final angle = math.acos(_dot(a, b).clamp(-1.0, 1.0));
      const steps = 40;
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final v = _slerp(a, b, angle, t);
        final lat = math.asin(v.$2) * 180 / math.pi;
        final lng = math.atan2(v.$1, v.$3) * 180 / math.pi;
        final p = projectPoint(
          lat: lat,
          lng: lng,
          viewLat: viewLat,
          viewLng: viewLng,
          center: center,
          radius: r,
          altitude: math.sin(t * math.pi) * angle * 0.22,
        );
        points.add(p?.offset);
      }

      if (light > 0.5) {
        // Light style: a quiet dashed route.
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = _mint.withValues(alpha: 0.85);
        for (var s = 0; s < points.length - 1; s += 2) {
          final p0 = points[s], p1 = points[s + 1];
          if (p0 != null && p1 != null) canvas.drawLine(p0, p1, dash);
        }
        continue;
      }

      // Faint full path, then a bright comet travelling along it.
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = _pinColor.withValues(alpha: 0.25);
      _drawPolyline(canvas, points, 0, 1, base);

      final head = ((time * 0.35 + k * 0.23) % 1.4);
      final comet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = _pinColor.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      _drawPolyline(canvas, points, head - 0.25, head, comet);
    }
  }

  void _drawPolyline(
    Canvas canvas,
    List<Offset?> points,
    double from,
    double to,
    Paint paint,
  ) {
    final n = points.length - 1;
    final start = (from.clamp(0.0, 1.0) * n).floor();
    final end = (to.clamp(0.0, 1.0) * n).ceil();
    Path? path;
    for (var i = start; i <= end && i <= n; i++) {
      final p = points[i];
      if (p == null) {
        if (path != null) canvas.drawPath(path, paint);
        path = null;
        continue;
      }
      path == null
          ? path = (Path()..moveTo(p.dx, p.dy))
          : path.lineTo(p.dx, p.dy);
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  void _paintPins(Canvas canvas, Offset center, double r) {
    final pulse = (time % 1.8) / 1.8;
    final labels = showLabels
        ? placeLabels(
            viewLat: viewLat,
            viewLng: viewLng,
            center: center,
            radius: r,
          )
        : const <PlacedLabel>[];
    final focused = labels.isEmpty ? null : labels.first.city;

    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: viewLat,
        viewLng: viewLng,
        center: center,
        radius: r,
      );
      if (p == null || p.depth < 0.1) continue;
      final o = p.offset;
      final fade = math.min(1.0, p.depth * 2.5);
      if (city == focused) {
        canvas.drawCircle(
          o,
          8 + 14 * pulse,
          Paint()
            ..color = _pinColor.withValues(alpha: 0.5 * (1 - pulse) * fade),
        );
      }
      // Soft halo, white ring, dark centre.
      canvas.drawCircle(
        o,
        11,
        Paint()
          ..color = (light > 0.5 ? _mint : _pinColor).withValues(
            alpha: (light > 0.5 ? 0.22 : 0.32) * fade,
          ),
      );
      canvas.drawCircle(
        o,
        6.5,
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
      canvas.drawCircle(
        o,
        3,
        Paint()..color = const Color(0xFF0A2A31).withValues(alpha: fade),
      );
    }

    for (final l in labels) {
      final isFocused = l.city == focused;
      final tp = _labelText(
        l.city,
        focused: isFocused,
        alpha: l.fade,
        light: light > 0.5,
      );
      final rrect = RRect.fromRectAndRadius(l.box, const Radius.circular(12));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color =
              (isFocused
                      ? (light > 0.5 ? _mint : const Color(0xFF0A2A31))
                      : (light > 0.5 ? const Color(0xFFEAF6F3) : Colors.white))
                  .withValues(alpha: (isFocused ? 0.95 : 0.88) * l.fade),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = (isFocused ? _pinColor : Colors.white).withValues(
            alpha: 0.6 * l.fade,
          ),
      );
      tp.paint(canvas, l.box.topLeft + const Offset(12, 7));
    }
  }

  /// "Name  count", with the count in the accent colour.
  static TextPainter _labelText(
    City city, {
    bool focused = false,
    double alpha = 1,
    bool light = false,
  }) {
    final base = AppText.small.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: (focused ? Colors.white : AppColors.ink).withValues(alpha: alpha),
    );
    return TextPainter(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: city.name),
          TextSpan(
            text: '  ${city.guidesOnline}',
            style: base.copyWith(
              color:
                  (focused
                          ? (light ? const Color(0xFFCFEDE6) : _pinColor)
                          : (light ? _mint : AppColors.teal))
                      .withValues(alpha: alpha),
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Name pills for the cities facing the viewer, nearest the middle first;
  /// a pill that would overlap one already placed is left out. The first is
  /// the focused city. Shared by painting and tap handling, so the whole
  /// pill is a touch target.
  static List<PlacedLabel> placeLabels({
    required double viewLat,
    required double viewLng,
    required Offset center,
    required double radius,
  }) {
    final visible = <(City, Offset, double)>[];
    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: viewLat,
        viewLng: viewLng,
        center: center,
        radius: radius,
      );
      if (p != null && p.depth > 0.35) visible.add((city, p.offset, p.depth));
    }
    visible.sort((a, b) => b.$3.compareTo(a.$3));
    final placed = <PlacedLabel>[];
    for (final (city, dot, depth) in visible) {
      final tp = _labelText(city);
      final box = Rect.fromCenter(
        center: Offset(dot.dx, dot.dy - 14 - (tp.height + 14) / 2),
        width: tp.width + 24,
        height: tp.height + 14,
      );
      if (placed.any((l) => l.box.inflate(3).overlaps(box))) continue;
      placed.add(
        PlacedLabel(
          city: city,
          box: box,
          fade: ((depth - 0.35) / 0.25).clamp(0.0, 1.0),
        ),
      );
    }
    return placed;
  }

  static (double, double, double) _toVector(double lat, double lng) {
    final phi = lat * math.pi / 180, lambda = lng * math.pi / 180;
    return (
      math.cos(phi) * math.sin(lambda),
      math.sin(phi),
      math.cos(phi) * math.cos(lambda),
    );
  }

  static double _dot((double, double, double) a, (double, double, double) b) =>
      a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;

  static (double, double, double) _slerp(
    (double, double, double) a,
    (double, double, double) b,
    double angle,
    double t,
  ) {
    final s = math.sin(angle);
    final wa = math.sin((1 - t) * angle) / s, wb = math.sin(t * angle) / s;
    return (
      a.$1 * wa + b.$1 * wb,
      a.$2 * wa + b.$2 * wb,
      a.$3 * wa + b.$3 * wb,
    );
  }

  @override
  bool shouldRepaint(GlobePainter old) => true;
}

class PlacedLabel {
  const PlacedLabel({
    required this.city,
    required this.box,
    required this.fade,
  });

  final City city;
  final Rect box;
  final double fade;
}
