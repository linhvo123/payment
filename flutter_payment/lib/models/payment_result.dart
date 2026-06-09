class PaymentResult {
  final bool success;
  final String message;
  final bool pending;
  final Map<String, dynamic>? data;

  PaymentResult({
    required this.success,
    required this.message,
    this.pending = false,
    this.data,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] == true,
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Format amount from VNPay (amount * 100) to display string
  String get formattedAmount {
    if (data == null || data!['amount'] == null) return '';
    final raw = int.tryParse(data!['amount'].toString()) ?? 0;
    final vnd = raw ~/ 100;
    return '$vnd ₫';
  }
}