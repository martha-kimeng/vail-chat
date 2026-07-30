import 'package:flutter_test/flutter_test.dart';
import 'package:vail_chat/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VailApp());
    expect(find.byType(VailApp), findsOneWidget);
  });
}
