import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/payment_result.dart';
import 'screens/home_screen.dart';
import 'screens/payment_result_screen.dart';

import 'services/startup_handler_stub.dart'
    if (dart.library.html) 'services/startup_handler_web.dart';

/// Global key to navigate from startup handler
final navigatorKey = GlobalKey<NavigatorState>();
PaymentResult? _startupResult;

Future<void> main() async {
  // Safely load .env — failure should NOT prevent app from starting.
  // On Android, asset loading can fail if the build cache is corrupt.
  try {
    await dotenv.load();
  } catch (e, st) {
    debugPrint('⚠ dotenv.load failed: $e\n$st');
    // App continues — ApiService has a fallback default URL.
  }

  // Check if launched with VNPay result (web redirect)
  handleStartupResult((result) {
    _startupResult = result;
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Payment Demo',
      home: const _StartupGate(),
    );
  }
}

/// Shows result screen if launched with VNPay result, else Home
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    if (_startupResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              success: _startupResult!.success,
              message: _startupResult!.message,
              data: _startupResult!.data,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}