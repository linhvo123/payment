import 'package:flutter/material.dart';
import 'api_service.dart';
import 'payment_webview_screen.dart';
import 'result_screen.dart';

class VNPayScreen extends StatefulWidget {
  final int? prefillAmount;

  const VNPayScreen({super.key, this.prefillAmount});

  @override
  State<VNPayScreen> createState() => _VNPayScreenState();
}

class _VNPayScreenState extends State<VNPayScreen> {
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

      // This URL is intercepted by the WebView when VNPay redirects back.
      // The backend appends ?vnpay_result=... to this URL.
      const appReturnUrl = 'https://payment-1-3sh3.onrender.com/api/payments/vnpay-return';

      final paymentUrl = await ApiService.createPaymentUrl(
        amount: amount,
        appReturnUrl: appReturnUrl,
      );

      if (!mounted) return;

      // Navigate to WebView to process payment
      final resultJson = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            paymentUrl: paymentUrl,
            callbackUrlPrefix: appReturnUrl,
          ),
        ),
      );

      if (!mounted) return;

      if (resultJson != null) {
        // Payment completed — navigate to result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(resultJson: resultJson),
          ),
        );
      }
      // If resultJson is null, user pressed back — stay on home screen
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('VNPay Payment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                // App icon or title
                Icon(
                  Icons.payment,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thanh toán VNPay',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                // Amount: show as text if pre-filled, input if manual
                if (widget.prefillAmount != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_outlined, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.prefillAmount!.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} VND',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
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
                      if (a < 5000) return 'Số tiền tối thiểu là 5,000 VND';
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
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_outline),
                    label: Text(
                      _isLoading ? 'Đang xử lý...' : 'Thanh toán VNPay',
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
