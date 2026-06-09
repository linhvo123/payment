import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const VNPayApp());
}

class VNPayApp extends StatelessWidget {
  const VNPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VNPay Payment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
