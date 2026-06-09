import 'dart:convert';
import 'dart:html' as html;
import '../models/payment_result.dart';

/// Web: check URL for vnpay_result on startup.
/// If in popup → postMessage to opener & close.
/// If in main window → callback with result.
void handleStartupResult(void Function(PaymentResult?) onResult) {
  final uri = Uri.parse(html.window.location.href);
  final encoded = uri.queryParameters['vnpay_result'];

  if (encoded == null) {
    onResult(null);
    return;
  }

  try {
    final json = jsonDecode(Uri.decodeComponent(encoded))
        as Map<String, dynamic>;
    final result = PaymentResult.fromJson(json);

    if (html.window.opener != null) {
      // We're in a popup → send result to main window & close
      html.window.opener!.postMessage(
        jsonEncode({'type': 'vnpay_result', ...json}),
        '*',
      );
      html.window.close();
      return;
    }

    // Main window → show result
    onResult(result);
  } catch (_) {
    onResult(null);
  }
}
