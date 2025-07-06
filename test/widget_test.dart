// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:jtv7/main.dart';

void main() {
  testWidgets('JustTouch app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JustTouchApp());

    // Verify that our app displays the correct title
    expect(find.text('JustTouch'), findsOneWidget);
    expect(find.text('NFC File Sharing Made Simple'), findsOneWidget);

    // Verify that we have file selection button
    expect(find.text('Select Files'), findsOneWidget);
    
    // Verify that we have the touch to send button (should be disabled initially)
    expect(find.text('Touch to Send'), findsOneWidget);

    // Verify that we show the empty state
    expect(find.text('No files selected'), findsOneWidget);
  });
}
