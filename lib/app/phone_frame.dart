import 'package:flutter/material.dart';

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

    return ColoredBox(color: const Color(0xFFDCE8E8), child: _frame(mq));
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
