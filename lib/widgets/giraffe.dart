import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Brand colours taken from the iOpen app icon.
abstract final class GiraffeColors {
  static const tile = Color(0xFF7CC5C1);
  static const spot = Color(0xFF4E8F8C);
  static const ink = Color(0xFF0E1214);
}

/// The iOpen app icon: a giraffe head on an aqua, spotted tile.
class GiraffeIcon extends StatelessWidget {
  const GiraffeIcon({super.key, this.size = 40, this.rounded = true});

  final double size;

  /// Rounded tile corners; off for launcher icons the OS masks itself.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: GiraffeIconPainter(rounded: rounded)),
    );
  }
}

class GiraffeIconPainter extends CustomPainter {
  const GiraffeIconPainter({this.rounded = true});

  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 100×100 design space.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    const tile = Rect.fromLTWH(0, 0, 100, 100);
    final clip = rounded
        ? (Path()..addRRect(
            RRect.fromRectAndRadius(tile, const Radius.circular(23)),
          ))
        : (Path()..addRect(tile));
    canvas.clipPath(clip);
    canvas.drawRect(tile, Paint()..color = GiraffeColors.tile);
    _spots(canvas);
    _giraffe(canvas);
    canvas.restore();
  }

  /// Leaf-shaped spots scattered across the tile.
  void _spots(Canvas canvas) {
    final rnd = math.Random(11);
    final paint = Paint()..color = GiraffeColors.spot;
    for (var row = 0; row < 10; row++) {
      final y = 4.0 + row * 10.5;
      // Offset every other row so the spots don't line up.
      for (var x = row.isOdd ? 8.5 : 3.0; x < 100; x += 11) {
        final cx = x + rnd.nextDouble() * 4 - 2;
        final cy = y + rnd.nextDouble() * 4 - 2;
        final w = 5.5 + rnd.nextDouble() * 3;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rnd.nextDouble() * math.pi);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.58),
          paint,
        );
        canvas.restore();
      }
    }
  }

  void _giraffe(Canvas canvas) {
    final ink = Paint()..color = GiraffeColors.ink;

    // Neck, widening towards the bottom edge.
    final neck = Path()
      ..moveTo(42.5, 62)
      ..lineTo(57.5, 62)
      ..lineTo(66, 100)
      ..lineTo(34, 100)
      ..close();
    canvas.drawPath(neck, ink);
    // Reticulated patches on the neck.
    final patch = Paint()..color = GiraffeColors.tile;
    for (final pts in const [
      [Offset(41.5, 74), Offset(48, 72), Offset(47, 82), Offset(40.5, 84)],
      [Offset(51, 72), Offset(58.5, 74), Offset(59.5, 84), Offset(52.5, 82)],
      [
        Offset(44, 87),
        Offset(49.5, 85.5),
        Offset(55.5, 87),
        Offset(54.5, 96),
        Offset(45, 96),
      ],
      [Offset(38.5, 88), Offset(42, 87.5), Offset(41.5, 97), Offset(37, 97)],
      [Offset(57.5, 87.5), Offset(61.5, 88), Offset(63, 97), Offset(58.5, 97)],
    ]) {
      canvas.drawPath(Path()..addPolygon(pts, true), patch);
    }

    // Ossicones with rounded knobs.
    final horn = Paint()
      ..color = GiraffeColors.ink
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(44.5, 30), const Offset(41.5, 13), horn);
    canvas.drawLine(const Offset(55.5, 30), const Offset(58.5, 13), horn);
    canvas.drawCircle(const Offset(41.2, 11.5), 4, ink);
    canvas.drawCircle(const Offset(58.8, 11.5), 4, ink);

    // Ears pointing outwards.
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(50 + side * 16, 33);
      canvas.rotate(side * -0.18);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(side * 6, 0), width: 18, height: 8),
        ink,
      );
      canvas.restore();
    }

    // Head: broad at the eyes, tapering to a rounded muzzle.
    final head = Path()
      ..moveTo(40, 26)
      ..quadraticBezierTo(50, 22, 60, 26)
      ..quadraticBezierTo(64.5, 36, 63, 44)
      ..quadraticBezierTo(60, 58, 57.5, 66)
      ..quadraticBezierTo(50, 74, 42.5, 66)
      ..quadraticBezierTo(40, 58, 37, 44)
      ..quadraticBezierTo(35.5, 36, 40, 26)
      ..close();
    canvas.drawPath(head, ink);

    // Eyes sit just outside the head outline, as on the icon.
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(35.2, 41.5), 1.6, ink);
    canvas.drawCircle(const Offset(64.8, 41.5), 1.6, ink);
    canvas.drawCircle(const Offset(35.2, 41.2), 0.8, eye);
    canvas.drawCircle(const Offset(64.8, 41.2), 0.8, eye);
  }

  @override
  bool shouldRepaint(GiraffeIconPainter oldDelegate) =>
      oldDelegate.rounded != rounded;
}
