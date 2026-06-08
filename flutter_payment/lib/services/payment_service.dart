import '../models/payment_result.dart';
import 'gateways/payment_gateway.dart';

class PaymentService {
  Future<PaymentResult> processPayment({
    required PaymentGateway gateway,
    required double amount,
  }) async {
    return gateway.pay(amount);
  }
}