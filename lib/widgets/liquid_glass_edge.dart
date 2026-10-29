import 'package:flutter/material.dart';

/// The liquid-glass edge shared by the tab bar and the flip cards: a soft
/// rim of light melting inwards from the outside, embossed with a bright
/// line along the top and bottom and a faint shadow just inside each, and
/// light flaring where the top edge catches it.
class LiquidGlassEdgePainter extends CustomPainter {
  const LiquidGlassEdgePainter({
    required this.radius,
    this.rim = 9,
    this.flares = const [0.4, 0.88],
  });

  /// Corner radius of the glass.
  final double radius;

  /// How far the rim of light reaches inwards.
  final double rim;

  /// Where light flares on the top edge, as fractions of the width.
  final List<double> flares;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(shape);

    // The rim: thin strokes stepping inwards, each fainter than the last,
    // softened so they blend into one band.
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      final t = i / (steps - 1);
      canvas.drawRRect(
        shape.deflate(0.6 + t * rim),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim / steps + 0.6
          ..color = Colors.white.withValues(
            alpha: 0.7 * (1 - t) * (1 - t) + 0.1 * t,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    // Emboss: a crisp bright line at the very edge, then a faint shadow a
    // little further in, along the top and (softer) along the bottom.
    // Both fade out towards the rounded ends.
    Shader along(double alpha) => LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: alpha),
        Colors.white.withValues(alpha: alpha),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0, 0.12, 0.88, 1],
    ).createShader(rect);
    for (final (top, light, shade) in [(true, 0.95, 0.16), (false, 0.7, 0.1)]) {
      canvas.save();
      canvas.clipRect(
        top
            ? Rect.fromLTWH(0, 0, size.width, size.height * 0.35)
            : Rect.fromLTWH(0, size.height * 0.65, size.width, size.height),
      );
      canvas.drawRRect(
        shape.deflate(1.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = along(light),
      );
      canvas.drawRRect(
        shape.deflate(rim * 0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF0E2A36).withValues(alpha: shade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
      canvas.restore();
    }

    // Flares where the top edge catches the light: a wide soft glow with a
    // bright core.
    for (final x in flares) {
      final c = Offset(size.width * x, 2);
      for (final (w, h, alpha) in [(70.0, 10.0, 0.6), (18.0, 4.0, 1.0)]) {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: w, height: h),
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(alpha: alpha),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCenter(center: c, width: w, height: w)),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiquidGlassEdgePainter old) =>
      old.radius != radius || old.rim != rim || old.flares != flares;
}
