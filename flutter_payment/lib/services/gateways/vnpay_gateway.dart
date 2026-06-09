import '../../models/payment_result.dart';
import '../api_service.dart';
import 'payment_gateway.dart';

class VNPayGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay(double amount) async {
    try {
      // Call Node.js backend to create VNPay payment URL
      final response = await ApiService.createPayment(amount: amount);

      if (response['success'] == true) {
        final paymentUrl = response['paymentUrl'] as String;

        // Return payment URL — caller will open WebView
        return PaymentResult(
          success: true,
          message: paymentUrl, // Hack: store URL in message for WebView
          pending: true,
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Failed to create payment',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}