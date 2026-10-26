import 'package:flutter/material.dart';

import 'common.dart';
import 'video_embed.dart';

/// Embedded video with zoom buttons (the player is scaled around its centre)
/// and an optional full-screen button.
class ZoomableVideo extends StatefulWidget {
  const ZoomableVideo({
    super.key,
    required this.url,
    this.onExpand,
    this.expanded = false,
  });

  final String url;
  final VoidCallback? onExpand;
  final bool expanded;

  @override
  State<ZoomableVideo> createState() => _ZoomableVideoState();
}

class _ZoomableVideoState extends State<ZoomableVideo> {
  static const _maxScale = 2.5;
  double _scale = 1;

  void _zoomBy(double factor) =>
      setState(() => _scale = (_scale * factor).clamp(1.0, _maxScale));

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 200),
            child: VideoEmbed(url: widget.url),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: ZoomControls(
              onZoomIn: _scale < _maxScale - 0.01 ? () => _zoomBy(1.25) : null,
              onZoomOut: _scale > 1.01 ? () => _zoomBy(1 / 1.25) : null,
              onExpand: widget.onExpand,
              expanded: widget.expanded,
            ),
          ),
        ),
      ],
    );
  }
}
