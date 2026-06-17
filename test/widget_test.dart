// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build a simple widget to verify the project compiles
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Demixr')),
          body: const Center(child: Text('Hello')),
        ),
      ),
    );

    expect(find.text('Demixr'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
