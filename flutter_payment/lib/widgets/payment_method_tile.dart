import 'package:flutter/material.dart';

import '../models/payment_method.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final String? selectedId;
  final Function(String?) onChanged;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(method.name),
      value: method.id,
      groupValue: selectedId,
      onChanged: onChanged,
    );
  }
}