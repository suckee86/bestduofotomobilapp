import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _openedController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<String>? _tokenSubscription;
  RemoteMessage? _initialMessage;
  String? _currentToken;
  bool _initialized = false;

  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;
  Stream<RemoteMessage> get openedMessages => _openedController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      _initialMessage = await _messaging.getInitialMessage();
      FirebaseMessaging.onMessage.listen(_foregroundController.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_openedController.add);
    } catch (error) {
      debugPrint('Az értesítési csatorna indítása sikertelen: $error');
    }
  }

  RemoteMessage? takeInitialMessage() {
    final message = _initialMessage;
    _initialMessage = null;
    return message;
  }

  Future<bool> registerForUser(User user) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      if (Platform.isIOS) {
        for (var attempt = 0; attempt < 5; attempt++) {
          if (await _messaging.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      }

      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveToken(token, user.uid);
      }

      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _saveToken(newToken, user.uid);
      });
      return true;
    } catch (error) {
      debugPrint('A push token regisztrációja sikertelen: $error');
      return false;
    }
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final token = _currentToken ?? await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('pushTokens')
            .doc(_tokenId(token))
            .delete();
      }
      await _messaging.deleteToken();
    } catch (error) {
      debugPrint('A push token törlése sikertelen: $error');
    } finally {
      _currentToken = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
    }
  }

  Future<void> unregisterAllDevicesForUser(User user) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    final tokens = FirebaseFirestore.instance.collection('pushTokens');
    while (true) {
      final snapshot = await tokens
          .where('userId', isEqualTo: user.uid)
          .limit(400)
          .get();
      if (snapshot.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }

    try {
      await _messaging.deleteToken();
    } catch (error) {
      debugPrint('A helyi push token törlése sikertelen: $error');
    } finally {
      _currentToken = null;
    }
  }

  Future<void> _saveToken(String token, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pushTokens')
          .doc(_tokenId(token))
          .set({
            'token': token,
            'userId': userId,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('A push token Firestore-mentése sikertelen: $error');
    }
  }

  String _tokenId(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
