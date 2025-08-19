import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/core/app.dart';

void main() {
  testWidgets('Streamshort app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: StreamshortApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('Streamshort'), findsOneWidget);
  });
}
