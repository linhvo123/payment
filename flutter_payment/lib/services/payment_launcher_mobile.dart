import 'package:url_launcher/url_launcher.dart';
import '../models/payment_result.dart';

/// Mobile implementation: opens VNPay in external browser
Future<PaymentResult?> launchPayment(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!launched) {
    return PaymentResult(
      success: false,
      message: 'Không thể mở trang thanh toán',
    );
  }

  // On mobile, user completes payment in browser and manually returns
  return PaymentResult(
    success: true,
    message: 'Vui lòng hoàn tất thanh toán trên trình duyệt.\n'
        'Sau khi thanh toán, quay lại app.',
    pending: true,
  );
}
