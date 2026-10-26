import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/phone_frame.dart';
import 'app/router.dart';
import 'screens/onboarding.dart';
import 'app/theme.dart';
import 'core/firebase_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    initPushNotifications();
  } on UnsupportedError catch (e) {
    // Until `flutterfire configure` is run, the UI works without a backend.
    debugPrint('Running without Firebase: ${e.message}');
  }
  runApp(const ProviderScope(child: GuideApp()));
}

class GuideApp extends StatefulWidget {
  const GuideApp({super.key});

  @override
  State<GuideApp> createState() => _GuideAppState();
}

class _GuideAppState extends State<GuideApp> {
  // Plays on a plain launch; deep links (e.g. a shared city) go straight in.
  bool _onboarding = const {
    '/',
    '/home',
  }.contains(WidgetsBinding.instance.platformDispatcher.defaultRouteName);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iOpen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: appRouter,
      builder: (context, child) => PhoneFrame(
        child: Stack(
          children: [
            child!,
            if (_onboarding)
              Positioned.fill(
                child: OnboardingOverlay(
                  onDone: () => setState(() => _onboarding = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
