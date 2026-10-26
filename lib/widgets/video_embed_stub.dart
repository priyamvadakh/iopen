import 'package:flutter/material.dart';

import '../app/theme.dart';

/// On iOS/Android the embedded video needs a WebView; until that is added,
/// show a calm placeholder.
class VideoEmbed extends StatelessWidget {
  const VideoEmbed({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Text(
          'Video plays in the web version.',
          style: AppText.body.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
