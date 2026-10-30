import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/onboarding_state.dart';
import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/globe.dart';
import '../widgets/liquid_glass.dart';
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
    duration: const Duration(milliseconds: 1800),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: GlassSearchField(
          hint: 'Search for a location',
          onTap: () => context.push('/explore'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(
                'See Before You Decide',
                centered: true,
                onSeeAll: () => context.push('/decide'),
              ),
            ),
            const SizedBox(height: 12),
            const _DecideCarousel(),
          ],
        ),
      ),
    ];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: ColoredBox(
        // Plain white, so the cards and the globe's glow do the colour.
        color: AppColors.dark ? AppColors.background : Colors.white,
        child: Stack(
          children: [
            ListView(
              // Room for the pinned globe section below.
              padding: EdgeInsets.only(
                bottom:
                    bottomInset +
                    _CountryGlobe.pinnedHeight +
                    _PinnedCountries.lift,
              ),
              children: [
                SizedBox(height: _flipTop(context)),
                for (var i = 0; i < sections.length; i++)
                  _Reveal(animation: _entrance, index: i, child: sections[i]),
              ],
            ),
            // Pinned to the bottom so the globe is always on screen; the
            // page scrolls under it. Not faded in: the intro's globe lands
            // right on it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PinnedCountries(
                reveal: _entrance,
                bottomInset: bottomInset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Room above the flip book's search bar, under the status bar.
double _flipTop(BuildContext context) =>
    math.max(MediaQuery.paddingOf(context).top, 20.0) + 14;

/// "Explore by Country" header over the globe, on a backdrop that fades in
/// from the page above so cards scroll softly under it.
class _PinnedCountries extends StatelessWidget {
  const _PinnedCountries({required this.reveal, required this.bottomInset});

  /// Shifts the globe up (positive) or down (negative) against the tab bar.
  static const lift = -26.0;

  final Animation<double> reveal;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    // Plain white behind the section, so the globe's glow does the colour.
    final page = AppColors.dark ? AppColors.background : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [page.withValues(alpha: 0), page, page],
          stops: const [0, 0.06, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: CurvedAnimation(
              parent: reveal,
              curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: SectionHeader(
                'Explore by Country',
                centered: true,
                onSeeAll: () => context.push('/explore'),
              ),
            ),
          ),
          SizedBox(
            height: _CountryGlobe.height + lift + bottomInset,
            child: _CountryGlobe(reveal: reveal),
          ),
        ],
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

/// Geometry shared with the onboarding landing.
abstract final class HomeHeroLayout {
  /// Hero height below the status bar.
  static const height = 176.0;

  /// How far the content sheet rides up over the hero.
  static const sheetOverlap = 24.0;
  static const globeLat = 26.0;
  static const globeLng = 55.3; // facing Dubai

  /// Only the globe's top shows on Home, so it tilts back to put Europe,
  /// the Gulf and Africa across that cap.
  static const capLat = -22.0;
  static const capLng = 38.0;

  /// Used until Home has measured where its globe really is.
  static Rect fallbackGlobeRect(Size screen) {
    final r = screen.width * 0.62;
    return Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height - 150 + r),
      width: r / 0.4,
      height: r / 0.4,
    );
  }
}

/// "See Before You Decide" flip book: the cards flip up and down over a
/// hinge, like a flip calendar.
class _DecideCarousel extends StatefulWidget {
  const _DecideCarousel();

  @override
  State<_DecideCarousel> createState() => _DecideCarouselState();
}

/// One page of the flip book: a kind of check, or a country.
class _FlipPage {
  const _FlipPage({this.kind, this.city});

  final InspectKind? kind;
  final City? city;

  String get label =>
      city == null ? kind!.title : '${city!.country}, ${city!.name}';

  String get route =>
      city == null ? '/inspect/${kind!.name}' : '/country/${city!.id}';
}

class _DecideCarouselState extends State<_DecideCarousel> {
  Timer? _auto;

  static const _kinds = [
    InspectKind.mall,
    InspectKind.place,
    InspectKind.car,
    InspectKind.property,
    InspectKind.hotel,
    InspectKind.restaurant,
    InspectKind.venue,
    InspectKind.tourist,
  ];

  static final _countries = [
    for (final r in regions)
      for (final id in r.cityIds) cityById(id)!,
  ];

  /// Every kind of check, then every country.
  static final _pages = [
    for (final k in _kinds) _FlipPage(kind: k),
    for (final c in _countries) _FlipPage(city: c),
  ];

  // One swipe of this height moves the deck by one card.
  final _controller = PageController(viewportFraction: 0.37);

  @override
  void initState() {
    super.initState();
    // Flips to the next card on its own, round and round.
    _auto = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!_controller.hasClients) return;
      final page = (_controller.page ?? 0).round();
      _controller.animateToPage(
        (page + 1) % _pages.length,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Page height, sized in [build] so the book fills the room between
  /// the section title and the country globe; the spine runs just under
  /// the top page.
  double _pageH = 216;
  double get _spineY => _pageH + 4;
  double get _bookH => _pageH * 2 + 18;

  /// Page width, as a share of the row.
  static const _pageW = 0.86;

  /// Every page hinges on one spine across the middle. Pages still to come
  /// stand above it, leaning back a little more each; the page being
  /// turned swings over the spine, and turned pages hang below it showing
  /// their backs, upside down.
  Widget _flipCard(int i, double delta, double w) {
    final d = delta.abs();
    if (d > 3.2) return const Positioned(left: 0, top: 0, child: SizedBox());
    // 0 stands the page up above the spine; pi hangs it straight down.
    final double angle;
    // A gentle lean, so the standing page reads flat and roomy.
    if (delta >= 0) {
      angle = -0.06 - math.min(delta, 2.5) * 0.12;
    } else if (delta > -1) {
      angle = -0.06 + Curves.easeInOut.transform(-delta) * (math.pi - 0.02);
    } else {
      angle = math.pi - 0.14 - math.min(d - 1, 2) * 0.14;
    }
    // Darkest when edge-on to the light, half way over.
    final shade =
        (math.sin(angle.clamp(0.0, math.pi)) * 0.4 +
                (delta > 0 ? math.min(delta, 2.0) * 0.08 : 0))
            .clamp(0.0, 0.5);
    final page = _glassPage(i);
    return Positioned(
      left: 0,
      right: 0,
      top: _spineY - _pageH,
      height: _pageH,
      child: Center(
        child: SizedBox(
          width: w,
          height: _pageH,
          child: Opacity(
            opacity: (1 - math.max(0.0, d - 2.4)).clamp(0.0, 1.0).toDouble(),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0013)
                ..rotateX(angle),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFF0F1B3D).withValues(alpha: shade),
                  BlendMode.srcATop,
                ),
                // Past half way the page shows its other side, drawn the
                // right way up rather than mirrored.
                child: angle > math.pi / 2
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationX(math.pi),
                        child: page,
                      )
                    : page,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A flip page with a polished crystal finish: a clear-coat glare,
  /// luminous rims, a glossy top reflection and twinkling sparkles. The
  /// half-pages are short, so their text is smaller.
  Widget _glassPage(int i) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F1B3D).withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF3CC7D0).withValues(alpha: 0.28),
          blurRadius: 26,
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _FlipPageCard(page: _pages[i], compact: true),
        const IgnorePointer(
          child: CustomPaint(painter: _CrystalCardPainter(radius: 20)),
        ),
        const GlassSparkles(
          radius: 20,
          spots: [
            SparkleSpot(0.22, 0, 0, 3, 14, 0.3),
            SparkleSpot(0, -3, 0.46, 5, 10, 1.4),
            SparkleSpot(0.82, 0, 1, -2, 12, 2.1),
          ],
        ),
      ],
    ),
  );

  void _step(int by) {
    final page = (_controller.page ?? 0).round() + by;
    _controller.animateToPage(
      page.clamp(0, _pages.length - 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Fills what's left between the section title and the pinned country
    // globe: search 54 + 8 + 22, title 32 + 12 and book frame 18; the fade
    // above the globe overlaps the book a little.
    final globe = _CountryGlobe.pinnedHeight + _PinnedCountries.lift;
    final top = _flipTop(context);
    _pageH = ((mq.size.height - top - mq.padding.bottom - 136 - globe) / 2)
        .clamp(100.0, 236.0);
    return SizedBox(
      height: _bookH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Clear glass slate behind both the standing and turned page.
          if (!AppColors.dark)
            const Positioned.fill(
              top: -6,
              child: FractionallySizedBox(
                widthFactor: 0.95,
                child: IgnorePointer(
                  child: CustomPaint(painter: _GlassSlatePainter()),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final page =
                    _controller.hasClients &&
                        _controller.position.haveDimensions
                    ? _controller.page!
                    : 0.0;
                // Farthest first, so the centre card paints on top.
                final order = List.generate(
                  _pages.length,
                  (i) => i,
                )..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final i in order)
                      _flipCard(i, i - page, constraints.maxWidth * _pageW),
                    // The glossy glass spine the pages turn on.
                    Positioned(
                      left: constraints.maxWidth * 0.03,
                      right: constraints.maxWidth * 0.03,
                      top: _spineY - 2.5,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFFB7FFF4)),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0x66FFFFFF),
                              Colors.white,
                              Color(0xFFC6F7F2),
                              Colors.white,
                              Color(0x66FFFFFF),
                            ],
                            stops: [0, 0.3, 0.55, 0.75, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3CC7D0)
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Invisible pages on top take the up and down swipes and taps.
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: _pages.length,
            itemBuilder: (context, i) => Semantics(
              button: true,
              label: _pages[i].label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(_pages[i].route),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: _spineY - 18,
            child: GlassIconButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Previous',
              size: 36,
              onPressed: () => _step(-1),
            ),
          ),
          Positioned(
            right: 6,
            top: _spineY - 18,
            child: GlassIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Next',
              size: 36,
              onPressed: () => _step(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// A flip-book page: a check type, or a country with its live Guides.
class _FlipPageCard extends StatelessWidget {
  const _FlipPageCard({required this.page, this.compact = false});

  final _FlipPage page;

  /// Smaller text, for the vertical flip book's short half-pages.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final city = page.city;
    if (city == null) {
      return _BentoTile(
        kind: page.kind!,
        big: true,
        compact: compact,
        onTap: () => context.push(page.route),
      );
    }
    final kind = page.kind;
    return Glass(
      radius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The full-size photo: covers are small crops, blurry this big.
            Photo(city.image, icon: Icons.location_city_outlined),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x00072A33),
                    Color(0xB3072A33),
                  ],
                  stops: [0, 0.3, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF0F1B3D).withValues(alpha: 0.55),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 4),
                    Text(
                      '${city.guidesOnline} Guides live',
                      style: AppText.small.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _IconBadge(icon: kind?.icon ?? Icons.public, size: 36),
            ),
            Positioned(
              left: 12,
              right: 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          kind == null
                              ? city.country
                              : '${kind.label} check in ${city.country}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 14 : 17,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          kind == null
                              ? '${city.name} · see it live with a Guide'
                              : 'Guides in ${city.name}, ready now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: compact ? 11 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const GlossyArrow(size: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.kind,
    required this.onTap,
    this.big = false,
    this.compact = false,
  });

  final InspectKind kind;
  final VoidCallback onTap;
  final bool big;

  /// Smaller text, for the vertical flip book's short half-pages.
  final bool compact;

  static const _sharpPhotos = {
    InspectKind.place: 'loc_streets',
    InspectKind.car: 'hero_car_live',
    InspectKind.property: 'hero_property',
    InspectKind.hotel: 'hero_hotel',
    InspectKind.restaurant: 'loc_food',
    InspectKind.tourist: 'area_fahidi',
  };

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Big tiles use a full-size photo where there is one: the
                // card crops are small and blur when shown this big.
                Photo(
                  big ? (_sharpPhotos[kind] ?? kind.card) : kind.card,
                  icon: kind.icon,
                ),
                // Glass sheen across the top, deeper teal along the bottom.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55FFFFFF),
                        Color(0x00FFFFFF),
                        Color(0x00072A33),
                        Color(0xB3072A33),
                      ],
                      stops: [0, 0.3, 0.5, 1],
                    ),
                  ),
                ),
                if (big)
                  const Positioned(top: 10, left: 10, child: _LiveChip()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _IconBadge(icon: kind.icon, size: big ? 38 : 30),
                ),
                Positioned(
                  left: 12,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              kind.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.label.copyWith(
                                color: Colors.white,
                                fontSize: big ? (compact ? 14 : 17) : 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            if (big) ...[
                              const SizedBox(height: 3),
                              Text(
                                kind.cardSubtitle,
                                maxLines: 2,
                                style: AppText.small.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: compact ? 11 : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (big) const GlossyArrow(size: 32),
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

/// Glossy "● LIVE" chip on the card in front.
class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF0F1B3D).withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: AppText.small.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Green dot with a soft ripple.
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
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 5 + 7 * _c.value,
              height: 5 + 7 * _c.value,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80)
                    .withValues(alpha: 0.5 * (1 - _c.value)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 6,
              height: 6,
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

/// White glass circle holding a teal category icon.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Glass(
      shape: BoxShape.circle,
      glow: 0.8,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.52, color: AppColors.teal),
      ),
    );
  }
}

/// "Explore by Country": city bubbles strung along a glass arc, over the
/// top of a teal crystal globe.
class _CountryGlobe extends StatefulWidget {
  const _CountryGlobe({required this.reveal});

  /// Bubbles, then the globe's cap down to the screen edge, under the
  /// floating tab bar.
  static const height = 178.0;

  /// The whole pinned block, header included.
  static const pinnedHeight = height + 48;

  /// The bubbles and arc fade in with the rest of Home; the globe doesn't.
  final Animation<double> reveal;

  @override
  State<_CountryGlobe> createState() => _CountryGlobeState();
}

class _CountryGlobeState extends State<_CountryGlobe> {
  /// Bubble centres as (fraction of width, offset from the top), with
  /// their diameters, matching the arc in the design.
  static const _spots = [
    (0.07, 72.0, 40.0),
    (0.215, 56.0, 40.0),
    (0.36, 46.0, 40.0),
    (0.5, 42.0, 52.0),
    (0.64, 46.0, 40.0),
    (0.785, 56.0, 40.0),
    (0.93, 70.0, 34.0),
  ];

  /// Where the globe's top edge sits, just under the bubble names.
  static const _capTop = 100.0;

  final _globeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishRect());
  }

  /// Tells the onboarding where to land its globe.
  void _publishRect() {
    final box = _globeKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null || !box.hasSize) return;
    homeGlobeRect.value = box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final arcIn = CurvedAnimation(
      parent: widget.reveal,
      curve: const Interval(0.2, 0.7, curve: Curves.easeInOutCubic),
    );
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          // A rounder dome, curving away well inside the screen edges.
          final r = w * 0.72;
          final globeCenter = Offset(w / 2, _capTop + r);
          final centers = [for (final s in _spots) Offset(w * s.$1, s.$2)];
          return Stack(
            // The globe runs on below the section, as in the design.
            clipBehavior: Clip.none,
            children: [
              Positioned(
                key: _globeKey,
                left: globeCenter.dx - r / 0.4 / 2,
                top: globeCenter.dy - r / 0.4 / 2,
                width: r / 0.4,
                height: r / 0.4,
                // Drag to spin it; tap a city to open it.
                child: RepaintBoundary(
                  child: Globe(
                    initialLat: HomeHeroLayout.capLat,
                    initialLng: HomeHeroLayout.capLng,
                    insideScrollView: true,
                    showZoomControls: false,
                    showLabels: false,
                    crystal: true,
                    onCityTap: (c) => context.push('/country/${c.id}'),
                    onZoomIn: (lat, lng) =>
                        showFullGlobe(context, lat: lat, lng: lng),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArcPainter(
                      centers,
                      globeCenter: globeCenter,
                      // The glass arc peaks just above the Dubai bubble.
                      arcRadius: globeCenter.dy - 8,
                      progress: arcIn,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < _spots.length; i++)
                Positioned(
                  left: centers[i].dx - 44,
                  top: centers[i].dy - _spots[i].$3 / 2,
                  width: 88,
                  child: _PopIn(
                    // Dubai first, then outwards along the arc.
                    animation: CurvedAnimation(
                      parent: widget.reveal,
                      curve: Interval(
                        0.3 + (i - 3).abs() * 0.12,
                        0.62 + (i - 3).abs() * 0.12,
                      ),
                    ),
                    child: i < homeBubbleCityIds.length
                        ? _CityBubble(
                            city: cityById(homeBubbleCityIds[i])!,
                            size: _spots[i].$3,
                            focused: homeBubbleCityIds[i] == 'dubai',
                          )
                        : _MoreBubble(size: _spots[i].$3),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Faint dotted string through the bubbles.
class _ArcPainter extends CustomPainter {
  _ArcPainter(
    this.points, {
    required this.globeCenter,
    required this.arcRadius,
    required this.progress,
  }) : super(repaint: progress);

  final List<Offset> points;
  final Offset globeCenter;
  final double arcRadius;

  /// 0 → 1 draws the arc out from its peak and fades the band in.
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) return;
    // Frosted glass band between the arc and the globe.
    final band = Rect.fromCircle(center: globeCenter, radius: arcRadius);
    canvas.drawCircle(
      globeCenter,
      arcRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: (AppColors.dark ? 0.06 : 0.25) * t),
          ],
          stops: const [0, 0.82, 1],
        ).createShader(band),
    );
    final line = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.28 * t)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = AppColors.teal.withValues(alpha: 0.55 * t);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      // Dip slightly below the straight line so the string sags.
      final mid = Offset.lerp(a, b, 0.5)! + const Offset(0, 14);
      final path = Path()
        ..moveTo(a.dx, a.dy + 10)
        ..quadraticBezierTo(mid.dx, mid.dy + 10, b.dx, b.dy + 10);
      canvas.drawPath(path, line);
      canvas.drawCircle(Offset(mid.dx, mid.dy + 4), 2, dot);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.points != points ||
      old.arcRadius != arcRadius ||
      old.progress != progress;
}

/// Fades a bubble in while it rises and swells softly into place.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        final scale = 0.7 + 0.3 * Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - Curves.easeOutCubic.transform(t))),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _CityBubble extends StatelessWidget {
  const _CityBubble({
    required this.city,
    required this.size,
    required this.focused,
  });

  final City city;
  final double size;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${city.name}, ${city.country}',
      child: GestureDetector(
        onTap: () => context.push('/country/${city.id}'),
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB5F1F4),
                    Color(0xFF2FB4BE),
                    Color(0xFF8FE6EB),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3CC7D0)
                        .withValues(alpha: focused ? 0.6 : 0.35),
                    blurRadius: focused ? 20 : 12,
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F1B3D).withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(city.coverImage, icon: Icons.location_city_outlined),
                    // Glass dome: a bright sheen over the top of the photo.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x8CFFFFFF),
                            Color(0x14FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0, 0.38, 0.5],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, 1.1),
                          radius: 0.9,
                          colors: [Color(0x00FFFFFF), Color(0x33BFF3F5)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              city.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            if (focused)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 16,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: const Color(0xFF5EE6EC),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoreBubble extends StatelessWidget {
  const _MoreBubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'More countries',
      child: GestureDetector(
        onTap: () => context.push('/explore'),
        child: Column(
          children: [
            Glass(
              shape: BoxShape.circle,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  Icons.public,
                  size: size * 0.55,
                  color: AppColors.teal,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'More',
              style: AppText.small.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polished glass over a flip page: a diagonal clear-coat glare, a
/// luminous aqua outer rim, a refractive inner rim and a glossy reflection
/// along the top edge.
class _CrystalCardPainter extends CustomPainter {
  const _CrystalCardPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.22, 0.38],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFB7FFF4).withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4.5), Radius.circular(radius - 4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    final line = Rect.fromLTRB(32, 3, size.width - 32, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(line.inflate(1), const Radius.circular(3)),
      Paint()
        ..color = const Color(0x9957D1C7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF8FFFF0),
            Colors.white,
            Color(0xFF57D1C7),
            Colors.white,
            Colors.transparent,
          ],
        ).createShader(line),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrystalCardPainter old) => old.radius != radius;
}

/// The thin, clear glass sheet behind the flip book: barely tinted, with
/// hairline edges, a diagonal glare and coloured light caught in its edges
/// as in cut glass.
class _GlassSlatePainter extends CustomPainter {
  const _GlassSlatePainter();

  static const _radius = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    // Shadow and glow outside the sheet only.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(60)),
        Path()..addRRect(rrect),
      ),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0xFF0F1B3D).withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF8FFFF0).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();
    canvas.drawRRect(
      rrect.inflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = const Color(0xFF6E8C98).withValues(alpha: 0.35),
    );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.17, -1),
          end: Alignment(0.17, 1),
          colors: [Color(0x0D284856), Color(0x06284856), Color(0x0F1E3C50)],
        ).createShader(rect),
    );
    // Bright inner edges, lit from the top left.
    final white = Colors.white;
    paintInsetShadow(canvas, rrect, white, spread: 1);
    paintInsetShadow(
      canvas,
      rrect,
      white,
      dx: 1.5,
      dy: 2,
      blur: 1,
      spread: 0.5,
    );
    paintInsetShadow(
      canvas,
      rrect,
      white.withValues(alpha: 0.9),
      dx: -1.5,
      dy: -2,
      blur: 1,
      spread: 0.5,
    );

    // Shine: a broad diagonal glare with a thin bright streak beside it.
    for (final (left, width, colors, stops) in [
      (
        0.08,
        0.22,
        [
          white.withValues(alpha: 0),
          white.withValues(alpha: 0.38),
          white.withValues(alpha: 0.12),
          white.withValues(alpha: 0),
        ],
        const [0.0, 0.45, 0.7, 1.0],
      ),
      (
        0.34,
        0.03,
        [
          white.withValues(alpha: 0),
          white.withValues(alpha: 0.5),
          white.withValues(alpha: 0),
        ],
        const [0.0, 0.5, 1.0],
      ),
    ]) {
      final strip = Rect.fromLTWH(w * left, -h * 0.1, w * width, h * 1.3);
      canvas.save();
      canvas.translate(strip.center.dx, strip.center.dy);
      canvas.transform(
        (Matrix4.identity()..setEntry(0, 1, math.tan(24 * math.pi / 180)))
            .storage,
      );
      canvas.translate(-strip.center.dx, -strip.center.dy);
      canvas.drawRect(
        strip,
        Paint()
          ..shader = LinearGradient(
            colors: colors,
            stops: stops,
          ).createShader(strip),
      );
      canvas.restore();
    }

    // Glossy sheen along the top.
    final sheen = Rect.fromLTWH(24, 2, w - 48, 56);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        sheen,
        topLeft: const Radius.circular(32),
        topRight: const Radius.circular(32),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [white.withValues(alpha: 0.6), white.withValues(alpha: 0)],
        ).createShader(sheen),
    );

    // Hot spots where the light hits the rounded corners, a glare down
    // the left edge, and coloured light caught in the edges.
    paintGlow(canvas, Rect.fromLTWH(18, 3, w * 0.3, 6), white, blur: 1.5);
    paintGlow(
      canvas,
      Rect.fromLTWH(w - 18 - w * 0.24, h - 8, w * 0.24, 5),
      white.withValues(alpha: 0.95),
      blur: 1.5,
    );
    paintGlow(
      canvas,
      Rect.fromLTWH(-4, h * 0.16, 16, h * 0.26),
      white,
      blur: 4,
    );
    paintGlow(
      canvas,
      Rect.fromLTWH(w - 6, h * 0.06, 10, h * 0.14),
      const Color(0xD9BE96FF),
      blur: 3,
    );
    paintGlow(
      canvas,
      Rect.fromLTWH(w - 6, h * 0.58, 10, h * 0.16),
      const Color(0xCC6EF0D2),
      blur: 3,
    );
    paintGlow(
      canvas,
      Rect.fromLTWH(-4, h * 0.7, 10, h * 0.1),
      const Color(0xCCFFAA5A),
      blur: 3,
    );

    // Polished top corners catching the light.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(33)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [white.withValues(alpha: 0.95), white.withValues(alpha: 0)],
          stops: const [0, 0.18],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassSlatePainter oldDelegate) => false;
}
