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
      body: AquaBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, top + 8, 20, 28),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: AppBackButton(),
            ),
            const SizedBox(height: 16),
            Text('Explore by Country', style: AppText.display),
            const SizedBox(height: 6),
            Text(
              widget.kind == null
                  ? 'Find a local Guide and see the reality before you go.'
                  : 'Where is the ${widget.kind!.label.toLowerCase()} you want to check?',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: AppText.label.copyWith(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search a city or country',
                hintStyle: AppText.body,
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(
                    color: AppColors.teal,
                    width: 1.5,
                  ),
                ),
              ),
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
                    Text('Try another city or country.', style: AppText.body),
                  ],
                ),
              ),
            for (final s in sections) ...[
              const SizedBox(height: 28),
              SectionHeader(s.region.name, subtitle: s.region.subtitle),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.74,
                children: [
                  for (final c in s.cities)
                    _CountryCard(
                      city: c,
                      onTap: () => context.push(
                        widget.kind == null
                            ? '/city/${c.id}'
                            : '/city/${c.id}?intent=${widget.kind!.name}',
                      ),
                    ),
                ],
              ),
            ],
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Photo(city.image, icon: Icons.location_city_outlined),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.country,
                          style: AppText.label.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          city.name,
                          style: AppText.small.copyWith(fontSize: 12),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.tealTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
