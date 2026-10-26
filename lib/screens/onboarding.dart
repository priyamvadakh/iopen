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
const _finaleStart = 5.3;
const _finaleEnd = 7.4;
const _total = 7.8;

/// "Anytime● → Anywhere● → iOpen●", then the dot grows into the globe,
/// which spins and glides into its place at the top of Home.
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
    if (now >= _finaleEnd) return;
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
        ? 1 - ((t - _finaleStart) / 0.3).clamp(0.0, 1.0)
        : ((_wordSeconds - local) / 0.25).clamp(0.0, 1.0);
    final dotPop = Curves.elasticOut.transform(
      ((local - 0.25) / 0.6).clamp(0.0, 1.0),
    );

    // Finale: the dot becomes the globe and lands where Home shows it.
    final f = ((t - _finaleStart) / (_finaleEnd - _finaleStart)).clamp(
      0.0,
      1.0,
    );
    if (f > 0 && _dotRect == null) _dotRect = _measureDot();
    final target = HomeHeroLayout.globeRect(size, top);
    final targetRadius = math.min(target.width, target.height) * 0.4;

    final children = <Widget>[
      Positioned.fill(child: ColoredBox(color: bg)),
      if (f > 0)
        Positioned.fill(
          child: Opacity(
            opacity: ((f - 0.05) / 0.3).clamp(0.0, 1.0),
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
                  child: const SpaceBackdrop(
                    radius: 0,
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                Opacity(
                  // Once the finale starts, the growing globe takes over.
                  opacity: f > 0 ? 0 : 1,
                  child: Transform.scale(
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
                ),
              ],
            ),
          ),
        ),
      ),
      if (f > 0) ..._globe(size, f, t, target.center, targetRadius),
      if (t < _finaleStart)
        Positioned(
          top: top + 8,
          right: 12,
          child: TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(foregroundColor: word.foreground),
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

  List<Widget> _globe(
    Size size,
    double f,
    double t,
    Offset targetCenter,
    double targetRadius,
  ) {
    final dot =
        _dotRect ??
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: 20,
          height: 20,
        );
    final grow = Curves.easeInOutCubic.transform((f / 0.35).clamp(0.0, 1.0));
    final land = Curves.easeInOutCubic.transform(
      ((f - 0.45) / 0.45).clamp(0.0, 1.0),
    );
    final bigRadius = math.min(size.width, size.height) * 0.34;
    final r1 = ui.lerpDouble(dot.width / 2, bigRadius, grow)!;
    final c1 = Offset.lerp(dot.center, size.center(Offset.zero), grow)!;
    final radius = ui.lerpDouble(r1, targetRadius, land)!;
    final center = Offset.lerp(c1, targetCenter, land)!;
    final globeIn = ((grow - 0.3) / 0.5).clamp(0.0, 1.0);
    // Spins fast, then settles on the exact view Home opens with.
    final settle = Curves.easeOutCubic.transform(f);
    final side = radius / 0.4;

    return [
      Positioned(
        left: center.dx - radius,
        top: center.dy - radius,
        width: radius * 2,
        height: radius * 2,
        child: Opacity(
          opacity: 1 - globeIn,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        rect: Rect.fromCenter(center: center, width: side, height: side),
        child: Opacity(
          opacity: globeIn,
          child: CustomPaint(
            painter: GlobePainter(
              assets: _assets,
              shader: _shader,
              viewLat: 5 + (HomeHeroLayout.globeLat - 5) * settle,
              viewLng: HomeHeroLayout.globeLng + 260 * (1 - settle),
              time: t,
              showArcs: f > 0.7,
            ),
          ),
        ),
      ),
    ];
  }
}
