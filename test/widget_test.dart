import 'package:bestduo/app.dart';
import 'package:bestduo/config/admin_access.dart';
import 'package:bestduo/services/auth_service.dart';
import 'package:bestduo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
