import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// API Service for communicating with the Node.js payment backend
class ApiService {
  /// Backend URL loaded from .env file
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://payment-1-3sh3.onrender.com';

  /// Create a VNPay payment URL
  /// [appReturnUrl] — Flutter app's origin (e.g. http://localhost:55000)
  ///   so backend can redirect back with result after payment
  static Future<Map<String, dynamic>> createPayment({
    required double amount,
    String? appReturnUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/api/payments/create');

    final body = <String, dynamic>{'amount': amount};
    if (appReturnUrl != null && appReturnUrl.isNotEmpty) {
      body['appReturnUrl'] = appReturnUrl;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to create payment: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Check payment status by transaction reference
  static Future<Map<String, dynamic>> checkPaymentStatus(
    String txnRef,
  ) async {
    final uri = Uri.parse('$baseUrl/api/payments/status/$txnRef');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to check status: ${response.statusCode}',
      );
    }
  }
}
