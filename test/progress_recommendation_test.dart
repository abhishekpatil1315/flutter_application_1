import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/recommendation_engine.dart';
import 'package:flutter_application_1/models/child_profile.dart';
import 'package:flutter_application_1/providers/progress_provider.dart';

void main() {
  late ProgressController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = ProgressController(await SharedPreferences.getInstance());
  });

  tearDown(() => controller.dispose());

  test(
    'records progress and routes struggling players to foundation practice',
    () async {
      final recommendation = await controller.recordGameResult(
        gameId: 'fraction-clash',
        course: 2,
        correctAnswers: 2,
        totalQuestions: 5,
        averageSeconds: 35,
        mistakes: 3,
        difficulty: GameDifficulty.medium,
      );

      expect(recommendation.gameId, 'number-builder');
      expect(recommendation.needsFollowUp, isTrue);
      expect(controller.state.pendingReviewGameId, 'fraction-clash');
      expect(controller.state.recommendedGameId, 'number-builder');
      expect(controller.state.completedGameIds, contains('fraction-clash'));
      expect(controller.state.xp, 20);
    },
  );

  test(
    'performance follow-up returns to challenge or recommends more foundation',
    () async {
      await controller.recordGameResult(
        gameId: 'fraction-clash',
        course: 2,
        correctAnswers: 1,
        totalQuestions: 5,
        averageSeconds: 35,
        mistakes: 4,
        difficulty: GameDifficulty.medium,
      );
      await controller.resolvePerformanceFollowUp(
        improved: false,
        currentFoundationGameId: 'number-builder',
      );
      expect(controller.state.recommendedGameId, 'math-snap');
      expect(controller.state.pendingReviewGameId, 'fraction-clash');

      await controller.resolvePerformanceFollowUp(
        improved: true,
        currentFoundationGameId: 'math-snap',
      );
      expect(controller.state.recommendedGameId, 'fraction-clash');
      expect(controller.state.pendingReviewGameId, isNull);
    },
  );

  test(
    'completing each required game with two stars masters the course',
    () async {
      for (final gameId in [
        'math-snap',
        'number-builder',
        'combo-forge',
        'grid-hunt',
        'math-array',
        'number-leap',
        'pizza-party',
        'number-trail',
        'flip-5',
      ]) {
        await controller.recordGameResult(
          gameId: gameId,
          course: 1,
          correctAnswers: 4,
          totalQuestions: 5,
          averageSeconds: 40,
          mistakes: 1,
          difficulty: GameDifficulty.medium,
        );
      }

      expect(controller.state.masteredCourses, contains(1));
    },
  );

  test(
    'keeps coins and game progress separate for each child profile',
    () async {
      await controller.addProfile(
        const ChildProfile(name: 'Ari', grade: 2, avatar: 'Penguin'),
      );
      await controller.awardCoins(10);
      await controller.markGameCompleted('grid-hunt');
      await controller.addProfile(
        const ChildProfile(name: 'Bo', grade: 4, avatar: 'Fox'),
      );
      expect(controller.state.coins, 20);
      expect(controller.state.completedGameIds, isEmpty);

      await controller.awardCoins(3);
      await controller.selectProfile(0);
      expect(controller.state.coins, 30);
      expect(controller.state.completedGameIds, contains('grid-hunt'));
      await controller.selectProfile(1);
      expect(controller.state.coins, 23);
      expect(controller.state.completedGameIds, isEmpty);
    },
  );

  test('new child profiles start with 20 shared wallet coins', () async {
    await controller.addProfile(
      const ChildProfile(name: 'Ari', grade: 2, avatar: 'Penguin'),
    );

    expect(controller.state.coins, 20);
    await controller.spendCoins(3);
    expect(controller.state.coins, 17);
  });

  test(
    'game rewards add XP and coins without reducing recorded stars',
    () async {
      await controller.addProfile(
        const ChildProfile(name: 'Ari', grade: 2, avatar: 'Penguin'),
      );
      await controller.recordGameReward(
        gameId: 'grid-hunt',
        xp: 8,
        coins: 12,
        stars: 3,
      );
      await controller.recordGameReward(
        gameId: 'grid-hunt',
        xp: 8,
        coins: 12,
        stars: 1,
      );

      expect(controller.state.xp, 16);
      expect(controller.state.coins, 44);
      expect(controller.state.gameStars['grid-hunt'], 3);
      expect(controller.state.completedGameIds, contains('grid-hunt'));
      expect(controller.state.streak, 0);
      expect(controller.state.recommendedGameId, isNull);
    },
  );

  test(
    'round rewards persist XP and coins without completing the game early',
    () async {
      await controller.awardRoundReward(xp: 8, coins: 12);

      expect(controller.state.xp, 8);
      expect(controller.state.coins, 12);
      expect(controller.state.completedGameIds, isEmpty);
      expect(controller.state.gameStars, isEmpty);
    },
  );

  test('updates the daily streak once and restores child progress', () async {
    final preferences = await SharedPreferences.getInstance();
    await controller.addProfile(
      const ChildProfile(name: 'Ari', grade: 2, avatar: 'Penguin'),
    );
    Future<void> recordResult() async {
      await controller.recordGameResult(
        gameId: 'grid-hunt',
        course: 1,
        correctAnswers: 3,
        totalQuestions: 5,
        averageSeconds: 25,
        mistakes: 0,
        difficulty: GameDifficulty.easy,
      );
    }

    await recordResult();
    await recordResult();
    expect(controller.state.streak, 1);

    final restored = ProgressController(preferences);
    addTearDown(restored.dispose);
    expect(restored.state.profiles.single.name, 'Ari');
    expect(restored.state.xp, 60);
    expect(restored.state.streak, 1);
  });
}
