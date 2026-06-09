import 'package:flutter/material.dart';

import '../data/payment_methods.dart';
import '../models/payment_result.dart';
import '../services/payment_service.dart';

import '../services/gateways/bank_gateway.dart';
import '../services/gateways/momo_gateway.dart';
import '../services/gateways/payment_gateway.dart';
import '../services/gateways/vnpay_gateway.dart';

import '../widgets/payment_method_tile.dart';
import 'payment_result_screen.dart';
import 'payment_webview.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedMethodId;
  bool isLoading = false;

  final paymentService = PaymentService();

  Future<void> handlePayment() async {
    if (selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán')),
      );
      return;
    }

    PaymentGateway gateway;
    switch (selectedMethodId) {
      case 'momo':
        gateway = MomoGateway();
        break;
      case 'vnpay':
        gateway = VNPayGateway();
        break;
      default:
        gateway = BankGateway();
    }

    setState(() => isLoading = true);

    final result = await paymentService.processPayment(
      gateway: gateway,
      amount: 500000,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    // For VNPay: open WebView and wait for payment result
    if (selectedMethodId == 'vnpay' && result.pending) {
      final vnpayUrl = result.message; // URL stored in message
      final webViewResult = await Navigator.push<PaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(paymentUrl: vnpayUrl),
        ),
      );

      if (!mounted) return;

      if (webViewResult != null) {
        _showResult(webViewResult);
      }
      return;
    }

    _showResult(result);
  }

  void _showResult(PaymentResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          success: result.success,
          message: result.message,
          data: result.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "Total: 500,000 VND",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount:
                    paymentMethods.length,
                itemBuilder:
                    (context, index) {

                  final method =
                      paymentMethods[index];

                  return PaymentMethodTile(
                    method: method,
                    selectedId:
                        selectedMethodId,
                    onChanged: (value) {
                      setState(() {
                        selectedMethodId =
                            value;
                      });
                    },
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : handlePayment,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'PAY NOW',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}