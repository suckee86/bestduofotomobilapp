import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/public_links.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  late final AnimationController _entranceController;
  bool _motionPreferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPreferenceApplied) return;
    _motionPreferenceApplied = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

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
                colors: [Color(0x44000000), Color(0xF2090807)],
                stops: [0, 0.88],
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
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          _AuthEntrance(
                            animation: _entranceController,
                            begin: 0,
                            end: 0.38,
                            distance: -14,
                            initialScale: 0.9,
                            child: const Align(
                              alignment: Alignment.topCenter,
                              child: BrandLogo(width: 148, padding: 7),
                            ),
                          ),
                          const Spacer(flex: 3),
                          _AuthEntrance(
                            animation: _entranceController,
                            begin: 0.16,
                            end: 0.68,
                            distance: 30,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.orange,
                                  size: 24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Üdvözlünk!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 46,
                                        letterSpacing: -2.2,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: 46,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 4),
                          _AuthEntrance(
                            animation: _entranceController,
                            begin: 0.48,
                            end: 1,
                            distance: 34,
                            initialScale: 0.92,
                            curve: Curves.easeOutBack,
                            child: _LoginActions(
                              loading: _loading,
                              error: _error,
                              onGoogle: () => _authenticate(
                                () async =>
                                    AuthService.instance.signInWithGoogle(),
                              ),
                              onApple: Platform.isIOS
                                  ? () => _authenticate(
                                      () async => AuthService.instance
                                          .signInWithApple(),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
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

class _AuthEntrance extends StatelessWidget {
  const _AuthEntrance({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.distance = 24,
    this.initialScale = 1,
    this.curve = Curves.easeOutCubic,
  });

  final Animation<double> animation;
  final double begin;
  final double end;
  final double distance;
  final double initialScale;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = ((animation.value - begin) / (end - begin)).clamp(
          0.0,
          1.0,
        );
        final curvedProgress = curve.transform(progress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, distance * (1 - curvedProgress)),
            child: Transform.scale(
              scale: initialScale + ((1 - initialScale) * curvedProgress),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _LoginActions extends StatelessWidget {
  const _LoginActions({
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
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEB).withValues(alpha: 0.96),
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
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onGoogle,
              icon: const _GoogleMark(),
              label: const Text('Belépés Google-fiókkal'),
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFF1F1F1F),
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(58),
                elevation: 0,
                side: const BorderSide(color: Color(0xFF747775)),
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
                label: const Text('Belépés Apple-fiókkal'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(58),
                  side: const BorderSide(color: Colors.white38),
                ),
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
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: loading
                ? null
                : () => launchUrl(
                    privacyPolicyUri,
                    mode: LaunchMode.externalApplication,
                  ),
            icon: const Icon(Icons.privacy_tip_outlined, size: 17),
            label: const Text('Adatkezelési tájékoztató'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              textStyle: const TextStyle(fontSize: 12),
            ),
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
    return Image.asset(
      'assets/images/google_g_logo.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      semanticLabel: 'Google',
    );
  }
}
