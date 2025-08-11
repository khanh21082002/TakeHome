import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      [
        find.text('0'),
        find.text('1'),
      ],
      [
        findsOneWidget,
        findsNothing,
      ],
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(
      [
        find.text('0'),
        find.text('1'),
      ],
      [
        findsNothing,
        findsOneWidget,
      ],
    );
  });
}