import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/games/combo_forge/combo_forge_screen.dart';
import 'package:flutter_application_1/games/combo_forge/combo_forge_logic.dart';
import 'package:flutter_application_1/games/number_builder/number_builder_logic.dart';
import 'package:flutter_application_1/games/number_builder/number_builder_screen.dart';
import 'package:flutter_application_1/models/recommendation_engine.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/widgets/number_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'tutorial.number-builder': true,
      'tutorial.combo-forge': true,
      'tutorial.math-array': true,
      'tutorial.number-leap': true,
    });
    await ProgressController.initialize();
  });

  testWidgets('Number Builder accepts the optimal number and awards progress', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: NumberBuilderScreen(initialDifficulty: GameDifficulty.easy),
        ),
      ),
    );
    await tester.pump();

    final cards = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final objectiveText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .firstWhere(
          (text) => text.contains('SMALLEST') || text.contains('LARGEST'),
        );
    final objective = objectiveText.contains('SMALLEST')
        ? NumberBuilderObjective.smallest
        : NumberBuilderObjective.largest;
    final puzzle = NumberBuilderPuzzle(
      cards: cards,
      slots: 2,
      objective: objective,
    );
    final answer = optimalNumberBuilderAnswers(puzzle).single.toString();

    for (var slot = 0; slot < answer.length; slot++) {
      final digit = int.parse(answer[slot]);
      final cardIndex = cards.indexOf(digit);
      await tester.ensureVisible(find.byType(NumberCard).at(cardIndex));
      await tester.tap(find.byType(NumberCard).at(cardIndex));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(ValueKey('number-builder-slot-$slot')),
      );
      await tester.tap(find.byKey(ValueKey('number-builder-slot-$slot')));
      await tester.pump();
    }

    await tester.ensureVisible(find.text('BUILD'));
    await tester.tap(find.text('BUILD'));
    await tester.pumpAndSettle();

    expect(
      find.text('Excellent building! $answer is optimal.'),
      findsOneWidget,
    );
    expect(container.read(progressProvider).coins, 12);
    expect(container.read(progressProvider).xp, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Combo Forge keeps the result hidden until submitting', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ComboForgeScreen(initialDifficulty: GameDifficulty.easy),
        ),
      ),
    );
    await tester.pump();

    final target = int.parse(
      tester.widget<Text>(find.byKey(const Key('combo-forge-target'))).data!,
    );
    final cards = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final first = cards.indexWhere(
      (value) =>
          cards.any((other) => other != value && value + other == target),
    );
    final second = cards.indexWhere(
      (value) => value != cards[first] && value + cards[first] == target,
    );
    expect(first, greaterThanOrEqualTo(0));
    expect(second, greaterThanOrEqualTo(0));

    await tester.ensureVisible(find.byType(NumberCard).at(first));
    await tester.tap(find.byType(NumberCard).at(first));
    await tester.pump();
    await tester.ensureVisible(find.text('+'));
    await tester.tap(find.text('+').first);
    await tester.pump();
    await tester.ensureVisible(find.byType(NumberCard).at(second));
    await tester.tap(find.byType(NumberCard).at(second));
    await tester.pump();

    expect(find.text('Submitted result: $target'), findsNothing);
    await tester.ensureVisible(find.text('SUBMIT'));
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted result: $target'), findsOneWidget);
    expect(
      find.text('Forged! Your expression reaches the target.'),
      findsOneWidget,
    );
    expect(container.read(progressProvider).coins, 12);
    expect(container.read(progressProvider).xp, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Combo Forge Medium deducts game points, not wallet coins', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ComboForgeScreen(initialDifficulty: GameDifficulty.medium),
        ),
      ),
    );
    await tester.pump();

    final target = int.parse(
      tester.widget<Text>(find.byKey(const Key('combo-forge-target'))).data!,
    );
    final values = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final validExpression = _findMediumSolution(values, target);
    await _tapExpression(
      tester,
      validExpression.cardIndices,
      validExpression.operations,
    );
    await tester.ensureVisible(find.text('SUBMIT'));
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();
    expect(
      find.text('Forged! Your expression reaches the target.'),
      findsOneWidget,
    );
    expect(container.read(progressProvider).coins, 12);
    expect(container.read(progressProvider).xp, 8);

    await tester.tap(find.text('Next Round'));
    await tester.pumpAndSettle();
    final nextTarget = int.parse(
      tester.widget<Text>(find.byKey(const Key('combo-forge-target'))).data!,
    );
    final nextCards = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final zeroIndex = nextCards.indexOf(0);
    final oneIndex = nextCards.indexOf(1);
    await _tapExpression(
      tester,
      [zeroIndex, oneIndex],
      const [ComboForgeOperation.add],
    );
    await tester.ensureVisible(find.text('SUBMIT'));
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your expression equals 1, not $nextTarget. (−1 points)'),
      findsOneWidget,
    );
    expect(find.text('ROUND SCORE'), findsOneWidget);
    expect(find.text('9 pts'), findsOneWidget);
    expect(container.read(progressProvider).coins, 12);
    expect(container.read(progressProvider).xp, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Builder and Combo Forge launch in solo mode', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pump();

    await tester.ensureVisible(find.textContaining('Number Builder').first);
    await tester.tap(find.textContaining('Number Builder').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Sample: build the smallest number from 3, 6, 1'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Play').last);
    await tester.pumpAndSettle();
    expect(find.text('Set up Number Builder'), findsOneWidget);
    expect(find.text('Choose a mode'), findsNothing);
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();
    expect(find.text('Number Builder'), findsOneWidget);
    expect(find.textContaining('NO TIMER'), findsNothing);

    await tester.tap(find.byTooltip('Back to journey'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Combo Forge').first);
    await tester.tap(find.textContaining('Combo Forge').first);
    await tester.pumpAndSettle();
    expect(find.text('Sample: target 15 · 3 × 5'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Play').last);
    await tester.pumpAndSettle();
    expect(find.text('Set up Combo Forge'), findsOneWidget);
    expect(find.text('Choose a mode'), findsNothing);
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();
    expect(find.text('Combo Forge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapExpression(
  WidgetTester tester,
  List<int> cardIndices,
  List<ComboForgeOperation> operations,
) async {
  for (var index = 0; index < cardIndices.length; index++) {
    final card = find.byType(NumberCard).at(cardIndices[index]);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    if (index >= operations.length) continue;
    final operator = find.text(operations[index].symbol).first;
    await tester.ensureVisible(operator);
    await tester.tap(operator);
    await tester.pump();
  }
}

_Expression _findMediumSolution(List<int> cards, int target) {
  const operations = [ComboForgeOperation.add, ComboForgeOperation.subtract];
  for (var first = 0; first < cards.length; first++) {
    for (var second = 0; second < cards.length; second++) {
      if (first == second) continue;
      for (var third = 0; third < cards.length; third++) {
        if (third == first || third == second) continue;
        for (final firstOperation in operations) {
          for (final secondOperation in operations) {
            final expressionOperations = [firstOperation, secondOperation];
            if (evaluateComboForgeExpression([
                  cards[first],
                  cards[second],
                  cards[third],
                ], expressionOperations) ==
                target) {
              return _Expression(
                cardIndices: [first, second, third],
                operations: expressionOperations,
              );
            }
          }
        }
      }
    }
  }
  throw StateError('Generated Medium puzzle has no test solution.');
}

class _Expression {
  const _Expression({required this.cardIndices, required this.operations});

  final List<int> cardIndices;
  final List<ComboForgeOperation> operations;
}
