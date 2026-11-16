// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';

void main() {
  testWidgets('MathQuest splash navigates to the welcome screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ProgressController.initialize();
    await tester.pumpWidget(const ProviderScope(child: MathQuestApp()));
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Welcome to MathQuest!\nPlay, explore and grow your math skills.',
      ),
      findsOneWidget,
    );
  });
}
