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
      body: AquaBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 330,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _CurvedBottom(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Photo(kind.hero, icon: kind.icon),
                          const Scrim(top: true, strength: 0.35),
                          const Scrim(strength: 0.85),
                        ],
                      ),
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
                          style: AppText.display.copyWith(color: Colors.white),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
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
                      childAspectRatio: 0.82,
                      children: [
                        for (final c in kind.checks)
                          Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Photo(c.image, icon: c.icon),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.label,
                                style: AppText.label.copyWith(fontSize: 13),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tealTint,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(kind.icon, color: AppColors.teal),
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
                child: const Text('Request a guide'),
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
