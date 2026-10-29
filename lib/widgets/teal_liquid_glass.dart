import 'dart:ui';

import 'package:flutter/material.dart';

/// Transparent teal liquid glass: a lightly tinted body, a luminous outer
/// rim and a refractive inner rim, glossy reflections along the top and
/// bottom edges, and a soft sheen over the upper part.
class TealLiquidGlass extends StatelessWidget {
  final Widget child;
  final double height;

  const TealLiquidGlass({super.key, required this.child, this.height = 82});

  @override
  Widget build(BuildContext context) {
    const radius = 48.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Only a light teal glow: a dark shadow under clear glass shows
          // through it as a grey wash.
          BoxShadow(
            color: const Color(0xFF57D1C7).withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Stack(
            children: [
              // Transparent teal glass body
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF9FFFF1).withValues(alpha: 0.12),
                        const Color(0xFF57D1C7).withValues(alpha: 0.03),
                        const Color(0xFF3FAFA6).withValues(alpha: 0.02),
                        const Color(0xFF9FFFF1).withValues(alpha: 0.1),
                      ],
                      stops: const [0, 0.30, 0.72, 1],
                    ),
                  ),
                ),
              ),

              // Outer luminous glass rim
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: const Color(0xFFB7FFF4),
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Inner refractive glass rim
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(43),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.68),
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Glossy upper edge
              const Positioned(
                top: 3,
                left: 34,
                right: 34,
                child: _Reflection(
                  height: 3,
                  colors: [
                    Colors.transparent,
                    Color(0xFF8FFFF0),
                    Colors.white,
                    Color(0xFF57D1C7),
                    Colors.white,
                    Colors.transparent,
                  ],
                ),
              ),

              // Bright lower reflection
              const Positioned(
                bottom: 3,
                left: 30,
                right: 30,
                child: _Reflection(
                  height: 3.5,
                  colors: [
                    Colors.transparent,
                    Color(0xFF57D1C7),
                    Colors.white,
                    Color(0xFF70FFDB),
                    Colors.white,
                    Colors.transparent,
                  ],
                ),
              ),

              // Subtle top glass sheen
              Positioned(
                top: 8,
                left: 20,
                right: 20,
                height: height * 0.35,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation content
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reflection extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const _Reflection({required this.height, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF57D1C7).withValues(alpha: 0.55),
              blurRadius: 7,
            ),
          ],
        ),
      ),
    );
  }
}
