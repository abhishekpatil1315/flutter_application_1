import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/games/grid_hunt/grid_hunt_logic.dart';
import 'package:flutter_application_1/games/grid_hunt/grid_hunt_screen.dart';
import 'package:flutter_application_1/models/child_profile.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';
import 'package:flutter_application_1/screens/account_screens.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/profile_screens.dart';
import 'package:flutter_application_1/widgets/number_card.dart';

void main() {
  testWidgets('new player flow follows the reference screen order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ProgressController.initialize();
    await tester.pumpWidget(const ProviderScope(child: MathQuestApp()));

    expect(find.text('MathQuest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome to MathQuest!'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsWidgets);

    await tester.enterText(find.byType(TextField).at(0), 'parent@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);

    for (var index = 0; index < 6; index++) {
      await tester.enterText(find.byType(TextField).at(index), '$index');
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mika');
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('What grade are you in?'), findsOneWidget);

    await tester.tap(find.text('Grade 4'));
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pick Your Partner!'), findsOneWidget);

    await tester.tap(find.text('Fox').first);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Let's Go!"));
    await tester.tap(find.widgetWithText(FilledButton, "Let's Go!"));
    await tester.pumpAndSettle();
    expect(find.text("You're ready, Mika!"), findsOneWidget);
    expect(find.text('REASONING · COURSE 2'), findsOneWidget);
  });

  testWidgets('welcome screen scrolls without overflow on short viewports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 379);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pump();

    expect(find.textContaining('Welcome to MathQuest!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile setup advances through name, grade, and avatar steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileSetupScreen())),
    );

    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ari');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('What grade are you in?'), findsOneWidget);

    await tester.tap(find.text('Grade 4'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pick Your Partner!'), findsOneWidget);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Owl'), findsOneWidget);
  });

  testWidgets(
    'sign-in form starts in sign-in mode and exposes password toggle',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AccessScreen(startInSignIn: true)),
      );
      expect(find.text('Forgot Password?'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    },
  );

  testWidgets('Home navigation fits a compact phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await ProgressController.initialize();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Math Snap quick view and setup open the playable game on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'tutorial.math-snap': true});
      await ProgressController.initialize();
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sample: 2 + 3 = target 5'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Play').last);
      await tester.pumpAndSettle();
      expect(find.text('Set up Math Snap'), findsOneWidget);

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();
      expect(find.text('Math Snap'), findsOneWidget);
      expect(find.text('TARGET'), findsOneWidget);
      expect(find.text('SNAP!'), findsOneWidget);
      expect(find.byType(NumberCard), findsNWidgets(10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grade four home selects Reasoning without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await ProgressController.initialize();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(progressProvider.notifier)
        .addProfile(const ChildProfile(name: 'Bo', grade: 4, avatar: 'Fox'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Reasoning · Forest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grid Hunt fits a compact phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'tutorial.grid-hunt': true});
    await ProgressController.initialize();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: GridHuntScreen())),
    );
    await tester.pump();

    expect(find.text('Grid Hunt'), findsOneWidget);
    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('Your Turn'), findsOneWidget);
    expect(find.textContaining('/5'), findsNothing);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(find.byType(NumberCard), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong claims cost nothing and correct claims award progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'tutorial.grid-hunt': true});
    await ProgressController.initialize();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(progressProvider.notifier)
        .addProfile(const ChildProfile(name: 'Ari', grade: 2, avatar: 'Lion'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GridHuntScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final target = int.parse(
      tester.widget<Text>(find.byKey(const ValueKey('grid-hunt-target'))).data!,
    );
    final correctPath = findAdjacentMatchingPair(values, target)!;
    var wrongPath = <int>[];
    for (var length = 2; length <= 3 && wrongPath.isEmpty; length++) {
      for (var first = 0; first < values.length && wrongPath.isEmpty; first++) {
        for (var second = 0; second < values.length; second++) {
          if (!areAdjacentGridCells(first, second)) continue;
          if (length == 2 && values[first] + values[second] != target) {
            wrongPath = [first, second];
            break;
          }
          if (length == 3) {
            for (var third = 0; third < values.length; third++) {
              if (third != first &&
                  areAdjacentGridCells(second, third) &&
                  values[first] + values[second] + values[third] != target) {
                wrongPath = [first, second, third];
                break;
              }
            }
            if (wrongPath.isNotEmpty) break;
          }
        }
      }
    }

    await tester.tap(find.byType(NumberCard).at(wrongPath[0]));
    await tester.tap(find.byType(NumberCard).at(wrongPath[1]));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Claim selected set'));
    await tester.tap(find.text('Claim selected set'));
    await tester.pump();

    final wrongSum = wrongPath.fold<int>(
      0,
      (sum, index) => sum + values[index],
    );
    expect(find.text('Sum is $wrongSum, target $target'), findsOneWidget);
    expect(container.read(progressProvider).xp, 0);
    expect(container.read(progressProvider).coins, 20);
    expect(find.text('Your Turn'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NumberCard).at(correctPath[0]));
    await tester.tap(find.byType(NumberCard).at(correctPath[1]));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Claim selected set'));
    await tester.tap(find.text('Claim selected set'));
    await tester.pumpAndSettle();

    expect(container.read(progressProvider).xp, 8);
    expect(container.read(progressProvider).coins, 32);
    expect(container.read(progressProvider).gameStars['grid-hunt'], 3);
    expect(
      container.read(progressProvider).completedGameIds,
      contains('grid-hunt'),
    );
    expect(find.text("Prof Penguin's Turn"), findsOneWidget);
    expect(find.text('PROF PENGUIN 0 Cards  —  YOU 1 Cards'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Your Turn'), findsOneWidget);
    final nextValues = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final nextTarget = int.parse(
      tester.widget<Text>(find.byKey(const ValueKey('grid-hunt-target'))).data!,
    );
    expect(nextTarget, inInclusiveRange(2, 10));
    expect(findAdjacentMatchingPair(nextValues, nextTarget), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'difficulty change deals a fresh board and persists per profile',
    (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial.grid-hunt': true});
      await ProgressController.initialize();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(progressProvider.notifier)
          .addProfile(
            const ChildProfile(name: 'Ari', grade: 2, avatar: 'Lion'),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GridHuntScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final initialValues = tester
          .widgetList<NumberCard>(find.byType(NumberCard))
          .map((card) => card.value)
          .toList();
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      final hardValues = tester
          .widgetList<NumberCard>(find.byType(NumberCard))
          .map((card) => card.value)
          .toList();
      expect(hardValues.every((value) => value >= 2 && value <= 10), isTrue);
      expect(hardValues, isNot(initialValues));
      expect(
        ProgressController.preferences.getString(
          'grid-hunt.difficulty.profile.0',
        ),
        'hard',
      );
      expect(
        tester
            .widget<SegmentedButton<GridHuntDifficulty>>(
              find.byType(SegmentedButton<GridHuntDifficulty>),
            )
            .selected,
        {GridHuntDifficulty.hard},
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await container
          .read(progressProvider.notifier)
          .addProfile(const ChildProfile(name: 'Bo', grade: 4, avatar: 'Fox'));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GridHuntScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final secondProfileValues = tester
          .widgetList<NumberCard>(find.byType(NumberCard))
          .map((card) => card.value)
          .toList();
      expect(
        secondProfileValues.every((value) => value >= 1 && value <= 5),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await container.read(progressProvider.notifier).selectProfile(0);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GridHuntScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<GridHuntDifficulty>>(
              find.byType(SegmentedButton<GridHuntDifficulty>),
            )
            .selected,
        {GridHuntDifficulty.hard},
      );
    },
  );

  testWidgets('dragging a correct linked pair claims only on release', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'tutorial.grid-hunt': true});
    await ProgressController.initialize();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(progressProvider.notifier)
        .addProfile(const ChildProfile(name: 'Ari', grade: 2, avatar: 'Lion'));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GridHuntScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<NumberCard>(find.byType(NumberCard))
        .map((card) => card.value)
        .toList();
    final target = int.parse(
      tester.widget<Text>(find.byKey(const ValueKey('grid-hunt-target'))).data!,
    );
    final path = findAdjacentMatchingPair(values, target)!;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NumberCard).at(path.first)),
    );
    await gesture.moveTo(
      tester.getCenter(find.byType(NumberCard).at(path.last)),
      timeStamp: const Duration(milliseconds: 100),
    );
    await tester.pump();

    expect(find.text('Your Turn'), findsOneWidget);
    expect(container.read(progressProvider).xp, 0);
    expect(find.text('Sum: $target'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text("Prof Penguin's Turn"), findsOneWidget);
    expect(container.read(progressProvider).xp, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('10 card keeps its two-digit value without an image asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, height: 120, child: NumberCard(value: 10)),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
