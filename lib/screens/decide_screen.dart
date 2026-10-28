import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';

/// "See Before You Decide": every kind of inspection as a glass card.
class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final q = _query.trim().toLowerCase();
    final kinds = [
      for (final k in InspectKind.decideOrder)
        if (q.isEmpty ||
            [
              k.title,
              k.label,
              k.cardSubtitle,
            ].any((s) => s.toLowerCase().contains(q)))
          k,
    ];

    return Scaffold(
      body: CrystalBackground(
        child: Stack(
          children: [
            Positioned(top: 0, right: 0, child: GlobeCorner(width: top + 150)),
            ListView(
              padding: EdgeInsets.fromLTRB(16, top + 12, 16, 28),
              children: [
                const PageHeader(
                  title: 'See Before You Decide',
                  subtitle:
                      'Avoid surprises. Inspect with a local Guide through a '
                      'live video.',
                ),
                const SizedBox(height: 16),
                GlassSearchField(
                  hint: 'Search by keyword',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 16),
                if (kinds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'Nothing matches “$_query” yet.',
                      textAlign: TextAlign.center,
                      style: AppText.body,
                    ),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [
                    for (final k in kinds)
                      KindCard(
                        kind: k,
                        onTap: () => context.push('/inspect/${k.name}'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo with a wavy glass edge, the category icon, title and an arrow.
class KindCard extends StatelessWidget {
  const KindCard({super.key, required this.kind, required this.onTap});

  final InspectKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: kind.title,
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          radius: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      ClipPath(
                        clipper: const WaveClipper(depth: 16),
                        child: Photo(kind.card, icon: kind.icon),
                      ),
                      Positioned(
                        left: 10,
                        bottom: -14,
                        child: Glass(
                          shape: BoxShape.circle,
                          glow: 0.8,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              kind.icon,
                              size: 21,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                kind.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                kind.cardSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.small.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const ArrowChip(size: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
