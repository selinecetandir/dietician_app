import 'package:flutter_test/flutter_test.dart';
import 'package:dietician_app/app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DieticianApp());
    expect(find.text('Dietician App'), findsOneWidget);
  });
}
