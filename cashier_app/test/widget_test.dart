// This is a basic Flutter widget test for the Cashier App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cashier_app/main.dart';

void main() {
  testWidgets('CashierApp widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashierApp());

    // Verify that the app title is displayed.
    expect(find.text('Restaurant Billing System'), findsOneWidget);

    // Verify that the server status card is displayed.
    expect(find.text('Server Status'), findsOneWidget);

    // Verify that the server information card is displayed.
    expect(find.text('Server Information'), findsOneWidget);

    // Verify that the connected clients card is displayed.
    expect(find.text('Connected Clients'), findsOneWidget);

    // Verify that the quick actions card is displayed.
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('Server manager initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CashierApp());
    
    // Allow the widget to build and the server to attempt starting
    await tester.pump(const Duration(seconds: 1));

    // Verify that the server status is displayed (should be starting or running)
    expect(find.textContaining('STARTING'), findsAny);
  });
}
