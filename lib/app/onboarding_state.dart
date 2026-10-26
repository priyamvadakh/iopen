import 'package:flutter/foundation.dart';

/// True while the opening sequence plays; Home holds its globe and section
/// animations until it ends so the landing lines up.
final onboardingActive = ValueNotifier<bool>(false);
