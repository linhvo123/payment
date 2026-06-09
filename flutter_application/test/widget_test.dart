import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PaymentApp());

    // Verify the home screen is shown with payment options
    expect(find.text('Chọn phương thức thanh toán'), findsOneWidget);
  });
}
