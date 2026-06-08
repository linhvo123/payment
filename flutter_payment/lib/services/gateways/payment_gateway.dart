import '../../models/payment_result.dart';

abstract class PaymentGateway {
  Future<PaymentResult> pay(double amount);
}