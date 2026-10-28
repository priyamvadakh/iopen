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

/// Small round-crop city photos for the globe's picture pins, loaded on
/// first use.
abstract final class CityPhotos {
  static final _images = <String, ui.Image>{};
  static bool _started = false;

  static ui.Image? of(City city) {
    if (!_started) {
      _started = true;
      for (final c in cities) {
        rootBundle.load('assets/images/${c.coverImage}.jpg').then((data) async {
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
            targetWidth: 128,
          );
          _images[c.id] = (await codec.getNextFrame()).image;
        }, onError: (_) {});
      }
    }
    return _images[city.id];
  }
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
    this.showLabels = true,
    this.crystal = false,
    this.photoPins = false,
  });

  /// Round city photos on the globe instead of name chips.
  final bool photoPins;

  /// City name pills; off when the page shows its own city bubbles.
  final bool showLabels;

  /// Teal crystal look with a steady, even spin (Home).
  final bool crystal;

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
      // With city titles showing, it tours from city to city instead.
      if (touring && widget.crystal && !widget.showLabels) {
        _steadySpin(math.min(dt, 0.1));
      } else if (touring) {
        _glideTour(elapsed, math.min(dt, 0.05));
      } else {
        _vLat = 0;
      }
    });
  }

  // The tour turns the globe all the way round, eastwards: it eases down
  // as each live city comes to the front, then speeds up again across the
  // oceans, tilting gently towards the city it is passing.
  double _vLat = 0;

  /// An even turn, eased in from a standstill so it never jerks.
  double _spinSpeed = 0;

  void _steadySpin(double dt) {
    _spinSpeed += (5 - _spinSpeed) * math.min(1, dt * 0.8);
    _lng += dt * _spinSpeed;
    _lat += (widget.initialLat - _lat) * math.min(1, dt * 1.5);
  }

  void _glideTour(Duration elapsed, double dt) {
    City? nearest;
    var gap = 360.0;
    for (final c in cities) {
      final d = (((c.lng - _lng + 540) % 360) - 180).abs();
      if (d < gap) {
        gap = d;
        nearest = c;
      }
    }
    final ease = Curves.easeInOut.transform((gap / 30).clamp(0.0, 1.0));
    _lng += dt * (2.5 + 15 * ease) / _zoom;

    final targetLat = gap < 30 && nearest != null
        ? (nearest.lat * 0.75 + 8).clamp(-60.0, 70.0)
        : 18.0;
    // Critically damped spring: smooth, no overshoot.
    const k = 1.2;
    final damping = 2 * math.sqrt(k);
    _vLat += (k * (targetLat - _lat) - damping * _vLat) * dt;
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
                    showLabels: widget.showLabels,
                    light: globeLight.value ? 1 : 0,
                    crystal: widget.crystal ? 1 : 0,
                    photoPins: widget.photoPins,
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
    this.crystal = 0,
    this.photoPins = false,
    this.center,
    this.radius,
  });

  /// Draws city photos in glass rings instead of name chips.
  final bool photoPins;

  /// 1 = teal crystal globe with white glowing routes.
  final double crystal;

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
    if (photoPins && showLabels) {
      _paintPhotoPins(canvas, center, r);
    } else {
      _paintPins(canvas, center, r);
    }
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
      crystal,
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

      if (light > 0.5 && crystal < 0.5) {
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
        ..color = (crystal > 0.5 ? Colors.white : _pinColor).withValues(
          alpha: crystal > 0.5 ? 0.55 : 0.25,
        );
      _drawPolyline(canvas, points, 0, 1, base);

      final head = ((time * 0.35 + k * 0.23) % 1.4);
      final comet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = (crystal > 0.5 ? Colors.white : _pinColor).withValues(
          alpha: 0.9,
        )
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

  /// Each city on the front of the globe gets its photo in a glossy white
  /// ring, standing on a short stem over its glowing dot, with its name
  /// underneath. Nearer cities win when two would overlap.
  void _paintPhotoPins(Canvas canvas, Offset center, double r) {
    final visible = <(City, Offset, double)>[];
    for (final city in cities) {
      final p = projectPoint(
        lat: city.lat,
        lng: city.lng,
        viewLat: viewLat,
        viewLng: viewLng,
        center: center,
        radius: r,
      );
      if (p != null && p.depth > 0.25) visible.add((city, p.offset, p.depth));
    }
    visible.sort((a, b) => b.$3.compareTo(a.$3));
    final placed = <(City, Offset, Offset, double, double)>[];
    for (final (city, dot, depth) in visible) {
      final front = placed.isEmpty;
      final size = front ? 23.0 : 18.0;
      final at = dot - Offset(0, size + 14);
      if (placed.any((q) => (q.$3 - at).distance < q.$4 + size + 4)) continue;
      placed.add((city, dot, at, size, ((depth - 0.25) / 0.25).clamp(0, 1)));
    }
    // Farthest first so the nearest photo sits on top.
    for (final (city, dot, at, size, fade) in placed.reversed) {
      canvas.saveLayer(
        Rect.fromCircle(center: at, radius: size + 40),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
      canvas.drawCircle(
        dot,
        8,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(dot, 3, Paint()..color = Colors.white);
      canvas.drawLine(
        dot,
        at + Offset(0, size),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.6,
      );
      // Soft shadow and aqua glow, then the white glass ring.
      canvas.drawCircle(
        at + const Offset(0, 3),
        size + 3,
        Paint()
          ..color = const Color(0xFF0F1B3D).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        at,
        size + 6,
        Paint()
          ..color = const Color(0xFF7FE6EE).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        at,
        size + 3,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFA9ECF0), Colors.white],
          ).createShader(Rect.fromCircle(center: at, radius: size + 3)),
      );
      final photo = CityPhotos.of(city);
      final inner = Rect.fromCircle(center: at, radius: size);
      canvas.save();
      canvas.clipPath(Path()..addOval(inner));
      if (photo != null) {
        final w = photo.width.toDouble(), h = photo.height.toDouble();
        final side = math.min(w, h);
        canvas.drawImageRect(
          photo,
          Rect.fromCenter(
            center: Offset(w / 2, h / 2),
            width: side,
            height: side,
          ),
          inner,
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        canvas.drawRect(inner, Paint()..color = AppColors.teal);
      }
      // Glass dome sheen over the top of the photo.
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.5),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(inner),
      );
      canvas.restore();
      // Name and live Guide count on a small frosted tag under the dot.
      final tp = TextPainter(
        text: TextSpan(
          text: '${city.name} ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F1B3D),
          ),
          children: [
            TextSpan(
              text: '${city.guidesOnline}',
              style: const TextStyle(color: AppColors.teal),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final tag = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: dot + Offset(0, 8 + tp.height / 2 + 3),
          width: tp.width + 12,
          height: tp.height + 6,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        tag,
        Paint()..color = Colors.white.withValues(alpha: 0.88),
      );
      tp.paint(canvas, tag.outerRect.topLeft + const Offset(6, 3));
      canvas.restore();
    }
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
      if (crystal > 0.5) {
        // Crystal: a glowing white node, like the design's network lights.
        canvas.drawCircle(
          o,
          9,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          o,
          3,
          Paint()..color = Colors.white.withValues(alpha: fade),
        );
        continue;
      }
      // Soft halo, then a white dot with a dark ring.
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
        6,
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
      canvas.drawCircle(
        o,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = const Color(0xFF10202A).withValues(alpha: fade),
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
      // Fully rounded pills: frosted white, or glossy green-teal when
      // focused, with a crisp edge so they read clearly over the pattern.
      final rrect = RRect.fromRectAndRadius(
        l.box,
        Radius.circular(l.box.height / 2),
      );
      final lightStyle = light > 0.5;
      final fill = Paint();
      if (isFocused) {
        fill.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lightStyle
              ? const [Color(0xFF64A396), _mint, Color(0xFF326C61)]
              : const [Color(0xFF4FA3A9), AppColors.teal, AppColors.tealDark],
        ).createShader(l.box);
      } else {
        fill.color = (lightStyle ? Colors.white : const Color(0xFF15282E))
            .withValues(alpha: 0.9);
      }
      canvas.saveLayer(
        l.box.inflate(14),
        Paint()..color = Color.fromRGBO(0, 0, 0, l.fade),
      );
      // Standing up off the globe: a soft shadow below, then a slightly
      // darker base edge that gives the pill some thickness.
      canvas.drawRRect(
        rrect.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0xFF1F4D45).withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(
        rrect.shift(const Offset(0, 2)),
        Paint()
          ..color = isFocused
              ? const Color(0xFF285A51)
              : (lightStyle
                    ? const Color(0xFFC9DED8)
                    : const Color(0xFF0A171B)),
      );
      canvas.drawRRect(rrect, fill);
      // Gloss: a faint highlight along the top half.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            l.box.left + 4,
            l.box.top + 2,
            l.box.right - 4,
            l.box.center.dy,
          ),
          Radius.circular(l.box.height / 2),
        ),
        Paint()
          ..color = Colors.white.withValues(
            alpha: isFocused ? 0.16 : (lightStyle ? 0.5 : 0.06),
          ),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = isFocused
              ? Colors.white.withValues(alpha: 0.35)
              : (lightStyle
                    ? const Color(0xFFD3E8E2)
                    : _pinColor.withValues(alpha: 0.35)),
      );
      canvas.restore();
      tp.paint(canvas, l.box.topLeft + const Offset(15, 8));
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
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: (focused || !light ? Colors.white : const Color(0xFF10202A))
          .withValues(alpha: alpha),
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
                          : (light ? _mint : _pinColor))
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
        center: Offset(dot.dx, dot.dy - 16 - (tp.height + 16) / 2),
        width: tp.width + 30,
        height: tp.height + 16,
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
