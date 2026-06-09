import 'dart:convert';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String resultJson;

  const ResultScreen({super.key, required this.resultJson});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> result = _parseResult(resultJson);
    final bool isSuccess = result['success'] == true;
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final message = result['message'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Remove back button — user should go back to home
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status icon
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),

              // Status text
              Text(
                isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
              const SizedBox(height: 32),

              // Transaction details card
              if (data.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết giao dịch',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(),
                        _buildDetailRow(context, 'Mã giao dịch', data['txnRef']),
                        _buildDetailRow(context, 'Số tiền', _formatAmount(data['amount'], isMomo: data['payType'] != null)),
                        _buildDetailRow(context, 'Nội dung', data['orderInfo']),
                        _buildDetailRow(context, 'Mã phản hồi', data['responseCode']),
                        _buildDetailRow(context, 'Mã giao dịch', data['transactionNo']),
                        _buildDetailRow(context, 'Ngân hàng', data['bankCode']),
                        _buildDetailRow(context, 'Kênh thanh toán', data['payType']),
                        _buildDetailRow(context, 'Thời gian', data['payDate'] ?? data['responseTime']),
                        _buildDetailRow(context, 'Trạng thái', _formatTxnStatus(data['transactionStatus'])),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Back to home button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount, {bool isMomo = false}) {
    if (amount == null) return '';
    final numAmount = int.tryParse(amount.toString()) ?? 0;
    // VNPay returns amount * 100, MoMo returns raw amount
    final actual = isMomo ? numAmount : numAmount / 100;
    return '${actual.toStringAsFixed(0)} VND';
  }

  String _formatTxnStatus(dynamic status) {
    if (status == null) return '';
    switch (status.toString()) {
      case '00':
      case '0':
        return 'Thành công';
      case '01':
        return 'Giao dịch chưa hoàn tất';
      case '02':
        return 'Giao dịch bị lỗi';
      default:
        return 'Mã: $status';
    }
  }

  Map<String, dynamic> _parseResult(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Không thể đọc kết quả thanh toán'};
    }
  }
}
