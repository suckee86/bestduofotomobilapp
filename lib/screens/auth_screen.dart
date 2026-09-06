import 'dart:io';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _authenticate(Future<void> Function() action) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/photo_lab_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x55000000), Color(0xEE090807)],
                stops: [0.05, 0.82],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 42,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BrandLogo(width: 112, padding: 6),
                            _SecureBadge(),
                          ],
                        ),
                        const SizedBox(height: 72),
                        const Text(
                          'PRÉMIUM FOTÓKIDOLGOZÁS',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Az emlékek kézben\nválnak igazivá.',
                          style: textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 43,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Fotókidolgozás egyszerűen, gyorsan és gondosan — közvetlenül a telefonodról.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 42),
                        _LoginCard(
                          loading: _loading,
                          error: _error,
                          onGoogle: () => _authenticate(
                            () async => AuthService.instance.signInWithGoogle(),
                          ),
                          onApple: Platform.isIOS
                              ? () => _authenticate(
                                  () async =>
                                      AuthService.instance.signInWithApple(),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.success),
          SizedBox(width: 7),
          Text(
            'Biztonságos belépés',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.loading,
    required this.error,
    required this.onGoogle,
    required this.onApple,
  });

  final bool loading;
  final String? error;
  final VoidCallback onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white70),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Üdvözlünk!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          const Text(
            'Jelentkezz be, és máris indulhat a rendelés.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error!,
                style: const TextStyle(
                  color: Color(0xFF9B2D1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onGoogle,
              icon: const _GoogleMark(),
              label: const Text('Folytatás Google-fiókkal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (onApple != null) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : onApple,
                icon: const Icon(Icons.apple_rounded, size: 24),
                label: const Text('Folytatás Apple-fiókkal'),
                style: FilledButton.styleFrom(backgroundColor: Colors.black),
              ),
            ),
          ],
          if (loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              minHeight: 3,
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ],
          const SizedBox(height: 15),
          const Text(
            'A belépési adatokat a Google, az Apple és a Firebase kezeli; jelszót nem tárolunk.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}
