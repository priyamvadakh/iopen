import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/phone_frame.dart';
import 'app/router.dart';
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

class GuideApp extends StatelessWidget {
  const GuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Remote Guide',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: appRouter,
      builder: (context, child) => PhoneFrame(child: child!),
    );
  }
}
