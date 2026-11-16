import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/games/math_snap/math_snap_screen.dart';
import 'package:flutter_application_1/models/recommendation_engine.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';
import 'package:flutter_application_1/widgets/number_card.dart';

void main() {
  testWidgets('a correct SNAP resolves the round and awards coins', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'tutorial.math-snap': true});
    await ProgressController.initialize();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MathSnapScreen(initialDifficulty: GameDifficulty.easy),
        ),
      ),
    );
    await tester.pump();

    final target = int.parse(
      tester.widget<Text>(find.byKey(const Key('math-snap-target'))).data!,
    );
    final dealtCards = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    var first = -1;
    var second = -1;
    for (var i = 0; i < dealtCards.length; i++) {
      for (var j = i + 1; j < dealtCards.length; j++) {
        if (dealtCards[i] + dealtCards[j] == target) {
          first = i;
          second = j;
          break;
        }
      }
      if (first >= 0) break;
    }
    expect(first, greaterThanOrEqualTo(0));

    await tester.ensureVisible(find.byType(NumberCard).at(first));
    await tester.tap(find.byType(NumberCard).at(first));
    await tester.tap(find.byType(NumberCard).at(second));
    await tester.ensureVisible(find.text('SNAP!'));
    await tester.tap(find.widgetWithText(FilledButton, 'SNAP!'));
    await tester.pumpAndSettle();

    expect(find.text('SNAP! You got it first!'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(container.read(progressProvider).coins, 12);
  });
}
