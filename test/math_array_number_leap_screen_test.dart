import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/games/math_array/math_array_screen.dart';
import 'package:flutter_application_1/games/number_leap/number_leap_screen.dart';
import 'package:flutter_application_1/models/child_profile.dart';
import 'package:flutter_application_1/models/game.dart';
import 'package:flutter_application_1/models/recommendation_engine.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'tutorial.math-array': true,
      'tutorial.number-leap': true,
    });
    await ProgressController.initialize();
  });

  test('registers both games as available in Course 1', () {
    for (final id in ['math-array', 'number-leap']) {
      final game = allGames.singleWhere((entry) => entry.id == id);
      expect(game.course, 1);
      expect(game.available, isTrue);
      expect(game.builder, isNotNull);
    }
  });

  testWidgets(
    'Math Array uses ordered digit input and awards a correct round',
    (tester) async {
      _setPhoneViewport(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(progressProvider.notifier)
          .addProfile(
            const ChildProfile(name: 'Ari', grade: 1, avatar: 'Penguin'),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MathArrayScreen(initialDifficulty: GameDifficulty.easy),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Round 1 of 6'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      final hintButton = find.textContaining('Hint · 20 coins');
      await tester.ensureVisible(hintButton);
      await tester.tap(hintButton);
      await tester.pump();
      expect(container.read(progressProvider).coins, 17);
      expect(find.text('Hint used'), findsOneWidget);
      final groupLabel = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .firstWhere((text) => text.contains('equal groups'));
      final rows = int.parse(groupLabel.split(' ').first);
      final dotsPerRow =
          tester.widgetList<Icon>(find.byIcon(Icons.circle)).length ~/ rows;
      final totalDigits = (rows * dotsPerRow)
          .toString()
          .split('')
          .map(int.parse);
      final answer = [rows, dotsPerRow, ...totalDigits];

      for (final digit in answer) {
        final button = find.byKey(ValueKey('math-array-digit-$digit'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
      }

      await tester.ensureVisible(find.text('CHECK'));
      await tester.tap(find.text('CHECK'));
      await tester.pump();

      expect(
        find.textContaining('Great job! $rows × $dotsPerRow'),
        findsOneWidget,
      );
      expect(container.read(progressProvider).coins, 29);
      expect(container.read(progressProvider).xp, 8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Number Leap builds a missing value with the digit pad', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(progressProvider.notifier)
        .addProfile(const ChildProfile(name: 'Bo', grade: 2, avatar: 'Fox'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: NumberLeapScreen(initialDifficulty: GameDifficulty.easy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Round 1 of 6'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final missing = find.byKey(const ValueKey('number-leap-answer-0'));
    expect(missing, findsOneWidget);

    final visible = <int, int>{};
    for (var index = 0; index < 5; index++) {
      final tile = find.byKey(ValueKey('number-leap-number-$index'));
      if (tile.evaluate().isNotEmpty) {
        visible[index] = int.parse(
          tester
              .widget<Text>(
                find.descendant(of: tile, matching: find.byType(Text)),
              )
              .data!,
        );
      }
    }
    final missingIndex = List.generate(
      5,
      (index) => index,
    ).firstWhere((index) => !visible.containsKey(index));
    final firstIndex = visible.keys.first;
    final lastIndex = visible.keys.last;
    final step =
        (visible[lastIndex]! - visible[firstIndex]!) ~/
        (lastIndex - firstIndex);
    final missingNumber =
        visible[firstIndex]! + step * (missingIndex - firstIndex);

    for (final digit in '$missingNumber'.split('')) {
      final button = find.byKey(ValueKey('number-leap-digit-$digit'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    await tester.ensureVisible(find.text('CHECK'));
    await tester.tap(find.text('CHECK'));
    await tester.pump();

    expect(find.textContaining('Great leap!'), findsOneWidget);
    expect(container.read(progressProvider).coins, 32);
    expect(container.read(progressProvider).xp, 8);
    expect(tester.takeException(), isNull);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
