import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/onboarding_state.dart';
import '../app/theme.dart';
import '../data/content.dart';
import '../data/user_store.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';
import 'globe_screen.dart';

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
  );

  @override
  void initState() {
    super.initState();
    // Sections rise in as the onboarding globe lands.
    if (onboardingActive.value) {
      onboardingActive.addListener(_onOnboarding);
    } else {
      _entrance.forward();
    }
  }

  void _onOnboarding() {
    if (!onboardingActive.value) {
      onboardingActive.removeListener(_onOnboarding);
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    onboardingActive.removeListener(_onOnboarding);
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
      // Picks up where the user left off.
      ValueListenableBuilder(
        valueListenable: UserStore.instance.lastViewed,
        builder: (context, last, _) => last == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ContinueCard(last: last),
              ),
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
        child: _HowItWorks(),
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
              offset: const Offset(0, -HomeHeroLayout.sheetOverlap),
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
              Expanded(
                child: Text(
                  'Search a city, address or listing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body,
                ),
              ),
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

/// Geometry of the Home globe hero, shared with the onboarding landing.
abstract final class HomeHeroLayout {
  static const height = 540.0;

  /// How far the content sheet rides up over the hero.
  static const sheetOverlap = 28.0;
  static const globeLat = 20.0;
  static const globeLng = 52.0;

  /// The globe nearly fills the width and sits low, its bottom tucked
  /// under the sheet; zooming in opens the whole globe.
  static double globeRadius(Size screen) => screen.width * 0.47;

  /// Where the hero stops being visible (the sheet's top edge).
  static double visibleBottom(double topInset) =>
      topInset + height - sheetOverlap;

  /// The globe's paint box in screen coordinates (page scrolled to the top);
  /// GlobePainter draws a radius of 0.4 × its shorter side.
  static Rect globeRect(Size screen, double topInset) {
    final r = globeRadius(screen);
    return Rect.fromCenter(
      center: Offset(screen.width / 2, visibleBottom(topInset) - r * 0.72),
      width: r / 0.4,
      height: r / 0.4,
    );
  }
}

/// Full-width globe at the top of Home, with the greeting and headline.
class _GlobeHero extends StatefulWidget {
  const _GlobeHero({required this.onExpand});

  final VoidCallback onExpand;

  @override
  State<_GlobeHero> createState() => _GlobeHeroState();
}

class _GlobeHeroState extends State<_GlobeHero> {
  /// Whether the globe keeps turning through the live cities.
  final _touring = ValueNotifier(true);

  @override
  void dispose() {
    _touring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onExpand = widget.onExpand;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + HomeHeroLayout.height,
      child: SpaceBackdrop(
        radius: 0,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: HomeHeroLayout.globeRect(MediaQuery.sizeOf(context), top),
              child: Globe(
                initialLng: HomeHeroLayout.globeLng,
                insideScrollView: true,
                showZoomControls: false,
                spin: _touring,
                onZoomIn: (lat, lng) =>
                    showFullGlobe(context, lat: lat, lng: lng),
                onCityTap: (c) => context.push('/city/${c.id}'),
              ),
            ),
            // The globe's box is wider than the screen, so the controls
            // live here instead.
            Positioned(
              right: 12,
              top: top + 250,
              child: ZoomControls(
                onZoomIn: () => showFullGlobe(context),
                onZoomOut: null,
                onExpand: onExpand,
              ),
            ),
            Positioned(
              left: 16,
              bottom: HomeHeroLayout.sheetOverlap + 14,
              child: _TourChip(touring: _touring),
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
              left: 20,
              top: top + 138,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.last});

  final LastViewed last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/city/${last.city.id}?area=${last.area.id}&intent=${last.kind.name}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Photo(last.area.image, icon: last.kind.icon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue exploring',
                      style: AppText.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      last.kind.placeTitle(last.area.name),
                      style: AppText.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${last.city.guidesOnline} Guides online in '
                      '${last.city.name}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sets expectations up front: what happens, how fast, and when you pay.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.place_outlined, 'Pick a place', 'Choose what to check'),
      (Icons.videocam_outlined, 'Guide goes live', 'Usually within 5 min'),
      (Icons.verified_user_outlined, 'Pay after', 'Only once they join'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('How it works', style: AppText.label)),
              const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
              const SizedBox(width: 2),
              Text(
                '4.8 · 2,300 sessions',
                style: AppText.small.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.tealTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].$1,
                          size: 20,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${i + 1}. ${steps[i].$2}',
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        steps[i].$3,
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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

/// Glass chip that pauses or resumes the globe's tour of live cities.
class _TourChip extends StatelessWidget {
  const _TourChip({required this.touring});

  final ValueNotifier<bool> touring;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: touring,
      builder: (context, on, _) => Semantics(
        button: true,
        toggled: on,
        child: GestureDetector(
          onTap: () => touring.value = !on,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.near_me_outlined : Icons.pause_circle_outline,
                  size: 17,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 8),
                Text(
                  on ? 'Touring live cities' : 'Paused · tap to tour',
                  style: AppText.label.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
