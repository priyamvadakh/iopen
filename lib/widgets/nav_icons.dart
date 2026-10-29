import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Hand-drawn tab icons, for shapes the icon fonts don't have.
enum NavGlyph { house, webcam, wallet }

class NavItem {
  const NavItem(this.label, {this.icon, this.glyph});

  final String label;
  final IconData? icon;
  final NavGlyph? glyph;
}

/// Same tabs and icons as the app on TestFlight.
const navItems = [
  NavItem('Home', glyph: NavGlyph.house),
  NavItem('Sessions', glyph: NavGlyph.webcam),
  NavItem('Map', icon: Icons.public),
  NavItem('Wallet', glyph: NavGlyph.wallet),
  NavItem('Profile', icon: CupertinoIcons.person),
];

/// A tab's icon: from the icon font, or drawn.
class NavIcon extends StatelessWidget {
  const NavIcon(
    this.item, {
    super.key,
    required this.size,
    required this.color,
  });

  final NavItem item;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => item.glyph == null
      ? Icon(item.icon, size: size, color: color)
      : CustomPaint(
          size: Size.square(size),
          painter: _GlyphPainter(item.glyph!, color),
        );
}

/// Rounded outline icons matching the app: house, webcam and wallet.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final NavGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case NavGlyph.house:
        // Soft-cornered house with a short line for the door step.
        final r = s * 0.1;
        final path = Path()
          ..moveTo(s * 0.14, s * 0.46)
          ..lineTo(s * 0.5, s * 0.14)
          ..lineTo(s * 0.86, s * 0.46)
          ..lineTo(s * 0.86, s * 0.86 - r)
          ..quadraticBezierTo(s * 0.86, s * 0.86, s * 0.86 - r, s * 0.86)
          ..lineTo(s * 0.14 + r, s * 0.86)
          ..quadraticBezierTo(s * 0.14, s * 0.86, s * 0.14, s * 0.86 - r)
          ..close();
        canvas.drawPath(path, line);
        canvas.drawLine(
          Offset(s * 0.4, s * 0.7),
          Offset(s * 0.6, s * 0.7),
          line,
        );
      case NavGlyph.webcam:
        final head = Offset(s * 0.5, s * 0.42);
        canvas.drawCircle(head, s * 0.3, line);
        canvas.drawCircle(head, s * 0.11, line);
        canvas.drawLine(
          Offset(s * 0.5, s * 0.72),
          Offset(s * 0.5, s * 0.82),
          line,
        );
        canvas.drawLine(
          Offset(s * 0.28, s * 0.86),
          Offset(s * 0.72, s * 0.86),
          line,
        );
      case NavGlyph.wallet:
        // Rounded wallet with a curved flap over the top and a clasp line.
        final body = RRect.fromLTRBR(
          s * 0.12,
          s * 0.3,
          s * 0.88,
          s * 0.84,
          Radius.circular(s * 0.14),
        );
        canvas.drawRRect(body, line);
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.24, s * 0.3)
            ..quadraticBezierTo(s * 0.5, s * 0.06, s * 0.76, s * 0.3),
          line,
        );
        canvas.drawLine(
          Offset(s * 0.4, s * 0.5),
          Offset(s * 0.6, s * 0.5),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
