// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:clietapp/main.dart';

void main() {
  testWidgets('App loads and main UI is present', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const NotionBookApp());

    // Check for main UI elements (replace with your actual home screen text/widgets)
    expect(find.text('NotionBook – Guest Booking Manager'), findsOneWidget);
    // Optionally check for login or dashboard widgets
    // expect(find.byType(AuthGate), findsOneWidget);
  });
}
