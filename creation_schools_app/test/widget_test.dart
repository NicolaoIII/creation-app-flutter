import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creation_schools_app/app/app.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
