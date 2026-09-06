import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await AuthService.instance.initialize();
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    startupError = error;
    debugPrint('Best Duo indulási hiba: $error\n$stackTrace');
  }

  runApp(BestDuoApp(startupError: startupError));
}
