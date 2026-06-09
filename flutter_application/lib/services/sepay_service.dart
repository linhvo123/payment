import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/sepay_config.dart';

enum PaymentStatus { waiting, success, failed, timeout }

class SepayTransaction {
  final String id;
  final String bankBrandName;
  final String accountNumber;
  final double amount;
  final String content;
  final String transferType;
  final DateTime transactionDate;

  SepayTransaction({
    required this.id,
    required this.bankBrandName,
    required this.accountNumber,
    required this.amount,
    required this.content,
    required this.transferType,
    required this.transactionDate,
  });

  factory SepayTransaction.fromJson(Map<String, dynamic> json) {
    return SepayTransaction(
      id: json['id']?.toString() ?? '',
      bankBrandName: json['bank_brand_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      amount: double.tryParse(json['amount_in']?.toString() ?? '0') ?? 0,
      content: json['transaction_content'] ?? '',
      transferType: json['transfer_type'] ?? '',
      transactionDate:
          DateTime.tryParse(json['transaction_date'] ?? '') ?? DateTime.now(),
    );
  }
}

class SepayService {
  static String generateOrderCode() {
    final rand = Random();
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final suffix = rand.nextInt(999).toString().padLeft(3, '0');
    return 'DH$timestamp$suffix';
  }

  static String buildTransferContent(String orderCode) {
    return 'Thanh toan $orderCode';
  }

  static Future<List<SepayTransaction>> getRecentTransactions({
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '${SepayConfig.transactionsUrl}?limit=$limit&account_number=${SepayConfig.bankAccount}',
      );

      debugPrint('[SePay] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${SepayConfig.apiToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('[SePay] Status: ${response.statusCode}');
      debugPrint(
          '[SePay] Body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 && data['transactions'] != null) {
          final txs = (data['transactions'] as List)
              .map((t) => SepayTransaction.fromJson(t))
              .toList();
          debugPrint('[SePay] Got ${txs.length} transactions');
          for (final tx in txs) {
            debugPrint('[SePay] TX: ${tx.amount} | ${tx.content}');
          }
          return txs;
        } else {
          debugPrint('[SePay] Unexpected response: ${data}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SePay] ERROR: $e');
      return [];
    }
  }

  static Future<SepayTransaction?> checkPayment({
    required String orderCode,
    required int expectedAmount,
  }) async {
    final transactions = await getRecentTransactions();

    for (final tx in transactions) {
      final txContent = tx.content.toLowerCase();
      final code = orderCode.toLowerCase();
      debugPrint(
          '[SePay] Checking: "$txContent" contains "$code" ? ${txContent.contains(code)}');
      if (txContent.contains(code) && tx.amount >= expectedAmount * 0.99) {
        return tx;
      }
    }
    return null;
  }

  static Stream<PaymentStatus> pollPaymentStatus({
    required String orderCode,
    required int expectedAmount,
    Duration interval = const Duration(seconds: 5),
    Duration timeout = const Duration(seconds: 300),
  }) async* {
    yield PaymentStatus.waiting;

    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);

      debugPrint('[SePay] Polling for order $orderCode...');
      final tx = await checkPayment(
        orderCode: orderCode,
        expectedAmount: expectedAmount,
      );

      if (tx != null) {
        debugPrint('[SePay] MATCH FOUND! $tx');
        yield PaymentStatus.success;
        return;
      }

      if (!DateTime.now().isBefore(deadline)) break;
      yield PaymentStatus.waiting;
    }

    yield PaymentStatus.timeout;
  }
}
