import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/sepay_config.dart';
import '../models/product.dart';
import '../services/sepay_service.dart';
import 'sepay_success_screen.dart';

class SepayPaymentScreen extends StatefulWidget {
  final String orderCode;
  final String transferContent;
  final int amount;
  final List<Product> cartItems;

  const SepayPaymentScreen({
    super.key,
    required this.orderCode,
    required this.transferContent,
    required this.amount,
    required this.cartItems,
  });

  @override
  State<SepayPaymentScreen> createState() => _SepayPaymentScreenState();
}

class _SepayPaymentScreenState extends State<SepayPaymentScreen> with TickerProviderStateMixin {
  PaymentStatus _status = PaymentStatus.waiting;
  StreamSubscription<PaymentStatus>? _pollingSub;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  int _remainingSeconds = SepayConfig.paymentTimeoutSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: SepayConfig.paymentTimeoutSeconds),
    )..forward();

    _startPolling();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds = (_remainingSeconds - 1).clamp(0, 999);
        });
        if (_remainingSeconds == 0) timer.cancel();
      }
    });
  }

  void _startPolling() {
    _pollingSub = SepayService.pollPaymentStatus(
      orderCode: widget.orderCode,
      expectedAmount: widget.amount,
      interval: Duration(seconds: SepayConfig.pollingIntervalSeconds),
      timeout: Duration(seconds: SepayConfig.paymentTimeoutSeconds),
    ).listen((status) {
      if (!mounted) return;
      setState(() => _status = status);

      if (status == PaymentStatus.success) {
        _stopPolling();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SepaySuccessScreen(
                  orderCode: widget.orderCode,
                  amount: widget.amount,
                  cartItems: widget.cartItems,
                ),
              ),
            );
          }
        });
      } else if (status == PaymentStatus.timeout) {
        _stopPolling();
      }
    });
  }

  void _stopPolling() {
    _pollingSub?.cancel();
    _countdownTimer?.cancel();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _stopPolling();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildQrSection() {
    final qrUrl = SepayConfig.qrImageUrl(
      amount: widget.amount.toString(),
      content: widget.transferContent,
    );

    return Column(
      children: [
        // QR Code image từ SePay
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withOpacity(0.1 + _pulseController.value * 0.15),
                    blurRadius: 20 + _pulseController.value * 20,
                    spreadRadius: _pulseController.value * 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  qrUrl,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 240,
                      height: 240,
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: hiển thị text QR info nếu không load được
                    return Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_2, size: 60, color: Color(0xFF0066FF)),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code\n${SepayConfig.bankCode} - ${SepayConfig.bankAccount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),
        const Text(
          'Mở app ngân hàng → Quét mã QR',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () => _copyToClipboard(value, label),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.copy, size: 16, color: Color(0xFF0066FF)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    if (_status == PaymentStatus.timeout) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hết thời gian thanh toán. Vui lòng tạo đơn hàng mới.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBDD0FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF0066FF),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đang chờ xác nhận thanh toán...',
                  style: TextStyle(color: Color(0xFF0044BB), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) => LinearProgressIndicator(
              value: 1 - _progressController.value,
              backgroundColor: const Color(0xFFBDD0FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          children: [
            const Text('Thanh toán QR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            Text(
              'Đơn #${widget.orderCode}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _formatCurrency(widget.amount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số tiền cần chuyển',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _buildQrSection(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin chuyển khoản
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin chuyển khoản',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Ngân hàng', SepayConfig.bankCode),
                  _buildInfoRow('Số tài khoản', SepayConfig.bankAccount, copyable: true),
                  _buildInfoRow('Chủ tài khoản', SepayConfig.accountName),
                  _buildInfoRow(
                    'Số tiền',
                    _formatCurrency(widget.amount),
                    copyable: true,
                  ),
                  _buildInfoRow(
                    'Nội dung CK (bắt buộc)',
                    widget.transferContent,
                    copyable: true,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Nhập đúng nội dung để hệ thống tự động xác nhận',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status
            _buildStatusBar(),

            const SizedBox(height: 16),

            if (_status == PaymentStatus.timeout)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại đặt hàng lại'),
              ),
          ],
        ),
      ),
    );
  }
}
