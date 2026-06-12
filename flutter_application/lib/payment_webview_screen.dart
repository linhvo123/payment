import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String callbackUrlPrefix;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.callbackUrlPrefix,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _didPop = false;

  @override
  void dispose() {
    // Clear the WebView to free memory when leaving this screen
    _controller.clearCache();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Only intercept if the URL already contains a payment result.
            // Otherwise let the backend process the redirect first.
            final uri = Uri.parse(url);
            if (uri.queryParameters.containsKey('vnpay_result')) {
              _handleCallbackUrl(url);
              return;
            }
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleCallbackUrl(String url) {
    if (_didPop) return;
    _didPop = true;

    final uri = Uri.parse(url);

    // Check for VNPay result
    final vnpayResult = uri.queryParameters['vnpay_result'];
    if (vnpayResult != null && vnpayResult.isNotEmpty) {
      try {
        final decoded = Uri.decodeComponent(vnpayResult);
        jsonDecode(decoded); // validate JSON
        Navigator.pop(context, decoded);
      } catch (_) {
        Navigator.pop(
          context,
          jsonEncode({
            'success': false,
            'message': 'Invalid payment result data',
          }),
        );
      }
      return;
    }

    // No recognizable payment result
    Navigator.pop(
      context,
      jsonEncode({
        'success': false,
        'message': 'No payment result received',
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ thanh toán?'),
        content: const Text('Bạn có chắc muốn huỷ giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp tục thanh toán'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // pop webview screen
            },
            child: const Text('Huỷ'),
          ),
        ],
      ),
    );
  }
}
