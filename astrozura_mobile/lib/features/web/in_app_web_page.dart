import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/contants/api_constants.dart';

class InAppWebPage extends StatefulWidget {
  final String title;
  final String pathOrUrl;

  const InAppWebPage({
    super.key,
    required this.title,
    required this.pathOrUrl,
  });

  static Uri buildUri(String pathOrUrl) {
    final raw = pathOrUrl.trim();
    final base = Uri.parse(ApiConstants.webBaseUrl);
    final uri = raw.startsWith('http://') || raw.startsWith('https://')
        ? Uri.parse(raw)
        : base.resolve(raw.startsWith('/') ? raw : '/$raw');
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'app_view': '1',
      },
    );
  }

  static Future<void> open(
    BuildContext context, {
    required String title,
    required String pathOrUrl,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppWebPage(
          title: title,
          pathOrUrl: pathOrUrl,
        ),
      ),
    );
  }

  @override
  State<InAppWebPage> createState() => _InAppWebPageState();
}

class _InAppWebPageState extends State<InAppWebPage> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _pageBg = Color(0xFFFBF7EF);

  late final Uri _uri;
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _uri = InAppWebPage.buildUri(widget.pathOrUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_pageBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _progress = 0;
              _hasError = false;
            });
          },
          onPageFinished: (_) async {
            await _hideWebsiteChrome();
            if (!mounted) return;
            setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _hasError = true);
          },
          onNavigationRequest: (request) {
            final next = Uri.tryParse(request.url);
            if (next == null) return NavigationDecision.navigate;
            if (next.host.endsWith('astrozura.com')) {
              return NavigationDecision.navigate;
            }
            launchUrl(next, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_uri);
  }

  Future<void> _hideWebsiteChrome() async {
    const script = r'''
      (function () {
        var css = `
          header, nav, footer,
          [role="navigation"],
          .navbar, .site-header, .main-header, .top-header, .secondary-nav,
          .mobile-header, .footer, .site-footer, .main-footer,
          .newsletter, .app-download, .download-app, .store-badges {
            display: none !important;
          }
          body {
            padding-top: 0 !important;
            margin-top: 0 !important;
            overflow-x: hidden !important;
            background: #fbf7ef !important;
          }
          main, #root, .app, .page, .content {
            padding-top: 0 !important;
            margin-top: 0 !important;
          }
        `;
        var style = document.getElementById('astrozura-app-webview-style');
        if (!style) {
          style = document.createElement('style');
          style.id = 'astrozura-app-webview-style';
          document.head.appendChild(style);
        }
        style.textContent = css;
        document.documentElement.classList.add('astrozura-app-webview');
      })();
    ''';
    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // Some pages may block injection; normal WebView rendering should continue.
    }
  }

  Future<void> _openExternal() async {
    await launchUrl(_uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0.5,
        titleSpacing: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progress < 100
              ? LinearProgressIndicator(
                  value: _progress <= 0 ? null : _progress / 100,
                  minHeight: 3,
                  color: _gold,
                  backgroundColor: const Color(0xFFF1E5C4),
                )
              : const SizedBox(height: 3),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _hasError
            ? _WebErrorState(onRetry: () => _controller.loadRequest(_uri))
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}

class _WebErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _WebErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: Color(0xFFD7AF4B),
            ),
            const SizedBox(height: 14),
            const Text(
              'This page could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3557),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
