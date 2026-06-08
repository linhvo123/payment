import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String message;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success
                  ? Icons.check_circle
                  : Icons.error,
              size: 80,
            ),

            const SizedBox(height: 20),

            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
              child: const Text("Back Home"),
            ),
          ],
        ),
      ),
    );
  }
}