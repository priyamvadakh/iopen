import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Where a sparkle sits: its centre at a fraction of the width/height plus
/// a pixel offset, so it can ride an edge.
class SparkleSpot {
  const SparkleSpot(this.fx, this.dx, this.fy, this.dy, this.size, this.delay);

  final double fx, dx, fy, dy;
  final double size;

  /// Seconds into the twinkle cycle this one lags.
  final double delay;

  Offset centerIn(Size s) => Offset(s.width * fx + dx, s.height * fy + dy);
}

/// Liquid glass: a clear, saturated, refracting body; a rim that catches
/// light top-left and bottom-right; inner depth; a curved specular
/// highlight; glossy teal reflections along both edges; and sparkles that
/// twinkle on the rim while a glint travels round it.
///
/// [crystal] adds a cut-crystal finish: clearer body, prismatic rim, facet
/// glints, a liquid right cap, caustics and more sparkle.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    required this.radius,
    this.height,
    this.crystal = false,
  });

  final Widget child;
  final double radius;
  final double? height;
  final bool crystal;

  static const _spots = [
    SparkleSpot(0.14, 0, 0, 3, 14, 0),
    SparkleSpot(0.78, 0, 0, 2, 10, 1.1),
    SparkleSpot(0.68, 0, 1, -2, 12, 1.9),
    SparkleSpot(1, 2, 0.38, 4.5, 9, 0.6),
  ];
  static const _crystalSpots = [
    SparkleSpot(0.14, 0, 0, 3.5, 15, 0),
    SparkleSpot(0.38, 0, 0, 1.5, 9, 2.3),
    SparkleSpot(0.78, 0, 0, 2.5, 11, 1.1),
    SparkleSpot(0, -2, 0.4, 5, 10, 1.6),
    SparkleSpot(1, 2, 0.38, 5, 10, 0.6),
    SparkleSpot(0.3, 0, 1, -0.5, 9, 2.7),
    SparkleSpot(0.68, 0, 1, -2.5, 13, 1.9),
    SparkleSpot(0.52, 0, 0.3, 4, 8, 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    // Crystal is clear glass: almost no tint and only a light blur, so
    // what's behind shows through.
    final blur = crystal ? 1.5 : 7.0;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _OuterShadowPainter(radius: radius, crystal: crystal),
        child: ClipRRect(
          borderRadius: shape,
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: ColorFilter.matrix(
                _saturate(crystal ? 1.6 : 1.9, crystal ? 1.04 : 1.06),
              ),
              inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: crystal
                      ? const [
                          Color(0x24FFFFFF),
                          Color(0x0AD6FCF7),
                          Color(0x059FFFF1),
                          Color(0x1AC8FFF8),
                        ]
                      : const [
                          Color(0x6BFFFFFF),
                          Color(0x2ED6FCF7),
                          Color(0x1A9FFFF1),
                          Color(0x42C8FFF8),
                        ],
                  stops: const [0, 0.45, 0.75, 1],
                ),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _GlassBodyPainter(
                            radius: radius,
                            crystal: crystal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GlassSparkles(
                      spots: crystal ? _crystalSpots : _spots,
                      radius: radius,
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Saturation and brightness, like CSS `saturate() brightness()`.
  static List<double> _saturate(double s, double b) {
    const r = 0.2126, g = 0.7152, bl = 0.0722;
    return [
      (r + (1 - r) * s) * b, (g - g * s) * b, (bl - bl * s) * b, 0, 0, //
      (r - r * s) * b, (g + (1 - g) * s) * b, (bl - bl * s) * b, 0, 0,
      (r - r * s) * b, (g - g * s) * b, (bl + (1 - bl) * s) * b, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Shadow and teal glow outside the glass only, so they don't show
/// through the clear body as a grey wash.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.radius, required this.crystal});

  final double radius;
  final bool crystal;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(80)),
        Path()..addRRect(rrect),
      ),
    );
    canvas.drawRRect(
      rrect.shift(Offset(0, crystal ? 8 : 10)),
      Paint()
        ..color = const Color(0xFF0F1B3D)
            .withValues(alpha: crystal ? 0.06 : 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, crystal ? 12 : 15),
    );
    canvas.drawRRect(
      rrect.inflate(2),
      Paint()
        ..color = const Color(0xFF57D1C7).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.radius != radius || old.crystal != crystal;
}

/// Everything static on the glass: inner depth, rims, highlights,
/// reflections and, for crystal, its prismatic and liquid details.
class _GlassBodyPainter extends CustomPainter {
  const _GlassBodyPainter({required this.radius, required this.crystal});

  final double radius;
  final bool crystal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, r = radius;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));
    canvas.save();
    canvas.clipRRect(rrect);

    // Inner depth: bright top and bottom lines, a soft white bloom and a
    // teal pool along the bottom.
    _insetShadow(
      canvas,
      rrect,
      Colors.white.withValues(alpha: 0.95),
      0,
      1.5,
      0,
    );
    _insetShadow(
      canvas,
      rrect,
      Colors.white.withValues(alpha: 0.55),
      0,
      -1.5,
      0,
    );
    _insetShadow(
      canvas,
      rrect,
      Colors.white.withValues(alpha: crystal ? 0.3 : 0.45),
      0,
      0,
      crystal ? 10 : 20,
    );
    _insetShadow(
      canvas,
      rrect,
      const Color(0xFF57D1C7).withValues(alpha: crystal ? 0.22 : 0.28),
      0,
      crystal ? -10 : -12,
      crystal ? 18 : 22,
      spread: crystal ? -8 : -6,
    );

    // Directional rim: bright where the light hits, teal where it bends.
    _ring(
      canvas,
      rrect.deflate(1),
      2,
      _conic(210, const [
        (0, Colors.white),
        (70, Color(0xFFB7FFF4)),
        (140, Color(0x8C57D1C7)),
        (200, Colors.white),
        (260, Color(0xFF8FFFF0)),
        (320, Color(0x8057D1C7)),
        (360, Colors.white),
      ], rect),
    );

    // Inner refractive rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(5.5),
        Radius.circular(math.max(r - 5, 0)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    // Curved specular highlight across the upper half.
    final spec = Rect.fromLTWH(12, 4, w - 24, h * 0.46);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        spec,
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.elliptical(r * 0.6, r * 0.35),
        bottomRight: Radius.elliptical(r * 0.6, r * 0.35),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: crystal
              ? [
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0),
                ]
              : [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0),
                ],
          stops: crystal ? const [0, 0.45, 1] : const [0, 0.55, 1],
        ).createShader(spec),
    );

    // Hot spot where the light source reflects.
    _glow(canvas, Rect.fromLTWH(w * 0.08, 6, w * 0.22, 10), [
      Colors.white.withValues(alpha: 0.95),
      Colors.white.withValues(alpha: 0),
    ], blur: 1.5);

    // Glossy teal reflections along the top and bottom edges.
    _reflection(
      canvas,
      Rect.fromLTRB(r * 0.8, 3, w - r * 0.8, 5.5),
      const [
        Colors.transparent,
        Color(0xFF8FFFF0),
        Colors.white,
        Color(0xFF57D1C7),
        Colors.white,
        Colors.transparent,
      ],
      const Color(0x9957D1C7),
      4,
    );
    _reflection(
      canvas,
      Rect.fromLTRB(r * 0.6, h - 6, w - r * 0.6, h - 3),
      const [
        Colors.transparent,
        Color(0xFF57D1C7),
        Colors.white,
        Color(0xFF70FFDB),
        Colors.white,
        Colors.transparent,
      ],
      const Color(0xB357D1C7),
      5,
    );

    if (crystal) _crystal(canvas, size);
    canvas.restore();
  }

  void _crystal(Canvas canvas, Size size) {
    final w = size.width, h = size.height, r = radius;
    final rect = Offset.zero & size;

    // Prismatic rim: light splitting into pale spectrum colours.
    _ring(
      canvas,
      RRect.fromRectAndRadius(rect.deflate(1.75), Radius.circular(r - 1)),
      1.5,
      _conic(0, const [
        (0, Color(0xE6FFFFFF)),
        (40, Color(0xE6FFD6EC)),
        (70, Color(0xE6FFFFFF)),
        (120, Color(0xE6C9F7FF)),
        (165, Color(0xE6E6D9FF)),
        (200, Color(0xE6FFFFFF)),
        (245, Color(0xE6FFF3C4)),
        (290, Color(0xE6C6FFF0)),
        (330, Color(0xE6D8E4FF)),
        (360, Color(0xE6FFFFFF)),
      ], rect),
    );

    // Cut facets: diagonal planes of light across the crystal.
    for (final (left, width, opacity) in const [
      (0.11, 10.0, 0.55),
      (0.15, 3.0, 0.8),
      (0.47, 14.0, 0.35),
      (0.52, 3.0, 0.6),
      (0.83, 8.0, 0.45),
    ]) {
      final top = -16.0, height = h * 1.6;
      final strip = Rect.fromLTWH(w * left, top, width, height);
      canvas.save();
      // Skew about the strip's centre, like CSS -skew-x-[28deg].
      canvas.translate(strip.center.dx, strip.center.dy);
      canvas.transform(
        (Matrix4.identity()..setEntry(0, 1, math.tan(28 * math.pi / 180)))
            .storage,
      );
      canvas.translate(-strip.center.dx, -strip.center.dy);
      canvas.drawRect(
        strip,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.9 * opacity),
              Colors.white.withValues(alpha: 0.15 * opacity),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 0.7, 1],
          ).createShader(strip),
      );
      canvas.restore();
    }

    // Liquid right cap: a thick meniscus where the glass rolls round.
    final capW = r * 1.6;
    final cap = Rect.fromLTWH(w - capW, 0, capW, h);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        cap,
        topRight: Radius.circular(r),
        bottomRight: Radius.circular(r),
      ),
    );
    canvas.translate(cap.left, h / 2);
    canvas.scale(capW * 1.15, h * 0.92);
    canvas.drawRect(
      const Rect.fromLTRB(0, -1, 1, 1),
      Paint()
        ..shader = const RadialGradient(
          // A unit circle at the cap's left middle, stretched by the scale.
          radius: 0.5,
          colors: [
            Color(0x00FFFFFF),
            Color(0x40C6FFF8),
            Color(0x8C8FFFF0),
            Color(0xF2FFFFFF),
            Color(0xB3B7FFF4),
            Color(0x5957D1C7),
          ],
          stops: [0.58, 0.68, 0.78, 0.88, 0.93, 1],
        ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
    );
    canvas.restore();

    // Inner refraction line following the curve of the cap.
    final lineW = r * 0.9;
    final line = Rect.fromLTRB(w - 9 - lineW, 9, w - 9, h - 9);
    final lr = math.min(lineW, line.height / 2);
    final path = Path()
      ..moveTo(line.left, line.top)
      ..lineTo(line.right - lr, line.top)
      ..arcToPoint(
        Offset(line.right, line.top + lr),
        radius: Radius.circular(lr),
      )
      ..lineTo(line.right, line.bottom - lr)
      ..arcToPoint(
        Offset(line.right - lr, line.bottom),
        radius: Radius.circular(lr),
      )
      ..lineTo(line.left, line.bottom);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x738FFFF0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.8),
    );

    // Droplet highlight: a soft wet specular on the upper right.
    _rotatedGlow(
      canvas,
      Offset(w - r * 0.38 - r * 0.275, 10 + 5.5),
      Size(r * 0.55, 11),
      18,
      [
        Colors.white,
        Colors.white.withValues(alpha: 0.55),
        Colors.white.withValues(alpha: 0),
      ],
      blur: 0.75,
    );
    _glow(canvas, Rect.fromLTWH(w - r * 0.2 - 5, 26, 5, 5), [
      Colors.white,
      Colors.white.withValues(alpha: 0),
    ]);
    // Teal light bending round the lower right of the cap.
    _rotatedGlow(
      canvas,
      Offset(w - r * 0.25 - r * 0.4, h - 6 - 6),
      Size(r * 0.8, 12),
      -22,
      [const Color(0xD970FFDB), const Color(0x0057D1C7)],
      blur: 2.5,
    );

    // Caustics: soft coloured light pooling along the bottom inside edge.
    final caustic = Rect.fromLTRB(24, h - 20, w - 24, h - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(caustic, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x00C9F7FF),
            Color(0xE6C9F7FF),
            Color(0xB3E6D9FF),
            Color(0xE6C6FFF0),
            Color(0x99FFF3C4),
            Color(0x00FFF3C4),
          ],
          stops: [0, 0.2, 0.45, 0.7, 0.85, 1],
        ).createShader(caustic)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  /// CSS `conic-gradient(from <from>deg, ...)` as a sweep gradient.
  static Shader _conic(double from, List<(double, Color)> stops, Rect rect) =>
      SweepGradient(
        colors: [for (final s in stops) s.$2],
        stops: [for (final s in stops) s.$1 / 360],
        // CSS starts at 12 o'clock, Flutter at 3 o'clock.
        transform: GradientRotation((from - 90) * math.pi / 180),
      ).createShader(rect);

  static void _ring(Canvas canvas, RRect rrect, double width, Shader shader) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = shader,
    );
  }

  /// CSS inset box-shadow.
  static void _insetShadow(
    Canvas canvas,
    RRect rrect,
    Color color,
    double dx,
    double dy,
    double blur, {
    double spread = 0,
  }) {
    final hole = rrect.shift(Offset(dx, dy)).deflate(spread);
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(rrect.outerRect.inflate(blur + 40)),
      Path()..addRRect(hole),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = blur > 0
            ? MaskFilter.blur(BlurStyle.normal, blur / 2)
            : null,
    );
  }

  static void _glow(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    double blur = 0,
  }) {
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(colors: colors).createShader(rect)
        ..maskFilter = blur > 0
            ? MaskFilter.blur(BlurStyle.normal, blur)
            : null,
    );
  }

  static void _rotatedGlow(
    Canvas canvas,
    Offset center,
    Size size,
    double degrees,
    List<Color> colors, {
    double blur = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    _glow(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width,
        height: size.height,
      ),
      colors,
      blur: blur,
    );
    canvas.restore();
  }

  static void _reflection(
    Canvas canvas,
    Rect rect,
    List<Color> colors,
    Color glow,
    double blur,
  ) {
    if (rect.width <= 0) return;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      rrect.inflate(1),
      Paint()
        ..color = glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
    canvas.drawRRect(
      rrect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassBodyPainter old) =>
      old.radius != radius || old.crystal != crystal;
}

/// Glass edge sparkle: a glint that travels round the rim and four-point
/// star glints that twinkle.
class GlassSparkles extends StatefulWidget {
  const GlassSparkles({
    super.key,
    required this.spots,
    required this.radius,
    this.glint = true,
  });

  final List<SparkleSpot> spots;
  final double radius;
  final bool glint;

  @override
  State<GlassSparkles> createState() => _GlassSparklesState();
}

class _GlassSparklesState extends State<GlassSparkles>
    with SingleTickerProviderStateMixin {
  /// 14 s holds whole cycles of the 7 s glint and the 2.8 s twinkle.
  static const _period = 14.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SparklePainter(
            spots: widget.spots,
            radius: widget.radius,
            glint: widget.glint,
            time: still ? null : _controller,
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.spots,
    required this.radius,
    required this.glint,
    required this.time,
  }) : super(repaint: time);

  final List<SparkleSpot> spots;
  final double radius;
  final bool glint;

  /// Null when motion is reduced: a still glint, sparkles mostly lit.
  final Animation<double>? time;

  static final _star = Path()
    ..moveTo(12, 0)
    ..cubicTo(12.8, 8, 16, 11.2, 24, 12)
    ..cubicTo(16, 12.8, 12.8, 16, 12, 24)
    ..cubicTo(11.2, 16, 8, 12.8, 0, 12)
    ..cubicTo(8, 11.2, 11.2, 8, 12, 0)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time == null ? null : time!.value * _GlassSparklesState._period;
    final rect = Offset.zero & size;

    if (glint) {
      final angle = t == null ? 300.0 : (t / 7 % 1) * 360;
      final shader = _GlassBodyPainter._conic(angle, const [
        (0, Color(0x00FFFFFF)),
        (34, Color(0x00FFFFFF)),
        (44, Color(0x59FFFFFF)),
        (52, Color(0xFFFFFFFF)),
        (60, Color(0x59FFFFFF)),
        (70, Color(0x00FFFFFF)),
        (196, Color(0x00FFFFFF)),
        (206, Color(0x4DB7FFF4)),
        (214, Color(0xFFE9FFFC)),
        (222, Color(0x4DB7FFF4)),
        (232, Color(0x00FFFFFF)),
        (360, Color(0x00FFFFFF)),
      ], rect);
      final rrect = RRect.fromRectAndRadius(
        rect.deflate(1),
        Radius.circular(radius),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..shader = shader,
      );
    }

    for (final s in spots) {
      final (opacity, scale, turn) = t == null
          ? (0.85, 1.0, 0.0)
          : _twinkle(((t - s.delay) % 2.8) / 2.8);
      final c = s.centerIn(size);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(turn * math.pi / 180);
      canvas.scale(scale * s.size / 24);
      canvas.translate(-12, -12);
      canvas.drawPath(
        _star,
        Paint()
          ..color = const Color(0xFF8FFFF0).withValues(alpha: 0.9 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * 24 / s.size),
      );
      canvas.drawPath(
        _star,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * 24 / s.size),
      );
      canvas.drawPath(
        _star,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  /// Opacity, scale and rotation through one twinkle.
  static (double, double, double) _twinkle(double p) {
    double lerp(double a, double b, double k) =>
        a + (b - a) * Curves.easeInOut.transform(k);
    if (p < 0.45) {
      final k = p / 0.45;
      return (lerp(0.15, 1, k), lerp(0.55, 1, k), lerp(0, 20, k));
    }
    if (p < 0.6) {
      final k = (p - 0.45) / 0.15;
      return (lerp(1, 0.9, k), lerp(1, 0.9, k), lerp(20, 25, k));
    }
    final k = (p - 0.6) / 0.4;
    return (lerp(0.9, 0.15, k), lerp(0.9, 0.55, k), lerp(25, 0, k));
  }

  @override
  bool shouldRepaint(_SparklePainter old) =>
      old.spots != spots || old.radius != radius || old.time != time;
}

/// CSS-style inset box-shadow inside [rrect]; clip to it first.
void paintInsetShadow(
  Canvas canvas,
  RRect rrect,
  Color color, {
  double dx = 0,
  double dy = 0,
  double blur = 0,
  double spread = 0,
}) => _GlassBodyPainter._insetShadow(
  canvas,
  rrect,
  color,
  dx,
  dy,
  blur,
  spread: spread,
);

/// Soft radial glow filling the oval [rect].
void paintGlow(Canvas canvas, Rect rect, Color color, {double blur = 0}) =>
    _GlassBodyPainter._glow(canvas, rect, [
      color,
      color.withValues(alpha: 0),
    ], blur: blur);
