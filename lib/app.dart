import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_logo.dart';

class BestDuoApp extends StatelessWidget {
  const BestDuoApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best Duo Fotó',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: startupError == null
          ? const AuthGate()
          : const StartupErrorScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandLoadingScreen();
        }

        final user = snapshot.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: user == null
              ? const AuthScreen(key: ValueKey('signed-out'))
              : MainShell(key: ValueKey(user.uid), user: user),
        );
      },
    );
  }
}

class BrandLoadingScreen extends StatelessWidget {
  const BrandLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(width: 132),
            SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(width: 142),
              const SizedBox(height: 32),
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.orange,
                size: 48,
              ),
              const SizedBox(height: 18),
              Text(
                'Nem sikerült kapcsolódni',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ellenőrizd az internetkapcsolatot, majd indítsd újra az alkalmazást.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
