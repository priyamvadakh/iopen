import 'package:flutter/widgets.dart';

/// True while the opening sequence plays; Home holds its globe and section
/// animations until it ends so the landing lines up.
final onboardingActive = ValueNotifier<bool>(false);

/// Bump to play the opening sequence again (Profile → Replay intro).
final replayOnboarding = ValueNotifier<int>(0);

/// Where Home's globe sits on screen, so the opening globe lands on it.
final homeGlobeRect = ValueNotifier<Rect?>(null);
