import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackWebViewScreen extends StatefulWidget {
  const PaystackWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.onPaymentComplete,
  });

  final String authorizationUrl;
  final Future<void> Function(String reference) onPaymentComplete;

  @override
  State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            _maybeCompleteFromUrl(request.url);
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) => _maybeCompleteFromUrl(url),
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _maybeCompleteFromUrl(String url) {
    if (_verifying) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final reference = uri.queryParameters['trxref'] ?? uri.queryParameters['reference'];
    if (reference != null && reference.isNotEmpty) {
      _complete(reference);
    }
  }

  Future<void> _complete(String reference) async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      await widget.onPaymentComplete(reference);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure payment'),
        actions: [
          if (_verifying)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Complete your payment securely with Paystack.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}