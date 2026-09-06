import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

class PhotoWebViewScreen extends StatefulWidget {
  const PhotoWebViewScreen({super.key, this.email});

  final String? email;

  @override
  State<PhotoWebViewScreen> createState() => _PhotoWebViewScreenState();
}

class _PhotoWebViewScreenState extends State<PhotoWebViewScreen> {
  static final _startUri = Uri.parse('https://bestduo.hu/onlinefoto/');

  late final WebViewController _controller;
  int _progress = 0;
  String? _mainFrameError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.paper)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _mainFrameError = null);
          },
          onPageFinished: (_) => _prefillEmail(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _mainFrameError = error.description);
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(_startUri);
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final isBestDuo =
        uri.scheme == 'https' &&
        (uri.host == 'bestduo.hu' || uri.host.endsWith('.bestduo.hu'));
    if (isBestDuo) return NavigationDecision.navigate;

    if (uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'mailto' ||
        uri.scheme == 'tel') {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
    return NavigationDecision.prevent;
  }

  Future<void> _prefillEmail() async {
    final email = widget.email?.trim();
    if (email == null || email.isEmpty) return;

    final encodedEmail = jsonEncode(email);
    await _controller.runJavaScript('''
      (() => {
        const input = document.querySelector('input[type="email"]');
        if (input && !input.value) {
          input.value = $encodedEmail;
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E3),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fénykép kidolgozás',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Biztonságos képfeltöltés',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Vissza',
                    onPressed: () async {
                      if (await _controller.canGoBack()) {
                        await _controller.goBack();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Előre',
                    onPressed: () async {
                      if (await _controller.canGoForward()) {
                        await _controller.goForward();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Frissítés',
                    onPressed: _controller.reload,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 3,
                color: AppColors.orange,
                backgroundColor: Colors.white12,
              ),
            Expanded(
              child: _mainFrameError == null
                  ? WebViewWidget(controller: _controller)
                  : _WebError(
                      onRetry: () => _controller.loadRequest(_startUri),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebError extends StatelessWidget {
  const _WebError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'A fotórendelő nem tölthető be',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ellenőrizd az internetkapcsolatot, majd próbáld újra.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Újrapróbálom'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
