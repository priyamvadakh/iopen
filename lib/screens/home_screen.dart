import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Drives the staggered fade-in of each section.
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What do you want to see?',
              style: AppText.display.copyWith(fontSize: 25),
            ),
            const SizedBox(height: 14),
            _SearchField(onTap: () => context.push('/explore')),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: IntentChips(onTap: (k) => context.push('/inspect/${k.name}')),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                'See before you decide',
                subtitle: 'Avoid surprises. Inspect with a local Guide live.',
              ),
            ),
            SizedBox(height: 6),
            _DecideCarousel(),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: _TrustStrip(),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                'Recent live sessions',
                subtitle: 'What other travellers saw this week.',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 214,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: recentSessions.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _SessionCard(session: recentSessions[i]),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          children: [
            SectionHeader(
              'Popular now',
              onSeeAll: () => context.push('/explore'),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final id in popularCityIds)
                  CityCard(
                    city: cityById(id)!,
                    onTap: () => context.push('/city/$id'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: AquaBackground(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
          ),
          children: [
            _GlobeHero(onExpand: () => context.go('/map')),
            // The content sheet overlaps the hero with rounded corners.
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0x00FFFFFF)],
                    stops: [0, 0.4],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      _Reveal(
                        animation: _entrance,
                        index: i,
                        child: sections[i],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and slides a section in, slightly after the one above it.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = math.min(0.55, index * 0.08);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, start + 0.45, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.teal,
              ),
              const SizedBox(width: 6),
              Text('AED 50', style: AppText.label.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.muted, size: 22),
              const SizedBox(width: 10),
              Text('Search a city, address or listing', style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3D tilted card carousel ("See Before You Decide" in the reference).
class _DecideCarousel extends StatefulWidget {
  const _DecideCarousel();

  @override
  State<_DecideCarousel> createState() => _DecideCarouselState();
}

class _DecideCarouselState extends State<_DecideCarousel> {
  static const _kinds = [
    InspectKind.place,
    InspectKind.car,
    InspectKind.property,
    InspectKind.hotel,
  ];
  final _controller = PageController(viewportFraction: 0.58, initialPage: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final page =
              _controller.hasClients && _controller.position.haveDimensions
              ? _controller.page!
              : 1.0;
          return PageView.builder(
            controller: _controller,
            itemCount: _kinds.length,
            itemBuilder: (context, i) {
              final delta = i - page;
              final shrink = 1 - math.min(1, delta.abs()) * 0.14;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(-delta * 0.5)
                ..scaleByDouble(shrink, shrink, 1, 1);
              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: Opacity(
                  opacity: 1 - math.min(1, delta.abs()) * 0.3,
                  child: _DecideCard(
                    kind: _kinds[i],
                    active: delta.abs() < 0.5,
                    onTap: () => context.push('/inspect/${_kinds[i].name}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DecideCard extends StatelessWidget {
  const _DecideCard({
    required this.kind,
    required this.active,
    required this.onTap,
  });

  final InspectKind kind;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(kind.hero, icon: kind.icon),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(kind.icon, size: 20, color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.title,
                        style: AppText.label.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                kind.subtitle,
                                style: AppText.small,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: active ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const _GlossyArrow(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlossyArrow extends StatelessWidget {
  const _GlossyArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5BAEB4), AppColors.teal, AppColors.tealDark],
        ),
      ),
      child: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
    );
  }
}

/// Full-width globe at the top of Home, with the greeting and headline.
class _GlobeHero extends StatelessWidget {
  const _GlobeHero({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 470,
      child: SpaceBackdrop(
        radius: 0,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: top + 118,
              bottom: 84,
              child: Globe(
                insideScrollView: true,
                onExpand: onExpand,
                onCityTap: (c) => context.push('/city/${c.id}'),
              ),
            ),
            Positioned(
              top: top + 10,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hi Priya 👋',
                      style: AppText.section.copyWith(color: Colors.white),
                    ),
                  ),
                  _WalletChip(onTap: () => context.go('/wallet')),
                ],
              ),
            ),
            Positioned(
              top: top + 50,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See it live.',
                      style: AppText.display.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      'Know before you go.',
                      style: AppText.display.copyWith(
                        color: const Color(0xFF8EE3E8),
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: IgnorePointer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulseDot(),
                          const SizedBox(width: 8),
                          Text(
                            '$totalGuidesOnline Guides online now',
                            style: AppText.label.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap a pin · pinch with two fingers to zoom',
                      style: AppText.small.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green "online" dot with a soft ripple.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * _c.value,
              height: 6 + 8 * _c.value,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80)
                    .withValues(alpha: 0.5 * (1 - _c.value)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String strong, String rest) => Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: strong,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  TextSpan(text: '\n$rest'),
                ],
              ),
              style: AppText.small.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          item(Icons.star_rounded, '4.8', 'average'),
          item(Icons.videocam_outlined, '2,300', 'sessions'),
          item(Icons.verified_user_outlined, 'Refund', "if Guide doesn't join"),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final RecentSession session;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Photo(session.image, icon: session.kind.icon),
                  const Scrim(strength: 0.45),
                  const Center(child: _PlayBadge(size: 40)),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _DarkChip('${session.minutes} min'),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _DarkChip(session.kind.label),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.place,
            style: AppText.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GuideAvatar(session.guide, size: 24),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  session.guide.name,
                  style: AppText.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Rating(session.guide.rating),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: AppColors.teal,
        size: size * 0.6,
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppText.small.copyWith(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Photo card with the city and country always visible.
class CityCard extends StatelessWidget {
  const CityCard({super.key, required this.city, required this.onTap});

  final City city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${city.name}, ${city.country}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Photo(city.image, icon: Icons.location_city_outlined),
                const Scrim(),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        style: AppText.label.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${city.country} · ${city.guidesOnline} online',
                        style: AppText.small.copyWith(color: Colors.white),
                      ),
                    ],
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
