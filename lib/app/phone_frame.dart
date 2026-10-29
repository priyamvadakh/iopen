import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'open_page.dart';
import 'theme.dart';

/// On wide screens (a laptop browser during a demo), shows the app inside an
/// iPhone-sized 390×844 frame. On phones it renders full screen.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const _size = Size(390, 844);
  static const _statusBar = 47.0;
  static const _homeIndicator = 34.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 600) return child;

    return ColoredBox(
      color: const Color(0xFFDCE8E8),
      child: Stack(
        children: [
          Positioned.fill(child: _frame(mq)),
          if (_showLayoutOptions && canOpenDemoPages)
            const Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: Center(child: _OptionsLink()),
            ),
        ],
      ),
    );
  }

  Widget _frame(MediaQueryData mq) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FittedBox(
          child: Container(
            width: _size.width + 24,
            height: _size.height + 24,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(58),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(46),
              child: MediaQuery(
                data: mq.copyWith(
                  size: _size,
                  padding: const EdgeInsets.only(
                    top: _statusBar,
                    bottom: _homeIndicator,
                  ),
                  viewPadding: const EdgeInsets.only(
                    top: _statusBar,
                    bottom: _homeIndicator,
                  ),
                ),
                child: Stack(
                  children: [
                    child,
                    // Dynamic Island.
                    Positioned(
                      top: 11,
                      left: (_size.width - 120) / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: 120,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    // Home indicator.
                    Positioned(
                      bottom: 8,
                      left: (_size.width - 134) / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: 134,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(3),
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
  }
}

/// Shows the "Options: 3 Home layouts" link beside the phone. Hidden on
/// the client demo; set to true to compare layouts again.
const _showLayoutOptions = false;

/// Glossy pill beside the phone that opens the three Home layouts.
class _OptionsLink extends StatelessWidget {
  const _OptionsLink();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Options: see three Home layouts',
      // Sits outside the app's pages, so it brings its own Material for
      // text styling.
      child: Material(
        type: MaterialType.transparency,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openDemoPage('variations.html'),
            child: Glass(
              radius: 24,
              gloss: true,
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.view_carousel_outlined,
                    size: 20,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Options', style: AppText.label),
                      Text('3 Home layouts', style: AppText.small),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const ArrowChip(size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
