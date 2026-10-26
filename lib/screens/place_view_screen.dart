import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/city_intro.dart';
import '../widgets/common.dart';
import '../widgets/panorama_viewer.dart';
import '../widgets/zoomable_video.dart';

class PlaceViewScreen extends StatefulWidget {
  const PlaceViewScreen({
    super.key,
    required this.city,
    required this.kind,
    this.showIntro = false,
  });

  final City city;
  final InspectKind kind;

  /// Plays the globe-to-city fly-in on top while the view loads.
  final bool showIntro;

  @override
  State<PlaceViewScreen> createState() => _PlaceViewScreenState();
}

class _PlaceViewScreenState extends State<PlaceViewScreen> {
  late InspectKind _kind = widget.kind;
  // Three checks start selected so the price summary has content.
  late Set<InspectCheck> _selected = _kind.checks.take(3).toSet();
  late bool _intro = widget.showIntro;

  void _toggle(InspectCheck check) => setState(() {
    if (!_selected.remove(check)) _selected.add(check);
  });

  void _setKind(InspectKind kind) => setState(() {
    _kind = kind;
    _selected = kind.checks.take(3).toSet();
  });

  @override
  Widget build(BuildContext context) {
    final city = widget.city, kind = _kind;
    return Stack(
      children: [
        Scaffold(
          body: AquaBackground(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _LiveViewer(city: city),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kind.placeTitle(city.area), style: AppText.display),
                      const SizedBox(height: 6),
                      Text(kind.placeSubtitle, style: AppText.body),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                IntentChips(selected: kind, onTap: _setKind),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Watch a sample'),
                      const SizedBox(height: 10),
                      _SampleVideo(image: city.image),
                      const SizedBox(height: 28),
                      const SectionHeader(
                        'What should your Guide check?',
                        subtitle: 'Pick as many as you like.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final check in kind.checks)
                            ChoicePill(
                              label: check.label,
                              icon: check.icon,
                              selected: _selected.contains(check),
                              showCheck: true,
                              onTap: () => _toggle(check),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const SectionHeader('Guides available now'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: guidesNearby.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) =>
                        _GuideCard(guide: guidesNearby[i]),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _PricingRow(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Full refund if your Guide doesn't join.",
                        style: AppText.small.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _RequestBar(
            checks: _selected.length,
            onRequest: () => _confirm(context),
          ),
        ),
        if (_intro)
          Positioned.fill(
            child: CityIntro(
              city: city,
              onDone: () {
                if (mounted) setState(() => _intro = false);
              },
            ),
          ),
      ],
    );
  }

  void _confirm(BuildContext context) {
    final checks = _kind.checks.where(_selected.contains).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review your request', style: AppText.title),
              const SizedBox(height: 4),
              Text(_kind.placeTitle(widget.city.area), style: AppText.body),
              const SizedBox(height: 16),
              for (final c in checks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Text(c.label, style: AppText.label),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${Pricing.baseMinutes} min live session',
                      style: AppText.body,
                    ),
                  ),
                  Text('AED ${Pricing.base}', style: AppText.section),
                ],
              ),
              const SizedBox(height: 16),
              GlossyButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showComingSoon(context, 'Payment');
                },
                child: const Text('Continue to payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top of the place view: the drag-to-look panorama, plus a real recorded
/// walk video where one is available.
class _LiveViewer extends StatefulWidget {
  const _LiveViewer({required this.city});

  final City city;

  @override
  State<_LiveViewer> createState() => _LiveViewerState();
}

class _LiveViewerState extends State<_LiveViewer> {
  bool _video = false;

  void _openFullScreen(BuildContext context) {
    final city = widget.city;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, _) => _FullScreenView(
          city: city,
          video: _video && city.walkVideoId != null,
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    final videoId = city.walkVideoId;
    final top = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              Positioned.fill(
                child: _video && videoId != null
                    ? Padding(
                        padding: EdgeInsets.only(top: top + 56),
                        child: ZoomableVideo(
                          url: _walkUrl(videoId),
                          onExpand: () => _openFullScreen(context),
                        ),
                      )
                    : PanoramaViewer(
                        image: city.panorama ?? city.image,
                        spanDegrees: city.panoramaSpan,
                        hotspots: city.hotspots,
                        initialX: city.panorama == null ? 0.5 : 0.36,
                        onExpand: () => _openFullScreen(context),
                      ),
              ),
              if (_video)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: top + 56,
                  child: const ColoredBox(color: AppColors.ink),
                )
              else
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Scrim(top: true, strength: 0.4),
                ),
              const TopBackButton(),
              if (videoId != null)
                Positioned(
                  top: top + 8,
                  right: 16,
                  child: _ViewToggle(
                    video: _video,
                    onChanged: (v) => setState(() => _video = v),
                  ),
                ),
              if (!_video)
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: _Badge(
                    icon: Icons.threesixty,
                    text: 'Free preview · drag to explore',
                  ),
                ),
            ],
          ),
        ),
        if (_video && city.walkVideoCredit != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 16,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Real recorded walk · ${city.walkVideoCredit}',
                    style: AppText.small,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _walkUrl(String videoId) =>
    'https://www.youtube-nocookie.com/embed/$videoId'
    '?autoplay=1&mute=1&playsinline=1&rel=0&start=90';

/// Full-screen 360° view or walk video, with free one-finger looking.
class _FullScreenView extends StatelessWidget {
  const _FullScreenView({required this.city, required this.video});

  final City city;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    void close() => Navigator.of(context).pop();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            top: video ? top + 56 : 0,
            child: video
                ? ZoomableVideo(
                    url: _walkUrl(city.walkVideoId!),
                    onExpand: close,
                    expanded: true,
                  )
                : PanoramaViewer(
                    image: city.panorama ?? city.image,
                    spanDegrees: city.panoramaSpan,
                    hotspots: city.hotspots,
                    initialX: city.panorama == null ? 0.5 : 0.36,
                    insideScrollView: false,
                    onExpand: close,
                    expanded: true,
                  ),
          ),
          const TopBackButton(),
        ],
      ),
    );
  }
}

/// Glass segmented control in the screenshots' glossy style.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.video, required this.onChanged});

  final bool video;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, IconData icon, bool selected, bool value) {
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5BAEB4),
                      AppColors.teal,
                      AppColors.tealDark,
                    ],
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.small.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment('360° view', Icons.threesixty, !video, false),
          segment('Walk video', Icons.play_circle_outline, video, true),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppText.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muted 15-second sample clip. In this prototype the "video" is the city
/// photo with a slow pan while the progress bar runs.
class _SampleVideo extends StatefulWidget {
  const _SampleVideo({required this.image});

  final String image;

  @override
  State<_SampleVideo> createState() => _SampleVideoState();
}

class _SampleVideoState extends State<_SampleVideo>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 15))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) setState(() {});
        });

  bool get _playing => _controller.isAnimating;

  void _toggle() => setState(() {
    if (_playing) {
      _controller.stop();
    } else {
      _controller.forward(from: _controller.isCompleted ? 0 : null);
    }
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _playing ? 'Pause sample' : 'Play 15 second sample',
      child: GestureDetector(
        onTap: _toggle,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final secondsLeft = (15 * (1 - t)).ceil();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.scale(
                      scale: 1 + 0.15 * t,
                      alignment: Alignment(-0.6 + 1.2 * t, 0),
                      child: Photo(widget.image, icon: Icons.videocam_outlined),
                    ),
                    const Scrim(strength: 0.55),
                    if (!_playing)
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 34,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _OverlayChip(
                        icon: Icons.videocam_outlined,
                        text:
                            'Sample · 0:${secondsLeft.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const Positioned(
                      right: 12,
                      top: 12,
                      child: _OverlayChip(
                        icon: Icons.volume_off,
                        text: 'Muted',
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: t,
                          minHeight: 3,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppText.small.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final km = guide.distanceKm == guide.distanceKm.roundToDouble()
        ? guide.distanceKm.toStringAsFixed(0)
        : guide.distanceKm.toStringAsFixed(1);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
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
              GuideAvatar(guide, size: 44, online: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.name,
                      style: AppText.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Rating(guide.rating, reviews: guide.reviews),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.translate, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  guide.languages.join(', '),
                  style: AppText.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Online · $km km away',
                style: AppText.small.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow();

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.small),
          const SizedBox(height: 2),
          Text(value, style: AppText.label),
        ],
      ),
    );
    Widget divider() => Container(
      width: 1,
      height: 32,
      color: AppColors.teal.withValues(alpha: 0.2),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tealTint,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          cell('From', 'AED ${Pricing.base}'),
          divider(),
          cell('Session', '${Pricing.baseMinutes} min'),
          divider(),
          cell('Extra ${Pricing.extraMinutes} min', 'AED ${Pricing.extra}'),
        ],
      ),
    );
  }
}

class _RequestBar extends StatelessWidget {
  const _RequestBar({required this.checks, required this.onRequest});

  final int checks;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: GlossyButton(
        onPressed: checks == 0 ? null : onRequest,
        child: Text(
          checks == 0
              ? 'Pick at least one check'
              : 'Request Guide · $checks ${checks == 1 ? 'check' : 'checks'} · AED ${Pricing.base}',
        ),
      ),
    );
  }
}
