import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final analyticsProvider = Provider((ref) => FirebaseAnalytics.instance);

/// Asks for notification permission and registers with Firebase Cloud
/// Messaging. Send the installation ID to your backend to target pushes
/// (e.g. order updates).
Future<void> initPushNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    messaging.onRegistered.listen(
      (id) => debugPrint('FCM installation ID: $id'),
    );
    await messaging.register();
  } catch (e) {
    // iOS needs APNs set up in the Apple Developer portal before this works.
    debugPrint('Push notifications unavailable: $e');
  }
}
