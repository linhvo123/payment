/// ==========================================
///  CẤU HÌNH SEPAY - thay bằng thông tin thật
/// ==========================================
class SepayConfig {
  /// API Token lấy từ dashboard.sepay.vn → API → Token
  static const String apiToken =
      'TTPJCGEYSI41ZRHZSM09EDYTUCB7HUZIXADQVO7RXVNJUHWLBKIKIOXQU2A68FQV';

  /// Số tài khoản ngân hàng của bạn
  static const String bankAccount = '0905210763';

  /// Mã ngân hàng theo chuẩn SePay (vd: MB, VCB, TCB, ACB, BIDV...)
  static const String bankCode = 'MB';

  /// Tên chủ tài khoản (hiển thị cho khách)
  static const String accountName = 'VU VAN DUC';

  /// URL webhook backend của bạn (SePay sẽ POST vào đây)
  static const String webhookUrl = 'https://your-backend.com/api/sepay-webhook';

  /// Timeout chờ thanh toán (giây)
  static const int paymentTimeoutSeconds = 300; // 5 phút

  /// Polling interval kiểm tra giao dịch (giây)
  static const int pollingIntervalSeconds = 5;

  // ---- SePay API endpoints ----
  static const String baseApiUrl = 'https://my.sepay.vn/userapi';
  static String get transactionsUrl => '$baseApiUrl/transactions/list';

  // ---- QR Image URL (không cần API key) ----
  static String qrImageUrl({
    required String amount,
    required String content,
    String template = 'compact2',
  }) {
    return 'https://qr.sepay.vn/img'
        '?acc=$bankAccount'
        '&bank=$bankCode'
        '&amount=$amount'
        '&des=${Uri.encodeComponent(content)}'
        '&template=$template';
  }
}
