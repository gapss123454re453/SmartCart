import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart_mobile/main.dart';

void main() {
  testWidgets('SmartCart renders splash while booting', (tester) async {
    await tester.pumpWidget(const SmartCartApp());

    expect(find.text('SmartCart'), findsOneWidget);
  });
}
