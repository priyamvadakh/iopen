import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Embedded web video (an iframe). Web-only; see video_embed_stub.dart.
class VideoEmbed extends StatelessWidget {
  const VideoEmbed({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: ValueKey(url),
      tagName: 'iframe',
      onElementCreated: (element) {
        final iframe = element as web.HTMLIFrameElement;
        iframe
          ..src = url
          ..allow = 'autoplay; encrypted-media; picture-in-picture'
          ..allowFullscreen = true
          ..referrerPolicy = 'strict-origin-when-cross-origin';
        iframe.style
          ..border = 'none'
          ..width = '100%'
          ..height = '100%';
      },
    );
  }
}
