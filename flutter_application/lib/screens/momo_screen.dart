import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../payment_webview_screen.dart';
import '../result_screen.dart';

class MoMoPaymentScreen extends StatefulWidget {
  final int? prefillAmount;

  const MoMoPaymentScreen({super.key, this.prefillAmount});

  @override
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillAmount != null) {
      _amountController.text = widget.prefillAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final amount = int.parse(_amountController.text.trim());

      // This URL is the backend endpoint that MoMo redirects to after payment
      // The backend then redirects back to the Flutter app
      const appReturnUrl =
          'https://payment-1-3sh3.onrender.com/api/payments/momo-return';

      final result = await ApiService.createMomoPaymentUrl(
        amount: amount,
        orderInfo: 'Thanh toan don hang',
        appReturnUrl: appReturnUrl,
      );

      if (!mounted) return;

      final payUrl = result['payUrl'] as String;

      if (kIsWeb) {
        // Web: open in new tab (iframe bị MoMo chặn)
        final launched = await launchUrl(
          Uri.parse(payUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          setState(() => _error = 'Không thể mở trang thanh toán MoMo');
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng hoàn tất thanh toán ở tab mới.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Mobile: use WebView with proper Android settings
        final resultJson = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              paymentUrl: payUrl,
              callbackUrlPrefix: appReturnUrl,
            ),
          ),
        );

        if (!mounted) return;

        if (resultJson != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(resultJson: resultJson),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Payment'),
        backgroundColor: cs.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // MoMo logo area
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA50064), Color(0xFFD82D8B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'MoMo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thanh toán MoMo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ví điện tử MoMo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Amount: show as text if pre-filled, input if manual
                if (widget.prefillAmount != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA50064).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA50064).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_outlined, color: Color(0xFFA50064)),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.prefillAmount!.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} VND',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFA50064)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (VND)',
                      hintText: 'Nhập số tiền cần thanh toán',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                      final a = int.tryParse(value.trim());
                      if (a == null || a <= 0) return 'Số tiền không hợp lệ';
                      if (a < 1000) return 'Số tiền tối thiểu là 1,000 VND';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Pay button
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _handlePay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA50064),
                      foregroundColor: Colors.white,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.wallet),
                    label: Text(
                      _isLoading ? 'Đang xử lý...' : 'Thanh toán MoMo',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
