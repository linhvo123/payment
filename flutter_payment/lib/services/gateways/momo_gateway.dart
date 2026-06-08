import '../../models/payment_result.dart';
import 'payment_gateway.dart';

class MomoGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay(double amount) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    return PaymentResult(
      success: true,
      message: 'MoMo payment successful',
    );
  }
}