import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';

/// "Buying a Car?", "Booking a Hotel?" and friends.
class InspectScreen extends StatelessWidget {
  const InspectScreen({super.key, required this.kind});

  final InspectKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CrystalBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 340,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _CurvedBottom(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Photo(kind.hero, icon: kind.icon),
                          const Scrim(top: true, strength: 0.25),
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00072A33),
                                    Color(0xCC072A33),
                                  ],
                                  stops: [0.35, 1],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Glowing glass rim along the curved edge.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _RimPainter()),
                    ),
                  ),
                  const TopBackButton(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.title,
                          style: AppText.display.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kind.subtitle,
                          style: AppText.body.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Glass(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      kind.checksTitle,
                      subtitle: kind.checksSubtitle,
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.9,
                      children: [
                        for (final c in kind.checks)
                          Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Glass.rim,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F1B3D)
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Photo(c.image, icon: c.icon),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.label,
                                style: AppText.label.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Glass(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 150,
                        child: ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Colors.transparent, Colors.white],
                            stops: [0, 0.5],
                          ).createShader(r),
                          blendMode: BlendMode.dstIn,
                          child: Image.asset(
                            'assets/images/decor_globe_card.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 110, 16),
                        child: Row(
                          children: [
                            Glass(
                              radius: 14,
                              glow: 0.6,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(kind.icon, color: AppColors.teal),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(kind.infoTitle, style: AppText.label),
                                  const SizedBox(height: 2),
                                  Text(kind.infoBody, style: AppText.small),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: GlossyButton(
                onPressed: () => context.push('/explore?intent=${kind.name}'),
                child: const Text('Request a Guide'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedBottom extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 48)
    ..quadraticBezierTo(
      size.width / 2,
      size.height + 24,
      size.width,
      size.height - 48,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Bright cyan line glowing along the hero's curved bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _CurvedBottom().getClip(size);
    // Only the curve: skip the straight sides and top.
    final metric = path.computeMetrics().first;
    final curve = Path();
    final h = size.height;
    for (var d = 0.0; d < metric.length; d += 2) {
      final t = metric.getTangentForOffset(d)!.position;
      if (t.dy > h - 60) {
        curve.moveTo(t.dx, t.dy);
        curve.lineTo(t.dx + 0.1, t.dy);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = const Color(0xFF7FF3F6).withValues(alpha: 0.55)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => false;
}
