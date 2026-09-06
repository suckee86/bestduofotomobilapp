import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/admin_access.dart';
import '../config/public_links.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'photo_webview_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});

  final User user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(AuthService.instance.ensureProfile(widget.user));
    unawaited(NotificationService.instance.registerForUser(widget.user));

    _foregroundSubscription = NotificationService.instance.foregroundMessages
        .listen(_showForegroundMessage);
    _openedSubscription = NotificationService.instance.openedMessages.listen(
      (_) => _openNews(),
    );

    if (NotificationService.instance.takeInitialMessage() != null) {
      _index = 2;
    }
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    super.dispose();
  }

  void _openNews() {
    if (mounted) setState(() => _index = 2);
  }

  void _showForegroundMessage(RemoteMessage message) {
    if (!mounted) return;
    final notification = message.notification;
    final title = notification?.title ?? 'Új Best Duo értesítés';
    final body = notification?.body;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (body != null) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'Megnézem',
            textColor: AppColors.orangeLight,
            onPressed: _openNews,
          ),
        ),
      );
  }

  void _showProfile() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = isContentAdmin(widget.user);
    final pages = [
      HomeScreen(
        user: widget.user,
        onOpenPhotos: () => setState(() => _index = 1),
        onOpenNews: () => setState(() => _index = 2),
        onOpenContact: () => setState(() => _index = 3),
        onOpenProfile: _showProfile,
      ),
      PhotoWebViewScreen(email: widget.user.email),
      const NewsScreen(),
      const ContactScreen(),
      if (isAdmin) AdminScreen(user: widget.user),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Kezdőlap',
            ),
            const NavigationDestination(
              icon: Icon(Icons.add_photo_alternate_outlined),
              selectedIcon: Icon(Icons.add_photo_alternate_rounded),
              label: 'Fotók',
            ),
            const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Hírek',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Kapcsolat',
            ),
            if (isAdmin)
              const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Kezelés',
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.user});

  final User user;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    final notificationCleanup = NotificationService.instance
        .unregisterCurrentDevice();

    try {
      await AuthService.instance.signOut();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A kijelentkezés most nem sikerült. Próbáld újra.'),
        ),
      );
    }

    unawaited(_finishNotificationCleanup(notificationCleanup));
  }

  Future<void> _finishNotificationCleanup(Future<void> cleanup) async {
    try {
      await cleanup.timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('A push token háttérbeli törlése sikertelen: $error');
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fiók törlése'),
        content: const Text(
          'Biztosan törlöd a Best Duo-fiókodat és a hozzá tartozó alkalmazásadatokat? Ez nem vonható vissza.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Mégsem'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Fiók törlése'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await NotificationService.instance.unregisterAllDevicesForUser(
        widget.user,
      );
      await AuthService.instance.deleteAccount();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyAuthError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.orange,
            foregroundImage: widget.user.photoURL == null
                ? null
                : NetworkImage(widget.user.photoURL!),
            child: Text(
              (widget.user.displayName?.trim().isNotEmpty ?? false)
                  ? widget.user.displayName!.trim()[0].toUpperCase()
                  : 'B',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            widget.user.displayName ?? 'Best Duo vásárló',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.user.email != null) ...[
            const SizedBox(height: 3),
            Text(
              widget.user.email!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _signOut,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(_busy ? 'Kijelentkezés…' : 'Kijelentkezés'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Fiók végleges törlése'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          ),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => unawaited(
                    launchUrl(
                      privacyPolicyUri,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Adatkezelési tájékoztató'),
          ),
          if (_busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 8),
          const Text(
            'Best Duo Fotó • 1.0.0',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
