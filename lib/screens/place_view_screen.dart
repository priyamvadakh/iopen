import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../data/user_store.dart';
import '../widgets/city_intro.dart';
import '../widgets/common.dart';
import '../widgets/help_sheet.dart';
import '../widgets/panorama_viewer.dart';
import '../widgets/zoomable_video.dart';

class PlaceViewScreen extends StatefulWidget {
  const PlaceViewScreen({
    super.key,
    required this.city,
    required this.kind,
    this.showIntro = false,
    this.areaId,
  });

  final City city;
  final InspectKind kind;

  /// Plays the globe-to-city fly-in on top while the view loads.
  final bool showIntro;

  /// Neighbourhood to open; defaults to the city's main area.
  final String? areaId;

  @override
  State<PlaceViewScreen> createState() => _PlaceViewScreenState();
}

class _PlaceViewScreenState extends State<PlaceViewScreen> {
  late InspectKind _kind = widget.kind;
  // Three checks start selected so the price summary has content.
  late Set<InspectCheck> _selected = _kind.checks.take(3).toSet();
  late bool _intro = widget.showIntro;
  late Area _area = widget.city.areaById(widget.areaId);

  @override
  void initState() {
    super.initState();
    _remember();
  }

  void _remember() =>
      UserStore.instance.rememberView(widget.city, _area, _kind);

  void _toggle(InspectCheck check) => setState(() {
    if (!_selected.remove(check)) _selected.add(check);
  });

  /// Lets the user switch city without going back, keeping the intent.
  Future<void> _pickDestination(BuildContext context) async {
    final picked = await showModalBottomSheet<_Destination>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) =>
          _DestinationSheet(city: widget.city, currentArea: _area),
    );
    if (picked == null || !context.mounted) return;
    if (picked.city.id == widget.city.id) {
      // Same city: swap the neighbourhood in place.
      _setArea(picked.area);
    } else {
      context.pushReplacement('/city/${picked.city.id}?intent=${_kind.name}');
    }
  }

  void _setArea(Area area) {
    if (area.id == _area.id) return;
    setState(() => _area = area);
    _remember();
  }

  void _setKind(InspectKind kind) {
    setState(() {
      _kind = kind;
      _selected = kind.checks.take(3).toSet();
    });
    _remember();
  }

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
                _LiveViewer(key: ValueKey(_area.id), area: _area),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DestinationPill(
                        city: city,
                        area: _area,
                        onTap: () => _pickDestination(context),
                      ),
                      const SizedBox(height: 10),
                      Text(kind.placeTitle(_area.name), style: AppText.display),
                      const SizedBox(height: 6),
                      Text(kind.placeSubtitle, style: AppText.body),
                    ],
                  ),
                ),
                if (city.areas.length > 1) ...[
                  const SizedBox(height: 16),
                  _RowLabel('Areas in ${city.name}'),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: city.areas.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final area = city.areas[i];
                        return ChoicePill(
                          label: area.name,
                          icon: Icons.threesixty,
                          selected: area.id == _area.id,
                          onTap: () => _setArea(area),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const _RowLabel('What are you checking?'),
                IntentChips(selected: kind, onTap: _setKind),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Watch a sample'),
                      const SizedBox(height: 10),
                      _SampleVideo(image: _area.image),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (icon, text) in const [
                        (
                          Icons.verified_user_outlined,
                          'Pay only after your Guide joins.',
                        ),
                        (
                          Icons.event_available_outlined,
                          'Free cancellation until then.',
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(icon, size: 18, color: AppColors.teal),
                              const SizedBox(width: 8),
                              Text(
                                text,
                                style: AppText.small.copyWith(
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
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
              area: _area,
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
              Text(_kind.placeTitle(_area.name), style: AppText.body),
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
              const SizedBox(height: 4),
              Text(
                'Charged only after your Guide joins. Cancel free until then.',
                style: AppText.small,
              ),
              const SizedBox(height: 16),
              GlossyButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _sendRequest(context, checks);
                },
                child: const Text('Send request'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => showHelpSheet(context),
                  child: const Text('Questions? How it works'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Records the request and confirms it with clear next steps.
  void _sendRequest(BuildContext context, List<InspectCheck> checks) {
    final guide = guidesNearby.reduce(
      (a, b) => a.joinMinutes <= b.joinMinutes ? a : b,
    );
    final session = BookedSession(
      city: widget.city,
      area: _area,
      kind: _kind,
      checks: checks,
      guide: guide,
    );
    UserStore.instance.addSession(session);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.tealTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 14),
              Text('Request sent', style: AppText.title),
              const SizedBox(height: 6),
              Text(
                '${guide.name} usually joins in about '
                '${guide.joinMinutes} minutes. We’ll notify you the moment '
                'they’re live.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    GuideAvatar(guide, size: 40, online: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kind.placeTitle(_area.name),
                            style: AppText.label,
                          ),
                          Text(
                            '${checks.length} checks · AED ${Pricing.base} '
                            'after they join',
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlossyButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/sessions');
                },
                child: const Text('View in Sessions'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
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
  const _LiveViewer({super.key, required this.area});

  final Area area;

  @override
  State<_LiveViewer> createState() => _LiveViewerState();
}

class _LiveViewerState extends State<_LiveViewer> {
  bool _video = false;

  void _openFullScreen(BuildContext context) {
    final area = widget.area;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, _) => _FullScreenView(
          area: area,
          video: _video && area.walkVideoId != null,
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final videoId = area.walkVideoId;
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
                        image: area.image,
                        spanDegrees: area.panoramaSpan,
                        hotspots: area.hotspots,
                        initialX: area.initialX,
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
        if (_video && area.walkVideoCredit != null)
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
                    'Real recorded walk · ${area.walkVideoCredit}',
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
  const _FullScreenView({required this.area, required this.video});

  final Area area;
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
                    url: _walkUrl(area.walkVideoId!),
                    onExpand: close,
                    expanded: true,
                  )
                : PanoramaViewer(
                    image: area.image,
                    spanDegrees: area.panoramaSpan,
                    hotspots: area.hotspots,
                    initialX: area.initialX,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guide.name,
                            style: AppText.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Tooltip(
                          message: 'ID verified',
                          child: Icon(
                            Icons.verified,
                            size: 15,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
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
                'Joins in ~${guide.joinMinutes} min · $km km',
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

class _DestinationPill extends StatelessWidget {
  const _DestinationPill({
    required this.city,
    required this.area,
    required this.onTap,
  });

  final City city;
  final Area area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Destination ${area.name}, ${city.name}, change',
      child: Material(
        color: AppColors.tealTint,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 16, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  '${area.name}, ${city.name}',
                  style: AppText.label.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'Change',
                  style: AppText.label.copyWith(
                    fontSize: 13,
                    color: AppColors.teal,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.teal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Destination = ({City city, Area area});

/// Areas of the current city first, then other cities; searchable.
class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet({required this.city, required this.currentArea});

  final City city;
  final Area currentArea;

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  String _query = '';

  bool _matches(String text) =>
      _query.trim().isEmpty ||
      text.toLowerCase().contains(_query.trim().toLowerCase());

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(
      text.toUpperCase(),
      style: AppText.small.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  Widget _tile({
    required String image,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Photo(image, icon: Icons.location_city_outlined),
        ),
      ),
      title: Text(title, style: AppText.label),
      subtitle: Text(subtitle, style: AppText.small),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.chevron_right,
        color: selected ? AppColors.teal : AppColors.muted,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    final areas = [
      for (final a in city.areas)
        if (_matches('${a.name} ${city.name}')) a,
    ];
    final others = [
      for (final c in cities)
        if (c.id != city.id && _matches('${c.name} ${c.country} ${c.area}')) c,
    ];

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change destination', style: AppText.title),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search an area, city or country',
                    hintStyle: AppText.body,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: areas.isEmpty && others.isEmpty
                ? Center(
                    child: Text('No Guides there yet.', style: AppText.body),
                  )
                : ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 12,
                    ),
                    children: [
                      if (areas.isNotEmpty) ...[
                        _header('Areas in ${city.name}'),
                        for (final a in areas)
                          _tile(
                            image: a.image,
                            title: a.name,
                            subtitle: a.walkVideoId != null
                                ? '360° view · walk video'
                                : '360° view',
                            selected: a.id == widget.currentArea.id,
                            onTap: () => Navigator.pop<_Destination>(context, (
                              city: city,
                              area: a,
                            )),
                          ),
                      ],
                      if (others.isNotEmpty) ...[
                        _header('Other cities'),
                        for (final c in others)
                          _tile(
                            image: c.image,
                            title: '${c.name}, ${c.country}',
                            subtitle:
                                '${c.guidesOnline} Guides online · '
                                '${c.areas.length} '
                                '${c.areas.length == 1 ? 'area' : 'areas'}',
                            selected: false,
                            onTap: () => Navigator.pop<_Destination>(context, (
                              city: c,
                              area: c.areas.first,
                            )),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: AppText.small.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
