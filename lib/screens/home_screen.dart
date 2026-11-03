import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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
        padding: const EdgeInsets.fromLTRB(34, 34, 34, 18),
        child: GlassSearchField(
          hint: 'Search for a location',
          onTap: () => context.push('/explore'),
        ),
      ),
      // The title is painted last, in front of the cards and their glow.
      Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: _titleH + 8),
            child: _DecideCarousel(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              height: _titleH,
              child: SectionHeader(
                'See Before You Decide',
                centered: true,
                onSeeAll: () => context.push('/decide'),
              ),
            ),
          ),
        ],
      ),
    ];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final sheetTop = _sheetTop(context);
    final dark = AppColors.dark;

    return Scaffold(
      body: DecoratedBox(
        // White into a fresh mint, so the whole page reads green and glossy.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [AppColors.background, AppColors.background]
                : const [Colors.white, _pageMint],
          ),
        ),
        child: Stack(
          children: [
            // The rotating photos fill the screen; the frosted sheet blurs
            // them below the header.
            const Positioned.fill(child: _PhotoHero()),
            // One liquid-glass sheet from just over the photos all the way
            // down past the bottom edge, under everything else on Home.
            Positioned(
              left: 0,
              right: 0,
              top: sheetTop,
              bottom: -_sheetRadius,
              // Not faded in: a fade layer would hide the photos from the
              // glass's blur.
              child: const _FrostedSheet(),
            ),
            // The search bar and cards scroll inside the sheet, above the
            // pinned country globe.
            Positioned(
              left: 0,
              right: 0,
              top: sheetTop,
              bottom:
                  bottomInset +
                  _CountryGlobe.pinnedHeight +
                  _PinnedCountries.lift,
              child: ListView(
                padding: EdgeInsets.zero,
                // Let the cards' glow fade out past the bottom edge
                // instead of being cut off in a hard line.
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    _Reveal(animation: _entrance, index: i, child: sections[i]),
                ],
              ),
            ),
            // Pinned to the bottom so the globe is always on screen. Not
            // faded in: the intro's globe lands right on it.
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

/// Height of a section title row.
const _titleH = 34.0;

/// Corner radius of the glass sheet over the photos.
const _sheetRadius = 30.0;

/// Control Center–style glass over the photos: clear and lightly frosted,
/// so the photos glow through, with a soft light-catching rim that blends
/// into the page instead of a hard border.
class _FrostedSheet extends StatelessWidget {
  const _FrostedSheet();

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_sheetRadius),
        boxShadow: const [
          // A soft mint glow spilling out from the edge.
          BoxShadow(color: Color(0x8C5BC6C2), blurRadius: 22, spreadRadius: 1),
          BoxShadow(color: Color(0x14000000), blurRadius: 14),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_sheetRadius),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ColorFilter.matrix(_saturate(1.3, 1.2)),
            inner: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          ),
          child: CustomPaint(
            foregroundPainter: const FrostRimPainter(
              radius: _sheetRadius,
              width: 1.8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // White in the middle, spreading out to green at the edges.
                gradient: dark
                    ? const LinearGradient(
                        colors: [Color(0x990B1A1F), Color(0x800B1A1F)],
                      )
                    : const RadialGradient(
                        center: Alignment(0, -0.6),
                        radius: 1.7,
                        // The aqua of cut glass, as in the app icon.
                        colors: [
                          Color(0xB3EFFBFA),
                          Color(0x99D3F1EE),
                          Color(0x8CB2E3DF),
                          Color(0xA68ED2CD),
                        ],
                        stops: [0, 0.3, 0.68, 1],
                      ),
              ),
              child: const Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: CustomPaint(painter: _SheetGlossPainter()),
                  ),
                  // Twinkling glints riding the top rim.
                  IgnorePointer(
                    child: GlassSparkles(
                      radius: _sheetRadius,
                      spots: [
                        SparkleSpot(0.12, 0, 0, 3, 15, 0),
                        SparkleSpot(0.5, 0, 0, 2.5, 11, 1.3),
                        SparkleSpot(0.86, 0, 0, 3, 14, 0.7),
                        SparkleSpot(0, 3, 0.06, 0, 10, 2.0),
                        SparkleSpot(1, -3, 0.08, 0, 10, 1.6),
                      ],
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

/// Saturation and brightness, like CSS `saturate() brightness()`.
List<double> _saturate(double s, double b) {
  const r = 0.2126, g = 0.7152, bl = 0.0722;
  return [
    (r + (1 - r) * s) * b, (g - g * s) * b, (bl - bl * s) * b, 0, 0, //
    (r - r * s) * b, (g + (1 - g) * s) * b, (bl - bl * s) * b, 0, 0,
    (r - r * s) * b, (g - g * s) * b, (bl + (1 - bl) * s) * b, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// The sheet's gloss: a soft white sheen fading down from the top edge.
class _SheetGlossPainter extends CustomPainter {
  const _SheetGlossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // A thick bevelled glass rim, like a cut glass slab: a bright outer
    // edge, an aqua refraction band, a crisp inner bevel line and a
    // darker teal edge just inside it.
    RRect inset(double d) => RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(d),
      Radius.circular(math.max(_sheetRadius - d, 4)),
    );
    const band = 10.0;
    canvas.drawRRect(
      inset(band / 2 + 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x99C9F4F1), Color(0x8C5DBDBA), Color(0x997FD0CC)],
        ).createShader(Offset.zero & size)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Bright outer edge.
    canvas.drawRRect(
      inset(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.95),
    );
    // Inner bevel: a bright line with a darker teal edge just inside.
    canvas.drawRRect(
      inset(band + 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );
    canvas.drawRRect(
      inset(band + 3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF2E8C8E).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Light streaks caught in the rim's glass.
    void streak(Rect r, {bool vertical = false}) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(r)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    final w = size.width;
    streak(Rect.fromLTWH(w * 0.18, 9, w * 0.3, 3.5));
    streak(Rect.fromLTWH(w * 0.6, 10, w * 0.22, 2.5));
    streak(Rect.fromLTWH(6, 70, 3.5, 160), vertical: true);
    streak(Rect.fromLTWH(w - 10, 110, 3, 200), vertical: true);

    // Layered strokes along the top of the rim, like thick cut glass:
    // bright white lines with thin teal refraction lines between them,
    // fading out as they run down the sides.
    final h = size.height;
    // Bright at the top, then catching the light in bands down the sides,
    // like the streaky rim of thick glass.
    final rimFade = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        Color(0x8CFFFFFF),
        Color(0xE6FFFFFF),
        Color(0x66FFFFFF),
        Color(0xCCFFFFFF),
        Color(0x4DFFFFFF),
      ],
      stops: [0, 0.12, 0.28, 0.45, 0.62, 1],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    void rimLine(double d, double width, Color color, double blur) {
      canvas.saveLayer(Offset.zero & size, Paint());
      canvas.drawRRect(
        inset(d),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = rimFade,
      );
      canvas.restore();
    }

    rimLine(3, 1.6, Colors.white.withValues(alpha: 0.95), 0.4);
    rimLine(5.2, 1.6, const Color(0xFF2E8C8E).withValues(alpha: 0.4), 0.8);
    rimLine(7.4, 1.3, Colors.white.withValues(alpha: 0.85), 0.4);
    rimLine(9.6, 1.4, const Color(0xFF2E8C8E).withValues(alpha: 0.3), 0.8);
    rimLine(12, 1.1, Colors.white.withValues(alpha: 0.75), 0.4);

    // Broken white highlights caught along the top edge.
    for (final (x, len, y) in [
      (0.10, 0.07, 4.5),
      (0.21, 0.13, 3.5),
      (0.40, 0.05, 6.5),
      (0.55, 0.16, 4.0),
      (0.78, 0.08, 7.0),
      (0.88, 0.05, 4.5),
    ]) {
      final seg = Rect.fromLTWH(w * x, y, w * len, 2.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(seg, const Radius.circular(1.3)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(seg)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7),
      );
    }

    // A pale reflection panel inside the top-right of the glass.
    final panel = Path()
      ..moveTo(w * 0.72, band + 4)
      ..lineTo(w - band - 6, band + 4)
      ..lineTo(w - band - 6, 96)
      ..lineTo(w * 0.86, 96)
      ..close();
    canvas.drawPath(
      panel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(w * 0.72, band, w * 0.28, 96))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Long white streaks running down both sides of the rim.
    for (final (x, y, len) in [
      (4.0, 0.16, 0.14),
      (8.0, 0.36, 0.2),
      (4.5, 0.62, 0.12),
      (w - 5.0, 0.2, 0.18),
      (w - 9.0, 0.46, 0.14),
      (w - 4.5, 0.7, 0.16),
    ]) {
      streak(Rect.fromLTWH(x - 1.5, h * y, 3, h * len), vertical: true);
    }

    // Curved white highlights inside both top corners.
    for (final left in [true, false]) {
      final c = inset(band + 4);
      final rr = c.tlRadiusX;
      final box = left
          ? Rect.fromLTWH(c.left, c.top, rr * 2, rr * 2)
          : Rect.fromLTWH(c.right - rr * 2, c.top, rr * 2, rr * 2);
      canvas.drawArc(
        box,
        left ? math.pi * 1.05 : math.pi * 1.5,
        math.pi * 0.45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    // White reflections like polished glass: a bright glint wrapping each
    // top corner, and a broad diagonal sheen across the upper glass.
    final r = _sheetRadius;
    void cornerGlint(bool left) {
      final x0 = left ? 3.0 : w - 3.0;
      final dir = left ? 1.0 : -1.0;
      final arc = Path()
        ..moveTo(x0, r + 46)
        ..lineTo(x0, r)
        ..quadraticBezierTo(x0, 3, x0 + dir * r, 3)
        ..lineTo(x0 + dir * (r + 70), 3);
      canvas.drawPath(
        arc,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }

    cornerGlint(true);
    cornerGlint(false);
    final sheenPath = Path()
      ..moveTo(0, 150)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.72, 0)
      ..lineTo(0, 240)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w * 0.72, 240))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final sheen = Rect.fromLTWH(0, 0, size.width, 80);
    canvas.drawRect(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(sheen),
    );
    // A shining reflection along the top edge: a soft mint bloom under a
    // bright white-and-green line.
    final line = Rect.fromLTRB(
      _sheetRadius * 0.9,
      3,
      size.width - _sheetRadius * 0.9,
      6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line.inflate(3), const Radius.circular(5)),
      Paint()
        ..color = const Color(0xB33FD6A0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF8FFFCF),
            Colors.white,
            Color(0xFF3FD6A0),
            Colors.white,
            Color(0xFF8FFFCF),
            Colors.transparent,
          ],
        ).createShader(line),
    );
    // Liquid glass: a curved specular highlight bending round the top-left
    // corner, and a fainter reflection along the right edge.
    final spec = Path()
      ..moveTo(_sheetRadius * 0.55, 46)
      ..quadraticBezierTo(4, 10, _sheetRadius + 18, 6)
      ..lineTo(w * 0.42, 6);
    canvas.drawPath(
      spec,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w * 0.42, 46))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final side = Rect.fromLTWH(w - 10, 60, 4, 220);
    canvas.drawRRect(
      RRect.fromRectAndRadius(side, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(side)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_SheetGlossPainter old) => false;
}

/// The mint the page fades to at the bottom, behind the country globe.
const _pageMint = Color(0xFFE6F7EE);

/// Where the content sheet starts, under the photo header.
double _sheetTop(BuildContext context) =>
    math.max(MediaQuery.paddingOf(context).top, 24.0) +
    HomeHeroLayout.height -
    HomeHeroLayout.sheetOverlap;

/// "Explore by Country" header over the globe, on a backdrop that fades in
/// from the page above so cards scroll softly under it.
class _PinnedCountries extends StatelessWidget {
  const _PinnedCountries({required this.reveal, required this.bottomInset});

  /// Shifts the globe up (positive) or down (negative) against the tab bar.
  static const lift = -52.0;

  final Animation<double> reveal;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    // No backdrop of its own: it sits straight on the glass sheet.
    // The title is painted last, in front of the globe and its bubbles.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16 + _titleH),
          child: SizedBox(
            height: _CountryGlobe.height + lift + bottomInset,
            child: _CountryGlobe(reveal: reveal),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: reveal,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: SizedBox(
              height: _titleH,
              child: SectionHeader(
                'Explore by Country',
                centered: true,
                onSeeAll: () => context.push('/explore'),
              ),
            ),
          ),
        ),
      ],
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
  static const height = 190.0;

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
    return Stack(
      fit: StackFit.expand,
      children: [
        // One still photo behind the glass card, so the card stays steady
        // while the header photos rotate above it.
        Photo(_slides.first.$1.hero, icon: _slides.first.$1.icon),
        PageView.builder(
          controller: _controller,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => context.push('/inspect/${_slides[i].$1.name}'),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Only the header rotates; its own crop keeps it crisp.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: top + HomeHeroLayout.height,
                  child: Photo(
                    _slides[i].$1.hero,
                    icon: _slides[i].$1.icon,
                    alignment: _slides[i].$2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: top + HomeHeroLayout.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // One smooth wash: light at the top for the status bar and
              // greeting, deep teal under the headline.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66063A2A),
                        Color(0x14063A2A),
                        Color(0x8C063A2A),
                        Color(0xB3063A2A),
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
                          fontSize: 20,
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
                          fontSize: 27,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Know before you go.',
                        style: AppText.display.copyWith(
                          color: const Color(0xFF7BF5C2),
                          fontSize: 27,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Send a local Guide to inspect any place,\n'
                        'before you spend your time or money.',
                        style: AppText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
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
                              ? const Color(0xFF4BE3A4)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

/// "See Before You Decide" flip book: the cards turn left and right over a
/// spine, like a book's pages, with the next ones fanned out underneath.
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

  // One swipe of this width turns one page.
  final _controller = PageController(viewportFraction: 0.72);

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

  /// Page height, sized in [build] so the deck fits between the section
  /// title and the country globe.
  double _pageH = 180;

  /// Room above and below the pages, for their shadows.
  static const _pad = 8.0;
  double get _deckH => _pageH + _pad * 2;

  /// Page width, as a share of the row: small enough that the pages
  /// waiting underneath show plenty of themselves.
  static const _pageW = 0.72;

  /// How many pages wait underneath, and how far each steps out to the
  /// right of the one above it.
  static const _under = 2;
  static const _step = 18.0;

  /// The whole stack is nudged left by half the fan, so it sits centred.
  static const _shift = _under * _step / 2;

  /// One page at a time turns over a spine down its left edge, like a
  /// book's; the next pages wait underneath, fanned out to the right.
  Widget _bookCard(int i, double delta, double w) {
    final d = delta.abs();
    // Turned pages are gone; only the next few wait underneath.
    if (delta <= -1 || delta > _under + 0.5) {
      return const Positioned(left: 0, top: 0, child: SizedBox());
    }
    final double angle, dx, scale, opacity, shade;
    if (delta >= 0) {
      // Waiting underneath, each a little smaller and further right.
      final k = math.min(delta, _under.toDouble());
      angle = 0;
      dx = k * (_step + w * 0.035) - _shift;
      scale = 1 - k * 0.05;
      opacity = (_under + 0.5 - delta).clamp(0.0, 1.0);
      shade = k * 0.07;
    } else {
      // Turning over the spine, the free edge swinging across to the left.
      final t = Curves.easeInOut.transform(d);
      angle = -t * 1.9;
      dx = -_shift;
      scale = 1;
      opacity = 1 - Curves.easeIn.transform(((t - 0.7) / 0.3).clamp(0.0, 1.0));
      shade = math.sin(t * math.pi / 2) * 0.3;
    }
    return Positioned(
      left: 0,
      right: 0,
      top: _pad,
      height: _pageH,
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
                  const Color(0xFF06402F).withValues(alpha: shade),
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

  /// A brand-green glow behind the deck, heavily blurred so it spreads
  /// softly past the cards. Kept clear of the section title above.
  Widget _ambient() => Positioned(
    left: 0,
    right: 0,
    top: -4,
    bottom: -36,
    child: IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 26,
          sigmaY: 26,
          tileMode: TileMode.decal,
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(14, 24, 14, 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              // Deepest behind the front card, lightening to pale mint as
              // it spreads out.
              gradient: RadialGradient(
                center: Alignment(-0.25, 0),
                radius: 0.95,
                colors: [
                  Color(0xD914A37C),
                  Color(0x8C2FD39A),
                  Color(0x407BEBC2),
                  Color(0x14B7FFE0),
                ],
                stops: [0, 0.4, 0.75, 1],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// A page with a polished crystal finish: a clear-coat glare, luminous
  /// green rims, a glossy top reflection and twinkling sparkles.
  Widget _glassPage(int i) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF06402F).withValues(alpha: 0.16),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF1FC98E).withValues(alpha: 0.35),
          blurRadius: 16,
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _FlipPageCard(page: _pages[i], compact: true),
        const IgnorePointer(
          child: CustomPaint(painter: _CrystalCardPainter(radius: 18)),
        ),
        const GlassSparkles(
          radius: 18,
          spots: [
            SparkleSpot(0.22, 0, 0, 3, 14, 0.3),
            SparkleSpot(0, -3, 0.46, 5, 10, 1.4),
            SparkleSpot(0.82, 0, 1, -2, 12, 2.1),
          ],
        ),
      ],
    ),
  );

  void _turn(int by) {
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
    // globe: search 34 + 58 + 18, title 34 + 8, less 10 the deck may reach
    // into the gap above the globe's title.
    final globe = _CountryGlobe.pinnedHeight + _PinnedCountries.lift;
    final room =
        mq.size.height - _sheetTop(context) - mq.padding.bottom - 142 - globe;
    _pageH = (room - _pad * 2).clamp(120.0, 262.0);
    // Any room left over goes evenly above and below the deck.
    final spare = math.max(0.0, room - _deckH);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spare / 2),
      child: SizedBox(
        height: _deckH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth * _pageW;
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final page =
                        _controller.hasClients &&
                            _controller.position.haveDimensions
                        ? _controller.page!
                        : 0.0;
                    // Farthest underneath first; the page being turned stays
                    // on top for the whole turn.
                    int depth(int i) => i - page < 0 ? 1 : 0;
                    final order = List.generate(_pages.length, (i) => i)
                      ..sort((a, b) {
                        final byDepth = depth(a).compareTo(depth(b));
                        if (byDepth != 0) return byDepth;
                        return (b - page).abs().compareTo((a - page).abs());
                      });
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Brand-green glow spread out behind the deck.
                        _ambient(),
                        for (final i in order) _bookCard(i, i - page, w),
                        // The glossy green spine down the book's left edge.
                        Positioned(
                          left: (constraints.maxWidth - w) / 2 - _shift - 3,
                          width: 5,
                          top: _pad + 10,
                          height: _pageH - 20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFFB7FFE0),
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x66FFFFFF),
                                  Colors.white,
                                  Color(0xFFC6F7E2),
                                  Colors.white,
                                  Color(0x66FFFFFF),
                                ],
                                stops: [0, 0.3, 0.55, 0.75, 1],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2FD39A)
                                      .withValues(alpha: 0.6),
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
            // Invisible pages on top take the left and right swipes and taps.
            PageView.builder(
              controller: _controller,
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
              left: 4,
              top: _deckH / 2 - 19,
              child: _GlassArrow(
                icon: Icons.chevron_left_rounded,
                label: 'Previous',
                onPressed: () => _turn(-1),
              ),
            ),
            Positioned(
              right: 4,
              top: _deckH / 2 - 19,
              child: _GlassArrow(
                icon: Icons.chevron_right_rounded,
                label: 'Next',
                onPressed: () => _turn(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round liquid-glass arrow, in the same glass as the search and tab
/// bars.
class _GlassArrow extends StatelessWidget {
  const _GlassArrow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  static const _size = 38.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: LiquidGlass(
          radius: _size / 2,
          height: _size,
          thin: true,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(icon, size: 22, color: const Color(0xFF1F6B70)),
          ),
        ),
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
                    Color(0x1FFFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x00063A2A),
                    Color(0xB3063A2A),
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
                        Color(0x1FFFFFFF),
                        Color(0x00FFFFFF),
                        Color(0x00063A2A),
                        Color(0xB3063A2A),
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
    // A thick glass rim along the curve, like the background card's: a
    // bright outer line, an aqua glass band, a thin teal refraction line,
    // a white inner bevel, and a glint near the top.
    if (!AppColors.dark) {
      void ring(double r, double width, Color color, double blur) =>
          canvas.drawCircle(
            globeCenter,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..color = color.withValues(alpha: color.a * t)
              ..maskFilter = blur > 0
                  ? MaskFilter.blur(BlurStyle.normal, blur)
                  : null,
          );
      // A soft aqua glow hugging the edge, then a thin glass rim.
      ring(arcRadius - 1, 6, const Color(0x737FE3DD), 5);
      ring(arcRadius - 2.5, 4, const Color(0x80B5E8E4), 1);
      ring(arcRadius - 0.6, 1.2, const Color(0xF2FFFFFF), 0.3);
      ring(arcRadius - 4.6, 0.9, const Color(0xB3FFFFFF), 0.4);
      canvas.drawArc(
        band.deflate(1.5),
        -math.pi * 0.62,
        math.pi * 0.14,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.95 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
      // Sparkles: four-point star glints with a soft halo along the edge.
      for (final (angle, size) in [
        (-0.78, 9.0),
        (-0.64, 6.0),
        (-0.5, 11.0),
        (-0.37, 7.0),
        (-0.24, 9.0),
      ]) {
        final a = math.pi * angle;
        final c =
            globeCenter + Offset(math.cos(a), math.sin(a)) * (arcRadius - 1);
        canvas.drawCircle(
          c,
          size * 0.55,
          Paint()
            ..color = const Color(0xFFB5F5EF).withValues(alpha: 0.7 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        final star = Path()
          ..moveTo(c.dx, c.dy - size)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + size, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + size)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - size, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - size)
          ..close();
        canvas.drawPath(
          star,
          Paint()..color = Colors.white.withValues(alpha: 0.95 * t),
        );
      }
    }
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
                    color: const Color(0xFF2FD39A)
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
            Colors.white.withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0.05),
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
        ..color = const Color(0xFFB7FFE0).withValues(alpha: 0.9),
    );
    // A crisp green keyline right on the edge, so the card reads sharp.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF0E8A6E).withValues(alpha: 0.6),
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
        ..color = const Color(0x993FD6A0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF8FFFCF),
            Colors.white,
            Color(0xFF3FD6A0),
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
