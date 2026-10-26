import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/onboarding_state.dart';
import '../app/theme.dart';
import '../widgets/globe.dart';
import 'home_screen.dart';

class _Word {
  const _Word(this.text, this.background, this.foreground);

  final String text;
  final Color background;
  final Color foreground;
}

const _words = [
  _Word('Anytime', Color(0xFF1C2B3F), Color(0xFFA8E6E3)),
  _Word('Anywhere', Color(0xFF2A5866), Color(0xFF8FBAC0)),
  _Word('iOpen', Color(0xFFF7F9F9), AppColors.teal),
];

// Timeline, in seconds.
const _wordSeconds = 1.5;
const _revealStart = 4.6; // the dot floods the screen with a flat map
const _revealEnd = 5.2;
const _morphStart = 5.7; // the map wraps itself into the globe
const _morphEnd = 6.9;
const _finaleEnd = 7.8; // the globe has landed on Home
const _total = 8.2;

/// "Anytime● → Anywhere● → iOpen●", then the dot opens into a full-screen
/// map, the map wraps itself into the globe, and the globe glides into its
/// place at the top of Home.
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );
  final _dotKey = GlobalKey();
  Rect? _dotRect;
  GlobeAssets? _assets = GlobeAssets.loaded;
  late ui.FragmentShader? _shader = _assets?.program.fragmentShader();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    onboardingActive.value = true;
    _c.forward().whenComplete(_finish);
    if (_assets == null) {
      GlobeAssets.load().then((a) {
        if (mounted) {
          setState(() {
            _assets = a;
            _shader = a.program.fragmentShader();
          });
        }
      });
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    onboardingActive.value = false;
    widget.onDone();
  }

  /// Skips straight to Home with a quick fade.
  void _skip() {
    final now = _c.value * _total;
    if (now >= _morphEnd) return;
    _c.animateTo(1, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _c.dispose();
    _shader?.dispose();
    onboardingActive.value = false;
    super.dispose();
  }

  /// Where the dot after "iOpen" sits, so the globe can grow out of it.
  Rect? _measureDot() {
    final dot = _dotKey.currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (dot == null || me == null || !dot.hasSize) return null;
    return dot.localToGlobal(Offset.zero, ancestor: me) & dot.size;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) => _frame(size, top, _c.value * _total),
        );
      },
    );
  }

  Widget _frame(Size size, double top, double t) {
    // Background and current word.
    var bg = _words.first.background;
    for (var i = 1; i < _words.length; i++) {
      final start = i * _wordSeconds;
      if (t >= start) {
        bg = Color.lerp(
          _words[i - 1].background,
          _words[i].background,
          ((t - start) / 0.35).clamp(0.0, 1.0),
        )!;
      }
    }
    final index = math.min(_words.length - 1, (t / _wordSeconds).floor());
    final word = _words[index];
    final local = t - index * _wordSeconds;
    final last = index == _words.length - 1;
    final enter = Curves.easeOut.transform((local / 0.4).clamp(0.0, 1.0));
    final exit = last
        ? 1 - ((t - _revealStart) / 0.4).clamp(0.0, 1.0)
        : ((_wordSeconds - local) / 0.25).clamp(0.0, 1.0);
    final dotPop = Curves.elasticOut.transform(
      ((local - 0.25) / 0.6).clamp(0.0, 1.0),
    );

    if (t >= _revealStart && _dotRect == null) _dotRect = _measureDot();
    final revealed = t >= _revealEnd;
    final onMap = t >= _revealStart;

    final children = <Widget>[
      Positioned.fill(child: ColoredBox(color: bg)),
      // What Home's hero looks like, so the globe lands on a matching scene.
      if (revealed)
        Positioned.fill(
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF061C22)),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: top + HomeHeroLayout.height,
                child: const SpaceBackdrop(radius: 0, child: SizedBox.expand()),
              ),
              // With the light style the whole scene is white, matching Home.
              if (globeLight.value)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFF3FAF8)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (!revealed)
        Center(
          child: Opacity(
            opacity: enter * exit,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - enter)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word.text,
                    style: AppText.display.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: word.foreground,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Transform.scale(
                    scale: dotPop,
                    child: Container(
                      key: last ? _dotKey : null,
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: word.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (onMap) _earth(size, top, t),
      if (t < _morphEnd)
        Positioned(
          top: top + 8,
          right: 12,
          child: TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(
              foregroundColor: onMap
                  ? (globeLight.value ? AppColors.ink : Colors.white)
                  : word.foreground,
            ),
            child: const Text('Skip'),
          ),
        ),
    ];

    final fadeOut =
        1 - ((t - _finaleEnd) / (_total - _finaleEnd)).clamp(0.0, 1.0);
    // Material gives the text proper styling; this overlay sits above the
    // app's pages.
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        ignoring: t >= _finaleEnd,
        child: Opacity(
          opacity: fadeOut,
          child: Stack(children: children),
        ),
      ),
    );
  }

  double _landing(double t) => Curves.easeInOutCubic.transform(
    ((t - _morphEnd) / (_finaleEnd - _morphEnd)).clamp(0.0, 1.0),
  );

  /// The full-screen map opening out of the dot, wrapping into the globe and
  /// landing where Home shows it. One shader draws every stage.
  Widget _earth(Size size, double top, double t) {
    final screenCenter = size.center(Offset.zero);
    final dot =
        _dotRect ??
        Rect.fromCenter(center: screenCenter, width: 20, height: 20);

    // 1. The dot opens into the map like a lens.
    final reveal = Curves.easeInCubic.transform(
      ((t - _revealStart) / (_revealEnd - _revealStart)).clamp(0.0, 1.0),
    );
    final farthest = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - dot.center).distance).reduce(math.max);
    final hole = ui.lerpDouble(dot.width / 2, farthest, reveal)!;

    // 2. The flat map curves into a sphere and shrinks to globe size.
    final morph = Curves.easeInOutCubic.transform(
      ((t - _morphStart) / (_morphEnd - _morphStart)).clamp(0.0, 1.0),
    );
    final flatScale = size.height / 2 / 1.2; // pixels per radian
    final bigRadius = math.min(size.width, size.height) * 0.36;
    final r1 = flatScale * math.pow(bigRadius / flatScale, morph);

    // 3. The globe glides into Home's hero.
    final land = _landing(t);
    final target = HomeHeroLayout.globeRect(size, top);
    final targetRadius = math.min(target.width, target.height) * 0.4;
    final radius = ui.lerpDouble(r1, targetRadius, land)!;
    final center = Offset.lerp(screenCenter, target.center, land)!;

    // The view drifts east across the map towards the Gulf, then settles on
    // exactly what Home opens with.
    final drift = Curves.easeInOut.transform(
      ((t - _revealStart) / (_finaleEnd - _revealStart)).clamp(0.0, 1.0),
    );

    // While landing, the sheet's edge on Home tucks the globe's bottom away.
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      height: ui.lerpDouble(
        size.height,
        HomeHeroLayout.visibleBottom(top),
        land,
      ),
      child: ClipPath(
        clipper: _HoleClipper(dot.center, hole, enabled: reveal < 1),
        child: CustomPaint(
          painter: GlobePainter(
            assets: _assets,
            shader: _shader,
            viewLat: HomeHeroLayout.globeLat,
            viewLng: HomeHeroLayout.globeLng - 40 * (1 - drift),
            time: t,
            flat: 1 - morph,
            center: center,
            radius: radius,
            showArcs: land > 0.5,
            light: globeLight.value ? 1 : 0,
          ),
        ),
      ),
    );
  }
}

/// Circle that grows from the dot to reveal the map.
class _HoleClipper extends CustomClipper<Path> {
  _HoleClipper(this.center, this.radius, {required this.enabled});

  final Offset center;
  final double radius;
  final bool enabled;

  @override
  Path getClip(Size size) => enabled
      ? (Path()..addOval(Rect.fromCircle(center: center, radius: radius)))
      : (Path()..addRect(Offset.zero & size));

  @override
  bool shouldReclip(_HoleClipper old) =>
      old.center != center || old.radius != radius || old.enabled != enabled;
}
