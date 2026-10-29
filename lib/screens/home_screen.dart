import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/onboarding_state.dart';
import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';
import '../widgets/giraffe.dart';
import '../widgets/globe.dart';
import '../widgets/liquid_glass_edge.dart';
import 'globe_screen.dart';

/// The Home layouts shown side by side at /variations.html.
enum HomeVariant {
  /// The PDF's cards, flipping vertically over a hinge like a flip deck.
  coverflow,

  /// The same page, with the cards turning horizontally like a book's.
  book,

  /// A fanned hand of cards.
  fan,

  /// The globe whole, in the middle of the page, with bento tiles below.
  bento,

  /// A "Detecting spots" location scanner in the middle, tiles below.
  scan;

  static HomeVariant fromName(String? name) =>
      values.asNameMap()[name] ?? coverflow;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.variant = HomeVariant.coverflow});

  final HomeVariant variant;

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
    final middle =
        widget.variant == HomeVariant.bento ||
        widget.variant == HomeVariant.scan;
    // The flip book, with the country globe pinned under it.
    final flip =
        widget.variant == HomeVariant.coverflow ||
        widget.variant == HomeVariant.book;
    // These two open on a light header instead of the photo slider.
    final scan = widget.variant == HomeVariant.scan;
    final compact = flip || scan;
    final search = GlassSearchField(
      hint: 'Search for it…',
      onTap: () => context.push('/explore'),
    );
    final sections = <Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 8 : 10,
          16,
          compact ? 26 : 0,
        ),
        child: search,
      ),
      if (middle && !scan)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: SectionHeader(
            'Explore by Country',
            subtitle: 'Find a Guide in the country you want to inspect.',
            onSeeAll: () => context.push('/explore'),
          ),
        ),
      // The scanner holds everything itself, so it has no tiles below.
      if (scan)
        const SizedBox()
      else if (middle)
        // Under the middle globe, the header and tiles share one glass card.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Glass(
            radius: 26,
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SectionHeader(
                    'See Before You Decide',
                    subtitle:
                        'Avoid surprises. Inspect with a local Guide through '
                        'a live video.',
                    onSeeAll: () => context.push('/decide'),
                  ),
                ),
                const _DecideBento(
                  padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
                ),
              ],
            ),
          ),
        )
      else
        Padding(
          padding: EdgeInsets.only(top: flip ? 2 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionHeader(
                  'See Before You Decide',
                  subtitle:
                      'Avoid surprises. Inspect with a local Guide through '
                      'a live video.',
                  onSeeAll: () => context.push('/decide'),
                ),
              ),
              SizedBox(height: flip ? 18 : 4),
              _DecideCarousel(
                fan: widget.variant == HomeVariant.fan,
                book: widget.variant == HomeVariant.book,
              ),
            ],
          ),
        ),
    ];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: _PageBackground(
        white: flip,
        child: Stack(
          children: [
            // A faint giraffe-skin pattern behind the scanner layout.
            if (scan)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: GiraffePatternPainter(
                        // A white network, like the globe's.
                        color: Colors.white.withValues(
                          alpha: AppColors.dark ? 0.06 : 0.75,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ListView(
              // Room for the pinned globe section below.
              padding: EdgeInsets.only(
                bottom:
                    bottomInset +
                    (middle
                        ? 100
                        : _CountryGlobe.pinnedHeight + _PinnedCountries.lift),
              ),
              children: [
                if (compact)
                  _CompactHero(combined: compact)
                else
                  const _PhotoHero(),
                // The content sheet overlaps the hero with rounded corners.
                Transform.translate(
                  offset: Offset(0, compact ? 0 : -HomeHeroLayout.sheetOverlap),
                  child: Container(
                    // The flip book sits straight on the page, no sheet.
                    decoration: compact
                        ? null
                        : BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: AppColors.dark
                                  ? [AppColors.background, AppColors.background]
                                  : const [
                                      Color(0xFFF7FDFD),
                                      Color(0xFFE6F6F7),
                                    ],
                            ),
                            border: Border(
                              top: BorderSide(color: Glass.rim, width: 1.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3CC7D0)
                                    .withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < sections.length; i++) ...[
                          _Reveal(
                            animation: _entrance,
                            index: i,
                            child: sections[i],
                          ),
                          // Not faded in: the intro's globe lands right on it.
                          if (middle && i == (scan ? 0 : 1))
                            widget.variant == HomeVariant.scan
                                ? const _LocationScanner()
                                : const _MiddleGlobe(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Pinned to the bottom so the globe is always on screen; the
            // page scrolls under it. Not faded in: the intro's globe lands
            // right on it.
            if (!middle)
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
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
              child: SectionHeader(
                'Explore by Country',
                subtitle: 'Find a Guide in the country you want to inspect.',
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

/// The whole crystal globe in the middle of Home, with the city bubbles
/// on a glass orbit over its top half.
class _MiddleGlobe extends StatefulWidget {
  const _MiddleGlobe();

  @override
  State<_MiddleGlobe> createState() => _MiddleGlobeState();
}

class _MiddleGlobeState extends State<_MiddleGlobe> {
  // Shorter than the globe, so the card below rides up over its bottom.
  static const _height = 276.0;
  static const _radius = 132.0;

  final _globeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Tells the onboarding where to land its globe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _globeKey.currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || box == null || !box.hasSize) return;
      homeGlobeRect.value = box.localToGlobal(Offset.zero) & box.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Sits just under the section title.
          final center = Offset(constraints.maxWidth / 2, _radius + 34);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                key: _globeKey,
                left: center.dx - _radius / 0.4 / 2,
                top: center.dy - _radius / 0.4 / 2,
                width: _radius / 0.4,
                height: _radius / 0.4,
                child: RepaintBoundary(
                  // The first demo's idea: city photo pins on the globe as
                  // it tours the live cities. Drag to spin it, tap a city to
                  // open it, pinch or scroll-zoom for the full globe.
                  child: Globe(
                    initialLat: HomeHeroLayout.globeLat,
                    initialLng: HomeHeroLayout.globeLng,
                    insideScrollView: true,
                    showZoomControls: false,
                    crystal: true,
                    photoPins: true,
                    onCityTap: (c) => context.push('/country/${c.id}'),
                    onZoomIn: (lat, lng) =>
                        showFullGlobe(context, lat: lat, lng: lng),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Detecting spots…": landmark photos glide through a scan frame while a
/// glowing line sweeps across it, naming each place as it's scanned.
class _LocationScanner extends StatefulWidget {
  const _LocationScanner();

  @override
  State<_LocationScanner> createState() => _LocationScannerState();
}

class _LocationScannerState extends State<_LocationScanner>
    with SingleTickerProviderStateMixin {
  /// Same filter as the flip book: everything, countries, or one kind of
  /// check followed by every country for it.
  String? _filter;

  List<_FlipPage> get _pages {
    final kind = InspectKind.fromName(_filter);
    final countries = _DecideCarouselState._countries;
    if (kind != null) {
      return [
        _FlipPage(kind: kind),
        for (final c in countries) _FlipPage(kind: kind, city: c),
      ];
    }
    return [
      if (_filter != 'countries')
        for (final k in _DecideCarouselState._kinds) _FlipPage(kind: k),
      for (final c in countries) _FlipPage(city: c),
    ];
  }

  /// Position along the pages, in pages: whole numbers are a page resting
  /// in the frame, and the fraction above it plays the glide then the
  /// scan. Steps on its own every few seconds; holding a press pauses it.
  late final _c = AnimationController.unbounded(vsync: this, value: 0)
    ..animateTo(_rest(0), duration: _scanTime, curve: Curves.linear);

  static const _scanTime = Duration(milliseconds: 1500);

  /// Where page [i] has finished gliding in and being scanned.
  static double _rest(int i) => i + 0.999;

  int get _at => _c.value.floor();

  /// True while a mouse button or finger is held down on the scanner.
  bool _held = false;
  Timer? _auto;
  Duration _idleSince = Duration.zero;
  final _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    // Moves on to the next page after it has rested for a few seconds.
    _auto = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_held || _c.isAnimating) {
        _idleSince = _clock.elapsed;
        return;
      }
      if (_clock.elapsed - _idleSince > const Duration(milliseconds: 2800)) {
        _idleSince = _clock.elapsed;
        _step(1);
      }
    });
  }

  void _hold(bool down) {
    setState(() => _held = down);
    if (down) {
      _c.stop();
    } else if (_c.value != _rest(_at)) {
      // Finishes the glide and scan it was in the middle of.
      _c.animateTo(
        _rest(_at),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.linear,
      );
    }
  }

  /// Glides [by] pages and scans the one that lands in the frame.
  void _step(int by) {
    _c.animateTo(
      _rest(_at + by),
      duration: const Duration(milliseconds: 2200),
      curve: Curves.linear,
    );
  }

  void _setFilter(String? f) {
    setState(() => _filter = f);
    _c
      ..value = 0
      ..animateTo(_rest(0), duration: _scanTime, curve: Curves.linear);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final mq = MediaQuery.of(context);
    // Fills the room under the search bar, like the flip book.
    final room = (mq.size.height - mq.padding.top - mq.padding.bottom - 360)
        .clamp(330.0, 470.0);
    return Column(
      children: [
        // Press and hold anywhere on the scanner to pause it.
        Listener(
          onPointerDown: (_) => _hold(true),
          onPointerUp: (_) => _hold(false),
          onPointerCancel: (_) => _hold(false),
          child: SizedBox(
            height: room,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                const frame = 196.0;
                const spacing = 168.0;
                // Caption (56) + gap (20) + frame, centred in the room.
                const block = 56 + 20 + frame;
                final blockTop = (constraints.maxHeight - block) / 2;
                // Frame and its caption, centred together in the room.
                // Caption first, the frame just below it.
                final center = Offset(w / 2, blockTop + 76 + frame / 2);
                return AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    // Glide, then pause with the place centred in the frame.
                    final step = t.floor();
                    final eased =
                        step +
                        Curves.easeInOutCubic.transform(
                          ((t - step) / 0.45).clamp(0.0, 1.0),
                        );
                    final current = pages[eased.round() % pages.length];
                    final within = (t - step - 0.45) / 0.55;
                    // The scan line sweeps the frame while the place rests in it.
                    final scanX = within < 0
                        ? -1.0
                        : math.sin(
                            within.clamp(0.0, 1.0) * math.pi * 2 - math.pi / 2,
                          );
                    final scanned = within > 0.55;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Soft glow behind the frame.
                        Positioned(
                          left: center.dx - 160,
                          top: center.dy - 160,
                          width: 320,
                          height: 320,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF7FD8FF)
                                        .withValues(alpha: 0.28),
                                    const Color(0xFF7FD8FF)
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (var k = -2; k <= 2; k++)
                          _place(pages, k, eased, center, spacing),
                        Positioned(
                          left: center.dx - frame / 2,
                          top: center.dy - frame / 2,
                          width: frame,
                          height: frame,
                          child: const IgnorePointer(
                            child: CustomPaint(painter: _BracketPainter()),
                          ),
                        ),
                        // The glowing scan line, gone once the page has been read.
                        if (within >= 0 && within < 0.97)
                          Positioned(
                            left: center.dx + scanX * frame * 0.42 - 3,
                            top: center.dy - frame * 0.62,
                            width: 6,
                            height: frame * 1.24,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x335B8CFF),
                                      Color(0xFF5B8CFF),
                                      Color(0xFF3CC7D0),
                                      Color(0x333CC7D0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5B8CFF)
                                          .withValues(alpha: 0.55),
                                      blurRadius: 22,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          top: blockTop,
                          child: Column(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  scanned
                                      ? current.found
                                      : 'Detecting spots${'.' * (1 + (t * 3).floor() % 3)}',
                                  key: ValueKey(
                                    scanned ? current.route : 'scan',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.title.copyWith(fontSize: 21),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scanned
                                    ? current.foundDetail
                                    : 'Scanning for local Guides near you…',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.small.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // Tap or click a side photo (or its arrow) to scan it next.
                        for (final by in [-1, 1])
                          Positioned(
                            left: center.dx + by * spacing - 60,
                            top: center.dy - 60,
                            width: 120,
                            height: 120,
                            child: Semantics(
                              button: true,
                              label: by < 0 ? 'Scan previous' : 'Scan next',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _step(by),
                                ),
                              ),
                            ),
                          ),
                        for (final by in [-1, 1])
                          Positioned(
                            left: by < 0 ? 10 : null,
                            right: by > 0 ? 10 : null,
                            top: center.dy + frame / 2 + 6,
                            child: GlassIconButton(
                              icon: by < 0
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              label: by < 0 ? 'Scan previous' : 'Scan next',
                              size: 38,
                              onPressed: () => _step(by),
                            ),
                          ),
                        // Tapping the frame opens the place being scanned.
                        Positioned(
                          left: center.dx - frame / 2,
                          top: center.dy - frame / 2,
                          width: frame,
                          height: frame,
                          child: Semantics(
                            button: true,
                            label: 'Open ${current.label}',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push(current.route),
                              onHorizontalDragEnd: (d) {
                                final v = d.primaryVelocity ?? 0;
                                if (v.abs() > 100) _step(v < 0 ? 1 : -1);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        const _Headline(combined: true),
        const SizedBox(height: 18),
        _FilterDial(selected: _filter, onSelected: _setFilter),
        const SizedBox(height: 18),
      ],
    );
  }

  /// The place [k] steps from the one in the frame; grows as it nears it.
  Widget _place(
    List<_FlipPage> pages,
    int k,
    double eased,
    Offset center,
    double spacing,
  ) {
    final index = (eased.floor() + k) % pages.length;
    final offset = k - (eased - eased.floor());
    final d = offset.abs();
    final size = 150 - math.min(1.0, d) * 50;
    final page = pages[index];
    return Positioned(
      left: center.dx + offset * spacing - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: (1 - math.max(0.0, d - 1) * 0.9).clamp(0.0, 1.0).toDouble(),
        child: Container(
          // A bright glass rim and aqua glow around each photo.
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28 + 3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFA9ECF0), Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3CC7D0).withValues(alpha: 0.35),
                blurRadius: 16,
              ),
              BoxShadow(
                color: const Color(0xFF0F1B3D).withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Photo(page.image, icon: Icons.location_city_outlined),
                // Glossy top, like a little glass tile.
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Four soft rounded corner brackets of a camera viewfinder.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = (AppColors.dark ? Colors.white : const Color(0xFF0F1B3D))
          .withValues(alpha: 0.12);
    final w = size.width, h = size.height;
    const arm = 30.0, r = 18.0;
    for (final (x, y, sx, sy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + sy * arm)
          ..lineTo(x, y + sy * r)
          ..quadraticBezierTo(x, y, x + sx * r, y)
          ..lineTo(x + sx * arm, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) => false;
}

/// The flip book sits on plain white; the others on the crystal aqua.
class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.white, required this.child});

  final bool white;
  final Widget child;

  @override
  Widget build(BuildContext context) => white && !AppColors.dark
      ? ColoredBox(color: Colors.white, child: child)
      : CrystalBackground(child: child);
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

/// Full-bleed photo carousel with the greeting, headline and wallet.
class _PhotoHero extends StatefulWidget {
  const _PhotoHero();

  @override
  State<_PhotoHero> createState() => _PhotoHeroState();
}

class _PhotoHeroState extends State<_PhotoHero> {
  static const _slides = [
    (InspectKind.car, Alignment(0.3, -0.2)),
    (InspectKind.property, Alignment.center),
    (InspectKind.hotel, Alignment.center),
    (InspectKind.place, Alignment.center),
  ];

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _slides.length,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // At least a status bar's worth on top, so the headline never clips
    // on screens without one (the side-by-side variations).
    final top = math.max(MediaQuery.paddingOf(context).top, 24.0);
    return SizedBox(
      height: top + HomeHeroLayout.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => context.push('/inspect/${_slides[i].$1.name}'),
              child: Photo(
                _slides[i].$1.hero,
                icon: _slides[i].$1.icon,
                alignment: _slides[i].$2,
              ),
            ),
          ),
          // One smooth wash: light at the top for the status bar and
          // greeting, deep teal under the headline.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80072A33),
                    Color(0x33072A33),
                    Color(0xB3072A33),
                    Color(0xF2062A33),
                  ],
                  stops: [0, 0.3, 0.65, 1],
                ),
              ),
            ),
          ),
          // Greeting and wallet share one row.
          Positioned(
            top: top + 8,
            left: 20,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hi Priyamvada! 👋',
                    style: AppText.label.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _WalletChip(onTap: () => context.go('/wallet')),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: HomeHeroLayout.sheetOverlap + 14,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See it live.',
                    style: AppText.display.copyWith(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Know before you go.',
                    style: AppText.display.copyWith(
                      color: const Color(0xFF6FF0F2),
                      fontSize: 23,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send a local Guide to inspect any place,\n'
                    'before you spend your time or money.',
                    style: AppText.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Slide dots, tucked into the bottom-right corner.
          Positioned(
            right: 18,
            bottom: HomeHeroLayout.sheetOverlap + 16,
            child: Row(
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 5),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _page
                          ? const Color(0xFF5EE6EC)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Light header without the photo slider: greeting and wallet, then the
/// headline, so the flip book gets the room.
class _CompactHero extends StatelessWidget {
  const _CompactHero({this.combined = false});

  /// One headline that also says what the cards are for, instead of a
  /// separate "See Before You Decide" title.
  final bool combined;

  @override
  Widget build(BuildContext context) {
    final top = math.max(MediaQuery.paddingOf(context).top, 28.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hi Priyamvada! 👋',
                  style: AppText.label.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _WalletChip(onTap: () => context.go('/wallet')),
            ],
          ),
          // The combined headline lives above the filter dial instead.
          if (!combined) ...[
            const SizedBox(height: 26),
            const _Headline(combined: false),
          ],
        ],
      ),
    );
  }
}

/// "See it live. Know before you go.", or the combined two-line, centred
/// "See it live before you / decide or go."
class _Headline extends StatelessWidget {
  const _Headline({required this.combined});

  final bool combined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          text: combined ? 'See it live before you\n' : 'See it live. ',
          children: [
            TextSpan(
              text: combined ? 'decide or go.' : 'Know before you go.',
              style: TextStyle(
                color: AppColors.dark
                    ? const Color(0xFF8EE3E8)
                    : AppColors.tealDark,
              ),
            ),
          ],
        ),
        style: AppText.display.copyWith(fontSize: 23, height: 1.15),
        textAlign: combined ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Wallet, AED 120.00',
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.teal,
              ),
              const SizedBox(width: 6),
              Text(
                'AED 120.00',
                style: AppText.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cover-flow of "See Before You Decide" cards: the centre card faces you,
/// the ones either side turn away.
class _DecideCarousel extends StatefulWidget {
  const _DecideCarousel({required this.fan, this.book = false});

  /// A fanned hand of cards; otherwise the PDF's cover-flow.
  final bool fan;

  /// The flip book's pages turn horizontally, like a book's, instead of
  /// vertically over a hinge.
  final bool book;

  @override
  State<_DecideCarousel> createState() => _DecideCarouselState();
}

/// One page of the flip book: a kind of check, a country, or a country
/// for one kind of check.
class _FlipPage {
  const _FlipPage({this.kind, this.city});

  final InspectKind? kind;
  final City? city;

  String get label => city == null
      ? kind!.title
      : kind == null
      ? '${city!.country}, ${city!.name}'
      : '${kind!.label} check in ${city!.country}';

  String get image => city?.coverImage ?? kind!.card;

  /// What the scanner says once it has read this page.
  String get found => city == null
      ? kind!.title
      : kind == null
      ? '${city!.name} · ${city!.guidesOnline} Guides live'
      : '${kind!.label} check in ${city!.country}';

  String get foundDetail => city == null
      ? kind!.cardSubtitle
      : kind == null
      ? 'Tap to explore ${city!.country} live.'
      : '${city!.guidesOnline} Guides ready in ${city!.name}.';

  String get route => city == null
      ? '/inspect/${kind!.name}'
      : kind == null
      ? '/country/${city!.id}'
      : '/country/${city!.id}?intent=${kind!.name}';
}

class _DecideCarouselState extends State<_DecideCarousel> {
  /// Not fanned: the cards flip vertically over a hinge.
  bool get _flip => !widget.fan;

  /// Flip book turning horizontally, like a book.
  bool get _book => _flip && widget.book;
  Timer? _auto;

  static final _countries = [
    for (final r in regions)
      for (final id in r.cityIds) cityById(id)!,
  ];

  /// Every kind of check, then every country.
  static final _pages = [
    for (final k in _kinds) _FlipPage(kind: k),
    for (final c in _countries) _FlipPage(city: c),
  ];

  int get _count => _flip ? _pages.length : _kinds.length;

  @override
  void initState() {
    super.initState();
    if (_flip) {
      // Flips to the next card on its own, round and round.
      _auto = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        if (!_controller.hasClients) return;
        final page = (_controller.page ?? 0).round();
        _controller.animateToPage(
          (page + 1) % _count,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

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
  static final _start = _kinds.indexOf(InspectKind.car);
  late final PageController _controller = PageController(
    // One swipe of this width moves the deck by one card.
    viewportFraction: widget.fan
        ? 0.42
        : widget.book
        ? 0.8
        : 0.37,
    initialPage: _flip ? 0 : _start,
  );

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
  double get _spineY => _pageH + 8;
  double get _bookH => _pageH * 2 + 18;

  /// Page width, as a share of the row.
  static const _pageW = 0.78;

  /// Flip book: every page hinges on one spine across the middle. Pages
  /// still to come stand above it, leaning back a little more each; the
  /// page being turned swings over the spine, and turned pages hang below
  /// it showing their backs, upside down.
  Widget _flipCard(int i, double delta, double w) {
    final d = delta.abs();
    if (d > 3.2) return const Positioned(left: 0, top: 0, child: SizedBox());
    // 0 stands the page up above the spine; pi hangs it straight down.
    final double angle;
    if (delta >= 0) {
      angle = -0.12 - math.min(delta, 2.5) * 0.16;
    } else if (delta > -1) {
      angle = -0.12 + Curves.easeInOut.transform(-delta) * (math.pi - 0.02);
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

  /// How far the two pages underneath peek out on the right in all; the
  /// book is shifted left by half of it, so page and edges sit centred.
  static const _peek = 12.0;

  /// Room above and below the book's page.
  static const _pad = 6.0;

  /// Book: one page at a time, bound on a spine down its left edge. The
  /// page being read turns over the spine, and the pages to come wait
  /// underneath, their edges peeking out on the right.
  Widget _bookCard(int i, double delta, double w) {
    final d = delta.abs();
    // Turned pages are gone; only the next two wait underneath.
    if (delta <= -1 || delta > 2.5) {
      return const Positioned(left: 0, top: 0, child: SizedBox());
    }
    final double angle, dx, scale, opacity, shade;
    if (delta >= 0) {
      // Waiting underneath, a little smaller and nudged right.
      angle = 0;
      dx = math.min(delta, 2) * (_peek / 2 + w * 0.04) - _peek / 2;
      scale = 1 - math.min(delta, 2) * 0.04;
      opacity = (2.5 - delta).clamp(0.0, 1.0);
      shade = math.min(delta, 2) * 0.12;
    } else {
      // Turning over the spine, the free edge swinging across to the left.
      final t = Curves.easeInOut.transform(d);
      angle = -t * 1.9;
      dx = -_peek / 2;
      scale = 1;
      opacity = 1 - Curves.easeIn.transform(((t - 0.7) / 0.3).clamp(0.0, 1.0));
      shade = math.sin(t * math.pi / 2) * 0.35;
    }
    return Positioned(
      left: 0,
      right: 0,
      top: _pad,
      height: _bookH - _pad * 2,
      child: Center(
        child: SizedBox(
          width: w,
          child: Opacity(
            opacity: opacity,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..translateByDouble(dx, 0, 0, 1)
                ..rotateY(angle)
                ..scaleByDouble(scale, scale, 1, 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFF0F1B3D).withValues(alpha: shade),
                  BlendMode.srcATop,
                ),
                child: _glassPage(i),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A flip page with the same liquid-glass edge as the tab bar. The
  /// vertical flip's half-pages are short, so their text is smaller.
  Widget _glassPage(int i) => Stack(
    fit: StackFit.expand,
    children: [
      _FlipPageCard(page: _pages[i], compact: !_book),
      const IgnorePointer(
        child: CustomPaint(
          painter: LiquidGlassEdgePainter(
            radius: 20,
            rim: 6,
            flares: [0.3, 0.8],
          ),
        ),
      ),
    ],
  );

  void _step(int by) {
    final page = (_controller.page ?? _start.toDouble()).round() + by;
    _controller.animateToPage(
      page.clamp(0, _count - 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  /// A hand of cards: each one turns about a pivot far below the deck,
  /// so neighbours fan out on an arc and tuck in behind the front card.
  Widget _placed(int i, double delta, double itemWidth, double height) {
    final d = delta.abs();
    final angle = delta.clamp(-3.0, 3.0) * 0.21;
    final scale = 1 - math.min(1.0, d) * 0.1 - math.max(0.0, d - 1) * 0.05;
    // Pivot sits well below the cards, in the card's own coordinates.
    final pivotY = height * 1.9;
    final transform = Matrix4.identity()
      ..translateByDouble(itemWidth / 2, pivotY, 0, 1)
      ..rotateZ(angle)
      ..translateByDouble(-itemWidth / 2, -pivotY, 0, 1)
      ..translateByDouble(itemWidth / 2, height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-itemWidth / 2, -height / 2, 0, 1);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: SizedBox(
          width: itemWidth,
          height: height,
          child: Opacity(
            opacity: (1 - math.max(0.0, d - 2) * 0.8).clamp(0.0, 1.0),
            child: Transform(
              transform: transform,
              child: _DecideCard(
                kind: _kinds[i],
                active: d < 0.5,
                // Photos drift against the turn, like looking through glass.
                parallax: delta.clamp(-1.5, 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Fills what's left between the search bar and the pinned country
    // globe: header 150, search 74, gaps 8 + 18, book frame 18.
    final globe = _CountryGlobe.pinnedHeight + _PinnedCountries.lift;
    // The header keeps at least 28 above it even with no status bar.
    final top = math.max(mq.padding.top, 28.0);
    _pageH = ((mq.size.height - top - mq.padding.bottom - 204 - globe) / 2)
        .clamp(100.0, 220.0);
    return _deck(context);
  }

  Widget _deck(BuildContext context) {
    return SizedBox(
      height: widget.fan ? 220 : _bookH,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  constraints.maxWidth * (widget.fan ? 0.5 : 0.37);
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final page =
                      _controller.hasClients &&
                          _controller.position.haveDimensions
                      ? _controller.page!
                      : (_flip ? 0.0 : _start.toDouble());
                  // Farthest first, so the centre card paints on top. In the
                  // book, the page being turned stays on top of the pages
                  // underneath for the whole turn.
                  int depth(int i) => _book && i - page < 0 ? 1 : 0;
                  final order = List.generate(_count, (i) => i)
                    ..sort((a, b) {
                      final byDepth = depth(a).compareTo(depth(b));
                      if (byDepth != 0) return byDepth;
                      return (b - page).abs().compareTo((a - page).abs());
                    });
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final i in order)
                        widget.fan
                            ? _placed(i, i - page, itemWidth, 200)
                            : _book
                            ? _bookCard(
                                i,
                                i - page,
                                constraints.maxWidth * _pageW,
                              )
                            : _flipCard(
                                i,
                                i - page,
                                constraints.maxWidth * _pageW,
                              ),
                      // The spine the pages turn on: across the middle, or
                      // down the book's left edge.
                      if (_flip)
                        Positioned(
                          left: _book
                              ? constraints.maxWidth * (1 - _pageW) / 2 -
                                    _peek / 2 -
                                    2
                              : constraints.maxWidth * 0.04,
                          right: _book ? null : constraints.maxWidth * 0.04,
                          width: _book ? 4 : null,
                          top: _book ? _pad + 6 : _spineY - 2,
                          height: _book ? _bookH - _pad * 2 - 12 : 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white.withValues(alpha: 0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3CC7D0)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          // Invisible pages on top take the swipes and taps.
          PageView.builder(
            controller: _controller,
            // The flip deck turns with up and down swipes; the book with
            // left and right ones.
            scrollDirection: _flip && !_book ? Axis.vertical : Axis.horizontal,
            itemCount: _count,
            itemBuilder: (context, i) => Semantics(
              button: true,
              label: _flip ? _pages[i].label : _kinds[i].title,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(
                  _flip ? _pages[i].route : '/inspect/${_kinds[i].name}',
                ),
              ),
            ),
          ),
          Positioned(
            left: _book ? 4 : 12,
            top: widget.fan
                ? 90
                : _book
                ? _bookH / 2 - 19
                : _spineY - 19,
            child: GlassIconButton(
              icon: _flip && !_book
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.chevron_left_rounded,
              label: 'Previous',
              size: 38,
              onPressed: () => _step(-1),
            ),
          ),
          Positioned(
            right: _book ? 4 : 12,
            top: widget.fan
                ? 90
                : _book
                ? _bookH / 2 - 19
                : _spineY - 19,
            child: GlassIconButton(
              icon: _flip && !_book
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_right_rounded,
              label: 'Next',
              size: 38,
              onPressed: () => _step(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Camera-style mode dial over the flip book. Filters sit on a gentle
/// arc; swipe or tap one into the glowing glass lens in the middle to pick
/// it, and the ones further out shrink and fade.
class _FilterDial extends StatefulWidget {
  const _FilterDial({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  State<_FilterDial> createState() => _FilterDialState();
}

class _FilterDialState extends State<_FilterDial> {
  static final _options = <(String?, String, IconData)>[
    (null, 'All', Icons.auto_awesome_outlined),
    ('countries', 'Countries', Icons.public),
    for (final k in InspectKind.decideOrder) (k.name, k.label, k.icon),
  ];

  /// The dial loops round, so every filter (All too) has others on both
  /// sides; it starts far into the loop with the selected one centred.
  static const _loops = 1000;
  late final _controller = PageController(
    viewportFraction: 0.3,
    initialPage:
        _options.length * _loops ~/ 2 +
        _options.indexWhere((o) => o.$1 == widget.selected),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          // The lens: a glossy glass pill the chosen filter sits in.
          const Positioned.fill(
            top: 16,
            child: Center(
              child: IgnorePointer(child: GlossyPill(width: 120, height: 42)),
            ),
          ),
          // Tick marks along the dial's rim.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 10,
            child: IgnorePointer(child: CustomPaint(painter: _DialTicks())),
          ),
          // The filters sit below the ticks, with room between.
          Positioned.fill(
            top: 16,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final page =
                    _controller.hasClients &&
                        _controller.position.haveDimensions
                    ? _controller.page!
                    : _controller.initialPage.toDouble();
                return PageView.builder(
                  controller: _controller,
                  itemCount: _options.length * _loops,
                  onPageChanged: (i) =>
                      widget.onSelected(_options[i % _options.length].$1),
                  itemBuilder: (context, i) {
                    final (_, label, icon) = _options[i % _options.length];
                    final d = (i - page).abs();
                    final on = d < 0.5;
                    final t = math.min(1.0, d);
                    return Semantics(
                      button: true,
                      selected: on,
                      label: '$label filter',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _controller.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        ),
                        // Dips along the arc and shrinks away from the lens.
                        child: Transform.translate(
                          offset: Offset(0, -math.min(d, 2.5) * 3),
                          child: Transform.scale(
                            scale: 1.08 - t * 0.24,
                            child: Opacity(
                              opacity: (1 - math.max(0.0, d - 0.6) * 0.45)
                                  .clamp(0.25, 1.0)
                                  .toDouble(),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 17,
                                      color: Color.lerp(
                                        Colors.white,
                                        AppColors.muted,
                                        t,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.label.copyWith(
                                          fontSize: 14,
                                          fontWeight: on
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Color.lerp(
                                            Colors.white,
                                            AppColors.muted,
                                            t,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fine ticks along the top of the dial, brightest over the lens.
class _DialTicks extends CustomPainter {
  const _DialTicks();

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    for (var x = 12.0; x < size.width - 12; x += 9) {
      final near = 1 - ((x - mid).abs() / mid).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, 3 + near * 4),
        Paint()
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.teal.withValues(alpha: 0.12 + near * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(_DialTicks oldDelegate) => false;
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

class _DecideCard extends StatelessWidget {
  const _DecideCard({
    required this.kind,
    required this.active,
    this.parallax = 0,
  });

  final InspectKind kind;
  final bool active;

  /// How far the card has turned away, in cards; shifts the photo.
  final double parallax;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: ExcludeSemantics(
        child: DecoratedBox(
          // Solid backing so cards behind don't show through the glass.
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Glass(
            radius: 18,
            glow: active ? 1.4 : 0.7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 112,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        ClipPath(
                          clipper: const WaveClipper(depth: 14),
                          child: Photo(
                            kind.card,
                            icon: kind.icon,
                            alignment: Alignment(-parallax * 0.7, 0),
                          ),
                        ),
                        // Glass sheen across the top of the photo.
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment(0.2, 0.2),
                                colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: AnimatedOpacity(
                            opacity: active ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const _LiveChip(),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: -16,
                          child: _IconBadge(icon: kind.icon, size: 36),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kind.title,
                            style: AppText.label.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    kind.cardSubtitle,
                                    style: AppText.small.copyWith(
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AnimatedOpacity(
                                  opacity: active ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const GlossyArrow(size: 30),
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
        ),
      ),
    );
  }
}

/// Bento grid: one tall feature tile beside two stacked tiles, then a
/// wide tile, each a glossy photo with its title on frosted glass.
class _DecideBento extends StatefulWidget {
  const _DecideBento({
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 14),
  });

  final EdgeInsets padding;

  @override
  State<_DecideBento> createState() => _DecideBentoState();
}

/// The tiles turn in like book pages, one after another; then every few
/// seconds one tile turns its page to show another kind of check.
class _DecideBentoState extends State<_DecideBento>
    with SingleTickerProviderStateMixin {
  static const _slots = 5;

  /// Which kind each slot shows, as an index into [InspectKind.decideOrder].
  final _shown = [0, 1, 2, 3, 4];
  int _nextKind = _slots;
  int _nextSlot = 1;
  Timer? _timer;

  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _entrance.forward();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 3400), (_) {
      if (!mounted) return;
      setState(() {
        _shown[_nextSlot] = _nextKind % InspectKind.decideOrder.length;
        // Skip kinds already on screen.
        do {
          _nextKind++;
        } while (_shown.contains(_nextKind % InspectKind.decideOrder.length));
        _nextSlot = (_nextSlot + 1) % _slots;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(int slot, {bool big = false}) {
      final kind = InspectKind.decideOrder[_shown[slot]];
      // Page turning in from its left edge, slightly after the one before.
      final turnIn = CurvedAnimation(
        parent: _entrance,
        curve: Interval(
          slot * 0.13,
          slot * 0.13 + 0.48,
          curve: Curves.easeOutCubic,
        ),
      );
      return AnimatedBuilder(
        animation: turnIn,
        builder: (context, child) => Opacity(
          opacity: turnIn.value < 0.02 ? 0 : 1,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY((1 - turnIn.value) * math.pi / 2),
            child: child,
          ),
        ),
        child: _PageTurn(
          child: _BentoTile(
            key: ValueKey(kind),
            kind: kind,
            big: big,
            onTap: () => context.push('/inspect/${kind.name}'),
          ),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          SizedBox(
            height: 196,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(0, big: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(1)),
                      const SizedBox(height: 10),
                      Expanded(child: tile(2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: tile(3)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: tile(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// When its child changes, the old one lifts away from its left edge like
/// a turning page, uncovering the new one underneath.
class _PageTurn extends StatelessWidget {
  const _PageTurn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 750),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.easeInOutCubic,
      // The page being turned sits on top of the new one.
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [?current, ...previous]),
      transitionBuilder: (child, animation) {
        if (child.key == this.child.key) return child;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final turn = 1 - animation.value;
            return Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-turn * math.pi / 2),
              // Darkens as it turns away from the light.
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: turn * 0.35),
                  BlendMode.srcATop,
                ),
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    super.key,
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
  static const pinnedHeight = height + 82;

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
