import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/payment_result.dart';
import '../services/api_service.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebView({super.key, required this.paymentUrl});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// Intercept navigation to detect VNPay return URL
  Future<NavigationDecision> _handleNavigation(
    NavigationRequest request,
  ) async {
    final url = request.url;

    // Detect return URL or IPN URL from backend
    if (url.contains('/api/payments/vnpay-return') ||
        url.contains('/api/payments/vnpay-ipn')) {
      if (_isReturning) return NavigationDecision.prevent;
      _isReturning = true;

      // Extract query params and call backend to verify
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      try {
        final result = await _verifyPayment(queryParams);

        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(
            PaymentResult(
              success: false,
              message: 'Lỗi xác nhận: ${e.toString()}',
            ),
          );
        }
      }

      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Call backend with VNPay return params to verify signature
  Future<PaymentResult> _verifyPayment(
    Map<String, String> queryParams,
  ) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/payments/vnpay-return',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PaymentResult.fromJson(json);
    } else {
      return PaymentResult(
        success: false,
        message: 'Lỗi kết nối server',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VNPay Thanh Toán'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(
              PaymentResult(
                success: false,
                message: 'Đã huỷ thanh toán',
              ),
            );
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
