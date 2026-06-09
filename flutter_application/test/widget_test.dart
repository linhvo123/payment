import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VNPayApp());

    // Verify the home screen is shown
    expect(find.text('Thanh toán VNPay'), findsOneWidget);
    expect(find.text('Số tiền (VND)'), findsOneWidget);
  });
}
