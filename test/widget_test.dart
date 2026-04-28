// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:env_reading/app.dart';
import 'package:env_reading/services/mock_data_repository.dart';

void main() {
  testWidgets('Dashboard renders with mock data', (WidgetTester tester) async {
    final repository = MockDataRepository();

    await tester.pumpWidget(
      App(repository: repository, firebaseReady: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Study Desk Monitor'), findsOneWidget);
  });
}
