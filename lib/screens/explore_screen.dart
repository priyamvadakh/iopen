import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.kind});

  /// Set when arriving from a "Request a guide" button.
  final InspectKind? kind;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _query = '';

  bool _matches(City c, Region r) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      c.name,
      c.country,
      c.area,
      r.name,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final sections = [
      for (final r in regions)
        (
          region: r,
          cities: [
            for (final id in r.cityIds)
              if (_matches(cityById(id)!, r)) cityById(id)!,
          ],
        ),
    ].where((s) => s.cities.isNotEmpty).toList();

    return Scaffold(
      body: CrystalBackground(
        child: Stack(
          children: [
            Positioned(top: 0, right: 0, child: GlobeCorner(width: top + 150)),
            ListView(
              padding: EdgeInsets.fromLTRB(16, top + 12, 16, 28),
              children: [
                PageHeader(
                  title: 'Explore by Country',
                  subtitle: widget.kind == null
                      ? 'Find a local Guide and see the reality before you go.'
                      : 'Where is the ${widget.kind!.label.toLowerCase()} you '
                            'want to check?',
                ),
                const SizedBox(height: 16),
                GlassSearchField(
                  hint: 'Search by keyword',
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.travel_explore,
                          size: 40,
                          color: AppColors.teal,
                        ),
                        const SizedBox(height: 10),
                        Text('No Guides there yet', style: AppText.section),
                        const SizedBox(height: 4),
                        Text(
                          'Try another city or country.',
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                for (final s in sections) ...[
                  const SizedBox(height: 22),
                  SectionHeader(s.region.name, subtitle: s.region.subtitle),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: [
                      for (final c in s.cities)
                        _CountryCard(
                          city: c,
                          onTap: () => context.push(
                            widget.kind == null
                                ? '/country/${c.id}'
                                : '/country/${c.id}?intent=${widget.kind!.name}',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({required this.city, required this.onTap});

  final City city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${city.country}, ${city.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          radius: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Photo(city.coverImage, icon: Icons.location_city_outlined),
                // Glass label sheet with a wavy top edge.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 62,
                  child: CustomPaint(
                    // Bright glass edge along the wave.
                    foregroundPainter: const _WaveRim(),
                    child: ClipPath(
                      clipper: const _WaveTop(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: AppColors.dark
                                ? Glass.fill
                                : [
                                    Colors.white.withValues(alpha: 0.97),
                                    const Color(0xFFF2FBFB),
                                    const Color(0xFFD9F3F5),
                                  ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 16, 6, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      city.country,
                                      style: AppText.label.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      city.name,
                                      style: AppText.small.copyWith(
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const ArrowChip(size: 26),
                            ],
                          ),
                        ),
                      ),
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

Path _wave(Size size) {
  final w = size.width;
  return Path()
    ..moveTo(0, 12)
    ..cubicTo(w * 0.3, 2, w * 0.62, 18, w, 2);
}

/// Gentle wave along the top of the card's label sheet.
class _WaveTop extends CustomClipper<Path> {
  const _WaveTop();

  @override
  Path getClip(Size size) => _wave(size)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_WaveTop oldClipper) => false;
}

/// White highlight with a soft aqua glow on the label sheet's wavy edge.
class _WaveRim extends CustomPainter {
  const _WaveRim();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _wave(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF8FEAEE).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_WaveRim oldDelegate) => false;
}
