import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_initialized) await initialize();

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthConfigurationException(
        'A Google nem adott vissza azonosító tokent.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    await _saveProfile(result.user);
    return result;
  }

  Future<UserCredential> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = await _auth.signInWithProvider(provider);
    await _saveProfile(result.user);
    return result;
  }

  Future<void> ensureProfile(User user) => _saveProfile(user);

  Future<void> signOut() => signOutSessions(
    firebaseSignOut: _auth.signOut,
    googleSignOut: _initialized ? _googleSignIn.signOut : null,
  );

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String? appleAuthorizationCode;
    final providers = user.providerData.map((item) => item.providerId).toSet();
    if (providers.contains(AppleAuthProvider.PROVIDER_ID)) {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final credential = await user.reauthenticateWithProvider(provider);
      appleAuthorizationCode = credential.additionalUserInfo?.authorizationCode;
    } else if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      if (!_initialized) await initialize();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthConfigurationException(
          'A Google nem adott vissza azonosító tokent.',
        );
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
    } catch (error) {
      debugPrint('A felhasználói profil előzetes törlése sikertelen: $error');
    }

    if (appleAuthorizationCode != null) {
      await _auth.revokeTokenWithAuthorizationCode(appleAuthorizationCode);
    }

    await user.delete();
    if (_initialized) await _googleSignIn.signOut();
  }

  Future<void> _saveProfile(User? user) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'providerIds': user.providerData
            .map((item) => item.providerId)
            .toList(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      // A belépés maradjon használható akkor is, ha a Firestore még nincs
      // létrehozva vagy a szabályok telepítése folyamatban van.
      debugPrint('A Firebase profil mentése sikertelen: $error');
    }
  }
}

@visibleForTesting
Future<void> signOutSessions({
  required Future<void> Function() firebaseSignOut,
  Future<void> Function()? googleSignOut,
}) async {
  // A felületet a Firebase authStateChanges streamje vezérli, ezért ezt a
  // munkamenetet zárjuk le először. A Google helyi munkamenetének esetleges
  // hibája nem tarthatja bejelentkezve a felhasználót az alkalmazásban.
  await firebaseSignOut();

  if (googleSignOut == null) return;
  unawaited(_finishGoogleSignOut(googleSignOut));
}

Future<void> _finishGoogleSignOut(Future<void> Function() googleSignOut) async {
  try {
    await googleSignOut().timeout(const Duration(seconds: 3));
  } catch (error) {
    debugPrint('A Google-munkamenet lezárása sikertelen: $error');
  }
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyAuthError(Object error) {
  if (error is AuthConfigurationException) return error.message;

  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return 'A belépés megszakadt.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'A Google-belépés beállítása még nem teljes (SHA-1/OAuth).';
      default:
        return 'A Google-belépés most nem sikerült. Próbáld újra.';
    }
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'canceled':
      case 'popup_closed_by_user':
      case 'web-context-cancelled':
        return 'A bejelentkezés megszakadt.';
      case 'account-exists-with-different-credential':
        return 'Ehhez az e-mail-címhez már másik belépési mód tartozik.';
      case 'network-request-failed':
        return 'Nincs megfelelő internetkapcsolat.';
      case 'operation-not-allowed':
        return 'Ez a belépési mód még nincs engedélyezve a Firebase-ben.';
      case 'requires-recent-login':
        return 'A művelethez jelentkezz be újra.';
      case 'user-disabled':
        return 'Ez a fiók le van tiltva.';
      default:
        return 'A belépés most nem sikerült. Próbáld újra.';
    }
  }

  final errorText = error.toString().toLowerCase();
  if (errorText.contains('canceled') || errorText.contains('cancelled')) {
    return 'A bejelentkezés megszakadt.';
  }

  return 'Váratlan hiba történt. Próbáld újra később.';
}
