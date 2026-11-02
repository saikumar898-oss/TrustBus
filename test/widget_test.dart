import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TrustBusApp());
    expect(find.byType(TrustBusApp), findsOneWidget);
  });
}
