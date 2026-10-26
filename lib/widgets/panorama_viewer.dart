import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../data/content.dart';
import 'common.dart';
import 'gestures.dart';

/// Drag-to-look panorama. Uses a perspective shader over a cylindrical
/// panorama so it behaves like a 360° viewer; pinch to zoom.
class PanoramaViewer extends StatefulWidget {
  const PanoramaViewer({
    super.key,
    required this.image,
    required this.spanDegrees,
    this.hotspots = const [],
    this.initialX = 0.5,
    this.onExpand,
    this.expanded = false,
    this.insideScrollView = true,
  });

  /// File name in assets/images without the extension.
  final String image;

  /// Horizontal angle the photo covers.
  final double spanDegrees;
  final List<Hotspot> hotspots;

  /// Where to start looking, as a fraction of the image width.
  final double initialX;

  /// Shows a full-screen button in the zoom controls.
  final VoidCallback? onExpand;
  final bool expanded;

  /// When the viewer sits in a scrolling page, one-finger vertical drags
  /// scroll the page; use two fingers to look up and down.
  final bool insideScrollView;

  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer>
    with SingleTickerProviderStateMixin {
  static final Future<ui.FragmentProgram> _program =
      ui.FragmentProgram.fromAsset('shaders/panorama.frag');

  ui.FragmentShader? _shader;
  ui.Image? _image;
  late final Ticker _ticker;

  late double _yaw = _span * (widget.initialX - 0.5);
  double _pitch = 0;
  double _fov = 58 * math.pi / 180;
  late double _targetFov = _fov;
  double _fovAtScaleStart = 0;
  bool _pinching = false;
  Duration _last = Duration.zero;
  Duration _idleUntil = const Duration(seconds: 1);
  double _drift = 1;
  Size _size = Size.zero;

  double get _span => widget.spanDegrees * math.pi / 180;

  double get _halfTan =>
      _image == null ? 0.4 : _image!.height * _span / (2 * _image!.width);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _load();
  }

  Future<void> _load() async {
    final program = await _program;
    final data = await rootBundle.load('assets/images/${widget.image}.jpg');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _shader = program.fragmentShader();
      _image = frame.image;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _image?.dispose();
    super.dispose();
  }

  /// Slowly pans back and forth while nobody is touching it.
  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_image == null || _size.isEmpty) return;
    if ((_targetFov - _fov).abs() > 0.001) {
      setState(() => _fov += (_targetFov - _fov) * math.min(1, dt * 12));
    }
    if (elapsed < _idleUntil) return;
    final limit = _yawLimit();
    var yaw = _yaw + _drift * dt * 0.06;
    if (yaw.abs() >= limit) {
      _drift = -_drift;
      yaw = yaw.clamp(-limit, limit);
    }
    setState(() => _yaw = yaw);
  }

  double _yawLimit() {
    final aspect = _size.width / _size.height;
    final halfH = math.atan(math.tan(_fov / 2) * aspect);
    return math.max(0, _span / 2 - halfH);
  }

  double _pitchLimit() => math.max(0, math.atan(_halfTan) - _fov / 2);

  /// Widest view that still stays inside the photo vertically.
  double get _maxFov => math.min(1.1, 2 * math.atan(_halfTan) * 0.97);

  /// About 3× zoom.
  static const _minFov = 0.36;

  void _zoomBy(double factor) => setState(() {
    _pauseDrift();
    _targetFov = (_targetFov * factor).clamp(_minFov, _maxFov);
  });

  void _clamp() {
    _fov = math.min(_fov, _maxFov);
    _targetFov = math.min(_targetFov, _maxFov);
    final y = _yawLimit(), p = _pitchLimit();
    _yaw = _yaw.clamp(-y, y);
    _pitch = _pitch.clamp(-p, p);
  }

  void _look(Offset delta, {required bool vertical}) {
    final perPixel = _fov / _size.height;
    _yaw -= delta.dx * perPixel;
    if (vertical) _pitch += delta.dy * perPixel;
  }

  void _drag(Offset delta) {
    if (_pinching) return;
    setState(() {
      _pauseDrift();
      _look(delta, vertical: !widget.insideScrollView);
    });
  }

  void _pauseDrift() => _idleUntil = _last + const Duration(seconds: 4);

  /// Screen position of an image point, or null when it is out of view.
  Offset? _project(double fx, double fy) {
    final yaw = (fx - 0.5) * _span;
    final pitch = math.atan((0.5 - fy) * 2 * _halfTan);
    var x = math.cos(pitch) * math.sin(yaw);
    var y = math.sin(pitch);
    var z = math.cos(pitch) * math.cos(yaw);
    // Undo the camera rotation (yaw, then pitch).
    final cy = math.cos(_yaw), sy = math.sin(_yaw);
    final x1 = x * cy - z * sy;
    final z1 = x * sy + z * cy;
    final cp = math.cos(_pitch), sp = math.sin(_pitch);
    final y2 = y * cp - z1 * sp;
    final z2 = y * sp + z1 * cp;
    x = x1;
    y = y2;
    z = z2;
    if (z <= 0.05) return null;
    final t = math.tan(_fov / 2);
    final aspect = _size.width / _size.height;
    final nx = x / z / (t * aspect);
    final ny = y / z / t;
    if (nx.abs() > 1.2 || ny.abs() > 1.2) return null;
    return Offset((nx + 1) / 2 * _size.width, (1 - ny) / 2 * _size.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final ready = _shader != null && _image != null;
        if (ready) _clamp();

        return Listener(
          onPointerSignal: (event) {
            // Mouse wheel / trackpad zoom; claim it so the page doesn't scroll.
            if (event is PointerScrollEvent) {
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (e) => _zoomBy(
                  math.exp((e as PointerScrollEvent).scrollDelta.dy * 0.0015),
                ),
              );
            }
          },
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              DoubleTapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    DoubleTapGestureRecognizer
                  >(DoubleTapGestureRecognizer.new, (r) {
                    r.onDoubleTap = () =>
                        _zoomBy(_targetFov > _maxFov * 0.7 ? 0.5 : 2);
                  }),
              PinchGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<PinchGestureRecognizer>(
                    PinchGestureRecognizer.new,
                    (r) {
                      r.onStart = () {
                        _pauseDrift();
                        _pinching = true;
                        _fovAtScaleStart = _fov;
                      };
                      r.onUpdate = (scale, delta, focal) {
                        setState(() {
                          _pauseDrift();
                          _look(delta, vertical: true);
                          _fov = _targetFov = (_fovAtScaleStart / scale).clamp(
                            _minFov,
                            _maxFov,
                          );
                        });
                      };
                      r.onEnd = () => _pinching = false;
                    },
                  ),
              // In a scrolling page one finger only turns sideways, so
              // up/down still scrolls the page.
              if (widget.insideScrollView)
                HorizontalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      HorizontalDragGestureRecognizer
                    >(HorizontalDragGestureRecognizer.new, (r) {
                      r.onUpdate = (d) => _drag(d.delta);
                    })
              else
                PanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                      PanGestureRecognizer.new,
                      (r) {
                        r.onUpdate = (d) => _drag(d.delta);
                      },
                    ),
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ready)
                  CustomPaint(
                    painter: _PanoramaPainter(
                      shader: _shader!,
                      image: _image!,
                      yaw: _yaw,
                      pitch: _pitch,
                      fov: _fov,
                      span: _span,
                      halfTan: _halfTan,
                    ),
                  )
                else
                  const ColoredBox(
                    color: Color(0xFFBFE0E1),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    ),
                  ),
                if (ready)
                  for (final h in widget.hotspots)
                    if (_project(h.x, h.y) case final p?)
                      Positioned(
                        left: p.dx - 70,
                        top: p.dy - 46,
                        width: 140,
                        child: HotspotPin(hotspot: h),
                      ),
                if (ready)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: ZoomControls(
                      onZoomIn: _targetFov > _minFov + 0.01
                          ? () => _zoomBy(0.7)
                          : null,
                      onZoomOut: _targetFov < _maxFov - 0.01
                          ? () => _zoomBy(1 / 0.7)
                          : null,
                      onExpand: widget.onExpand,
                      expanded: widget.expanded,
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

class _PanoramaPainter extends CustomPainter {
  _PanoramaPainter({
    required this.shader,
    required this.image,
    required this.yaw,
    required this.pitch,
    required this.fov,
    required this.span,
    required this.halfTan,
  });

  final ui.FragmentShader shader;
  final ui.Image image;
  final double yaw, pitch, fov, span, halfTan;

  static const _sky = Color(0xFFDCEBF2);
  static const _ground = Color(0xFFD9CDB8);

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    for (final v in [
      size.width,
      size.height,
      yaw,
      pitch,
      fov,
      span,
      halfTan,
      _sky.r,
      _sky.g,
      _sky.b,
      1.0,
      _ground.r,
      _ground.g,
      _ground.b,
      1.0,
    ]) {
      shader.setFloat(i++, v);
    }
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PanoramaPainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.fov != fov ||
      old.image != image;
}

class HotspotPin extends StatelessWidget {
  const HotspotPin({super.key, required this.hotspot});

  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hotspot.icon, size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  hotspot.label,
                  style: AppText.small.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 10, color: Colors.white),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}
