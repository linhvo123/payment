import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your actual backend URL
  static const String baseUrl = 'https://payment-1-3sh3.onrender.com';

  /// Creates a VNPay payment URL by calling the backend.
  ///
  /// [amount] is the payment amount in VND.
  /// [appReturnUrl] is the URL that VNPay will redirect to after payment.
  ///
  /// Returns the VNPay sandbox payment URL.
  static Future<String> createPaymentUrl({
    required int amount,
    required String appReturnUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/api/payments/create');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'appReturnUrl': appReturnUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['paymentUrl'] != null) {
          return data['paymentUrl'] as String;
        } else {
          throw ApiException(
            data['message'] as String? ?? 'Failed to create payment URL',
          );
        }
      } else {
        final body = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw ApiException('Server error (${response.statusCode}): $body');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
