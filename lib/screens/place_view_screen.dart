import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/content.dart';
import '../widgets/common.dart';

class PlaceViewScreen extends StatefulWidget {
  const PlaceViewScreen({super.key, required this.city, required this.kind});

  final City city;
  final InspectKind kind;

  @override
  State<PlaceViewScreen> createState() => _PlaceViewScreenState();
}

class _PlaceViewScreenState extends State<PlaceViewScreen> {
  // Three checks start selected so the price summary has content.
  late final Set<InspectCheck> _selected = widget.kind.checks.take(3).toSet();

  void _toggle(InspectCheck check) => setState(() {
    if (!_selected.remove(check)) _selected.add(check);
  });

  @override
  Widget build(BuildContext context) {
    final city = widget.city, kind = widget.kind;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PanoramaPreview(city: city),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.placeTitle(city.area), style: AppText.display),
                const SizedBox(height: 6),
                Text(kind.placeSubtitle, style: AppText.body),
                const SizedBox(height: 24),
                const SectionHeader('Watch a sample'),
                const SizedBox(height: 10),
                _SampleVideo(image: city.image),
                const SizedBox(height: 28),
                SectionHeader(
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
              itemBuilder: (context, i) => _GuideCard(guide: guidesNearby[i]),
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
      bottomNavigationBar: _RequestBar(
        checks: _selected.length,
        onRequest: () => _confirm(context),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final checks = widget.kind.checks.where(_selected.contains).toList();
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
              Text(
                widget.kind.placeTitle(widget.city.area),
                style: AppText.body,
              ),
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

/// Drag-to-explore panorama with hotspot pins that move with the image.
class _PanoramaPreview extends StatefulWidget {
  const _PanoramaPreview({required this.city});

  final City city;

  @override
  State<_PanoramaPreview> createState() => _PanoramaPreviewState();
}

class _PanoramaPreviewState extends State<_PanoramaPreview> {
  static const _height = 320.0;
  static const _widthFactor = 2.4;
  double? _offset;

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewW = constraints.maxWidth;
          final panoW = viewW * _widthFactor;
          final maxOffset = panoW - viewW;
          final offset = _offset ?? maxOffset / 2;

          return GestureDetector(
            onHorizontalDragUpdate: (d) => setState(
              () => _offset = (offset - d.delta.dx).clamp(0.0, maxOffset),
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -offset,
                    top: 0,
                    bottom: 0,
                    width: panoW,
                    child: Photo(
                      city.panorama ?? city.image,
                      icon: Icons.panorama_outlined,
                    ),
                  ),
                  const Positioned.fill(child: Scrim(top: true, strength: 0.5)),
                  const Positioned.fill(child: Scrim(strength: 0.45)),
                  for (final h in city.hotspots)
                    Positioned(
                      left: h.x * panoW - offset - 60,
                      top: h.y * _height - 40,
                      width: 120,
                      child: _HotspotPin(hotspot: h),
                    ),
                  const TopBackButton(),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.threesixty,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Free preview · drag to explore',
                            style: AppText.small.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
        },
      ),
    );
  }
}

class _HotspotPin extends StatelessWidget {
  const _HotspotPin({required this.hotspot});

  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hotspot.icon, size: 14, color: AppColors.teal),
              const SizedBox(width: 4),
              Text(
                hotspot.label,
                style: AppText.small.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(width: 2, height: 10, color: Colors.white),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
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
