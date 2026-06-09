import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../models/payment_result.dart';

/// Web implementation: opens VNPay in a popup, receives result via postMessage
Future<PaymentResult?> launchPayment(String url) async {
  final completer = Completer<PaymentResult?>();

  // Open VNPay in a centered popup window
  final w = 500;
  final h = 700;
  final left = (html.window.screen!.width! - w) ~/ 2;
  final top = (html.window.screen!.height! - h) ~/ 2;
  final features = 'width=$w,height=$h,left=$left,top=$top,scrollbars=yes';

  final popup = html.window.open(url, 'vnpay_payment', features);

  // Listen for result from popup via postMessage
  html.window.addEventListener('message', (event) {
    try {
      final data = jsonDecode((event as html.MessageEvent).data as String)
          as Map<String, dynamic>;
      if (data['type'] == 'vnpay_result') {
        popup.close();
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.fromJson(data));
        }
      }
    } catch (_) {
      // ignore malformed messages
    }
  });

  // Check if popup was closed manually
  late final Timer timer;
  timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (popup.closed!) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(PaymentResult(
          success: false,
          message: 'Đã huỷ thanh toán',
        ));
      }
    }
  });

  return completer.future;
}
