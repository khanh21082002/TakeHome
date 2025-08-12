import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(const MyApp());
    
    // Initial state verification
    final findZero = find.text('0');
    final findOne = find.text('1');
    
    expect(findZero, findsOneWidget);
    expect(findOne, findsNothing);

    // Simulate user interaction
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Post-interaction state verification
    expect(findZero, findsNothing);
    expect(findOne, findsOneWidget);
  });
}