import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String message;
  final bool pending;
  final Map<String, dynamic>? data;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.message,
    this.pending = false,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = success ? Colors.green : Colors.red;
    final icon = success ? Icons.check_circle : Icons.error;
    final title = success ? 'Thanh toán thành công!' : 'Thanh toán thất bại';

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: color),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              if (data != null && data!['amount'] != null) ...[
                const SizedBox(height: 8),

                // Amount
                Text(
                  _formatAmount(data!['amount'].toString()),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              Text(
                data?['orderInfo'] ?? message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

              if (data != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                _detailRow('Mã giao dịch', data!['txnRef']),
                _detailRow('Mã VNPay', data!['transactionNo']),
                _detailRow('Ngân hàng', data!['bankCode']),
                _detailRow('Thời gian', data!['payDate']),
                _detailRow(
                  'Trạng thái',
                  success ? 'Thành công' : 'Thất bại',
                  valueColor: color,
                ),
              ],

              const SizedBox(height: 32),

              // Back to home button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value, {Color? valueColor}) {
    final displayValue = value?.toString() ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(String raw) {
    final n = int.tryParse(raw) ?? 0;
    final vnd = n ~/ 100;
    // Simple formatting
    final str = vnd.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '$buffer ₫';
  }
}