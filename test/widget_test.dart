import 'dart:async';

import 'package:bestduo/app.dart';
import 'package:bestduo/config/admin_access.dart';
import 'package:bestduo/screens/auth_screen.dart';
import 'package:bestduo/screens/home_screen.dart';
import 'package:bestduo/services/auth_service.dart';
import 'package:bestduo/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestUser extends Fake implements User {
  @override
  String get uid => 'test-user';

  @override
  String? get displayName => 'István Teszt';

  @override
  String? get photoURL => null;
}

void main() {
  test('csak az ellenőrzött tartalomkezelői cím kap adminjogot', () {
    expect(
      isContentAdminIdentity(
        email: ' BESTDUO.FIREBASE@GMAIL.COM ',
        emailVerified: true,
      ),
      isTrue,
    );
    expect(
      isContentAdminIdentity(email: contentAdminEmail, emailVerified: false),
      isFalse,
    );
    expect(
      isContentAdminIdentity(email: 'masik@gmail.com', emailVerified: true),
      isFalse,
    );
  });

  test('a konfigurációs belépési hiba magyar üzenetet ad', () {
    const error = AuthConfigurationException('Hiányzó OAuth-beállítás.');
    expect(friendlyAuthError(error), 'Hiányzó OAuth-beállítás.');
  });

  test('a Firebase-kijelentkezés nem vár a Google takarítására', () async {
    final events = <String>[];
    final googleCleanup = Completer<void>();

    await signOutSessions(
      firebaseSignOut: () async => events.add('firebase'),
      googleSignOut: () async {
        events.add('google');
        await googleCleanup.future;
      },
    );

    expect(events, ['firebase', 'google']);
    googleCleanup.complete();
  });

  testWidgets('az indulási hiba márkázott, érthető állapotot mutat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const StartupErrorScreen()),
    );

    expect(find.text('Nem sikerült kapcsolódni'), findsOneWidget);
    expect(find.textContaining('internetkapcsolatot'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a belépési kezdőképernyő csak a lényegi elemeket mutatja', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Üdvözlünk!'), findsOneWidget);
    expect(find.text('Belépés Google-fiókkal'), findsOneWidget);
    expect(find.text('Adatkezelési tájékoztató'), findsOneWidget);
    expect(find.text('Biztonságos belépés'), findsNothing);
    expect(find.text('PRÉMIUM FOTÓKIDOLGOZÁS'), findsNothing);
    expect(find.textContaining('Az emlékek kézben'), findsNothing);
    expect(find.textContaining('Fotókidolgozás egyszerűen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a főoldal személyes, animált köszöntéssel indul', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeScreen(
            user: _TestUser(),
            onOpenPhotos: () {},
            onOpenNews: () {},
            onOpenContact: () {},
            onOpenProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Szia, István!'), findsOneWidget);
    expect(find.text('JÓ, HOGY ITT VAGY'), findsOneWidget);
    expect(find.text('Fotót választok'), findsOneWidget);
    expect(find.textContaining('megérdemlik a papírt'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
