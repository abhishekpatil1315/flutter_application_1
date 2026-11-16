import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/games/pizza_party/pizza_party_screen.dart';
import 'package:flutter_application_1/models/child_profile.dart';
import 'package:flutter_application_1/models/game.dart';
import 'package:flutter_application_1/models/recommendation_engine.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';
import 'package:flutter_application_1/widgets/number_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'tutorial.pizza-party': true,
    });
    await ProgressController.initialize();
  });

  test('Pizza Party is an available Course 1 game', () {
    final entry = allGames.singleWhere((game) => game.id == 'pizza-party');
    expect(entry.course, 1);
    expect(entry.available, isTrue);
    expect(entry.builder, isNotNull);
  });

  testWidgets('solo screen uses number cards, two attempts, and coin hints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(progressProvider.notifier).addProfile(
      const ChildProfile(name: 'Ari', grade: 2, avatar: 'Penguin'),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PizzaPartyScreen(initialDifficulty: GameDifficulty.easy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Round 1 of 8'), findsOneWidget);
    expect(find.text('What fraction of the pizza is red?'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(NumberCard), findsNWidgets(10));
    expect(find.text('Check'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Check')).onPressed, isNull);

    final hint = find.text('Hint · 3');
    await tester.ensureVisible(hint);
    await tester.tap(hint);
    await tester.pumpAndSettle();
    expect(container.read(progressProvider).coins, 17);
    expect(find.textContaining('The pizza has'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hard level fixes the denominator and only asks for a numerator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PizzaPartyScreen(initialDifficulty: GameDifficulty.hard),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Round 1 of 8'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Fixed denominator')),
      findsOneWidget,
    );
    expect(find.byType(NumberCard), findsNWidgets(10));
    expect(find.text('The red amount is the same on both pizzas. Find the missing top number.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
