import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App basic widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mewati Tune Player'),
          ),
        ),
      ),
    );
    expect(find.text('Mewati Tune Player'), findsOneWidget);
  });
}
