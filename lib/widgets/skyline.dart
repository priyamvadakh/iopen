import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Stylised low-poly city skyline. Dubai gets its landmarks; other cities
/// get a generated skyline.
class SkylinePainter extends CustomPainter {
  SkylinePainter({required this.cityId, required this.pulse});

  final String cityId;

  /// 0..1, drives the landmark pin pulse.
  final double pulse;

  static const _light = Color(0xFFA9D3D5);
  static const _mid = Color(0xFF7DBBBE);
  static const _dark = Color(0xFF4E9A9E);
  static const _deep = Color(0xFF2F7C80);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.66;

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD5ECEC), Color(0xFFF4FAFA)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.18),
      w * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Sea and shore.
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      Paint()..color = const Color(0xFFBFE0E1),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 7; i++) {
      final y = horizon + 14 + i * (h - horizon) / 7;
      final x = (i * 53) % (w * 0.6);
      canvas.drawLine(Offset(x, y), Offset(x + w * 0.18, y), wave);
    }
    final shore = Path()
      ..moveTo(0, horizon - 4)
      ..lineTo(w * 0.7, horizon - 4)
      ..lineTo(w * 0.64, horizon + 16)
      ..lineTo(0, horizon + 16)
      ..close();
    canvas.drawPath(shore, Paint()..color = const Color(0xFFDDEBE6));

    final pins = <({Offset at, String label})>[];
    if (cityId == 'dubai') {
      _paintDubai(canvas, w, horizon, pins);
    } else {
      _paintGeneric(canvas, w, horizon);
    }

    for (final pin in pins) {
      _paintPin(canvas, pin.at, pin.label);
    }
  }

  void _paintDubai(
    Canvas canvas,
    double w,
    double base,
    List<({Offset at, String label})> pins,
  ) {
    final h = base / 0.66;

    // Dubai Frame.
    final fx = w * 0.07, fw = w * 0.11, fh = h * 0.27;
    _prism(canvas, Rect.fromLTWH(fx, base - fh, fw * 0.24, fh));
    _prism(canvas, Rect.fromLTWH(fx + fw * 0.76, base - fh, fw * 0.24, fh));
    _prism(canvas, Rect.fromLTWH(fx, base - fh, fw, fh * 0.09));
    pins.add((at: Offset(fx + fw / 2, base - fh - 8), label: 'Dubai Frame'));

    // Dubai Marina cluster.
    final marina = [
      (0.22, 0.05, 0.30),
      (0.27, 0.045, 0.38),
      (0.315, 0.05, 0.33),
      (0.355, 0.04, 0.42),
      (0.395, 0.05, 0.28),
    ];
    for (final (x, bw, bh) in marina) {
      _prism(canvas, Rect.fromLTWH(w * x, base - h * bh, w * bw, h * bh));
    }
    _twisted(canvas, w * 0.43, base, w * 0.04, h * 0.36);
    pins.add((
      at: Offset(w * 0.355 + w * 0.02, base - h * 0.42 - 8),
      label: 'Marina',
    ));

    // Downtown fillers around the Burj Khalifa.
    for (final (x, bw, bh) in [
      (0.5, 0.04, 0.2),
      (0.6, 0.045, 0.24),
      (0.645, 0.035, 0.16),
    ]) {
      _prism(canvas, Rect.fromLTWH(w * x, base - h * bh, w * bw, h * bh));
    }

    // Burj Khalifa: stepped tiers then a spire.
    final cx = w * 0.565;
    final tiers = [
      (0.075, 0.13),
      (0.06, 0.1),
      (0.046, 0.09),
      (0.032, 0.07),
      (0.02, 0.05),
    ];
    var y = base;
    for (final (tw, th) in tiers) {
      final rect = Rect.fromLTWH(cx - w * tw / 2, y - h * th, w * tw, h * th);
      _prism(canvas, rect, light: const Color(0xFFC7E3E4), dark: _mid);
      y -= h * th;
    }
    final spireTop = y - h * 0.07;
    canvas.drawLine(
      Offset(cx, y),
      Offset(cx, spireTop),
      Paint()
        ..color = _dark
        ..strokeWidth = 2,
    );
    pins.add((at: Offset(cx, spireTop - 8), label: 'Burj Khalifa'));

    // Burj Al Arab on its island.
    final bx = w * 0.84;
    final island = Rect.fromCenter(
      center: Offset(bx + w * 0.02, base + 12),
      width: w * 0.16,
      height: 10,
    );
    canvas.drawOval(island, Paint()..color = const Color(0xFFDDEBE6));
    final top = base - h * 0.38;
    final sail = Path()
      ..moveTo(bx, base + 8)
      ..lineTo(bx, top)
      ..quadraticBezierTo(
        bx + w * 0.11,
        base - h * 0.2,
        bx + w * 0.075,
        base + 8,
      )
      ..close();
    canvas.drawPath(sail, Paint()..color = Colors.white);
    final facet = Paint()
      ..color = _light
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      canvas.drawLine(
        Offset(bx, top + (base - top) * t),
        Offset(
          bx + w * 0.06 * math.sin(t * math.pi * 0.9) + w * 0.012,
          top + (base - top) * t,
        ),
        facet,
      );
    }
    canvas.drawPath(
      sail,
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(bx - 4, top - 4),
      Offset(bx, base + 8),
      Paint()
        ..color = _deep
        ..strokeWidth = 2.5,
    );
    pins.add((at: Offset(bx + w * 0.02, top - 12), label: 'Burj Al Arab'));
  }

  void _paintGeneric(Canvas canvas, double w, double base) {
    final h = base / 0.66;
    final rnd = math.Random(cityId.hashCode);
    var x = w * 0.04;
    while (x < w * 0.66) {
      final bw = w * (0.04 + rnd.nextDouble() * 0.04);
      final bh = h * (0.12 + rnd.nextDouble() * 0.3);
      _prism(canvas, Rect.fromLTWH(x, base - bh, bw, bh));
      x += bw + w * 0.006;
    }
  }

  /// Two-tone block: lit left face, shaded right face, faint window bands.
  void _prism(
    Canvas canvas,
    Rect r, {
    Color light = _light,
    Color dark = _mid,
  }) {
    final split = r.left + r.width * 0.55;
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.top, split, r.bottom),
      Paint()..color = light,
    );
    canvas.drawRect(
      Rect.fromLTRB(split, r.top, r.right, r.bottom),
      Paint()..color = dark,
    );
    final band = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var y = r.top + 6; y < r.bottom - 4; y += 9) {
      canvas.drawRect(Rect.fromLTWH(r.left + 2, y, r.width - 4, 1.2), band);
    }
  }

  /// Cayan-style twisted tower drawn as offset stacked slabs.
  void _twisted(Canvas canvas, double x, double base, double bw, double bh) {
    const slabs = 14;
    for (var i = 0; i < slabs; i++) {
      final shift = math.sin(i / slabs * math.pi) * bw * 0.25;
      final sh = bh / slabs;
      _prism(
        canvas,
        Rect.fromLTWH(x + shift, base - sh * (i + 1), bw, sh + 0.5),
        light: _mid,
        dark: _dark,
      );
    }
  }

  void _paintPin(Canvas canvas, Offset at, String label) {
    canvas.drawCircle(
      at,
      5 + 10 * pulse,
      Paint()..color = AppColors.teal.withValues(alpha: 0.3 * (1 - pulse)),
    );
    canvas.drawCircle(at, 6, Paint()..color = Colors.white);
    canvas.drawCircle(at, 4, Paint()..color = AppColors.teal);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: AppText.small.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromCenter(
      center: at - Offset(0, 20),
      width: tp.width + 16,
      height: tp.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    tp.paint(canvas, box.topLeft + const Offset(8, 4));
  }

  @override
  bool shouldRepaint(SkylinePainter old) =>
      old.pulse != pulse || old.cityId != cityId;
}
