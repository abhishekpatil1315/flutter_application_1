import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  static const _achievementNames = <(String, String)>[
    ('Number Ninja', 'Complete your first number challenge.'),
    ('Quick Thinker', 'Solve a round before the timer runs low.'),
    ('Math Explorer', 'Try games across all three courses.'),
    ('Star Collector', 'Earn three stars in a game.'),
    ('Coin Champion', 'Earn your first 50 coins.'),
    ('Streak Starter', 'Build a three-day learning streak.'),
    ('Card Captain', 'Complete five card challenges.'),
    ('Pattern Spotter', 'Find a correct linked-card path.'),
    ('Practice Pro', 'Replay a game to improve your score.'),
    ('Addition Ace', 'Solve 20 addition questions.'),
    ('Product Pro', 'Master a multiplication challenge.'),
    ('Fraction Friend', 'Complete a fractions game.'),
    ('Decimal Dynamo', 'Complete a decimals game.'),
    ('Ratio Ranger', 'Complete a ratio challenge.'),
    ('Percent Pilot', 'Complete a percent challenge.'),
    ('Place Value Pro', 'Build a number using place value.'),
    ('Trail Blazer', 'Explore the Number Trail.'),
    ('Bingo Bright', 'Claim a Math Bingo square.'),
    ('Factor Finder', 'Find a factor pair.'),
    ('Fair Share', 'Complete a sharing challenge.'),
    ('Combo Crafter', 'Forge a correct number combination.'),
    ('Ice Explorer', 'Reach the Ice Trail.'),
    ('Mastery Maker', 'Master a course.'),
    ('Perfect Round', 'Answer every question correctly in a game.'),
    ('Steady Learner', 'Complete three games.'),
    ('Curious Mind', 'Open a game tutorial.'),
    ('Hintful Hero', 'Use a hint to help solve a challenge.'),
    ('Course Champion', 'Earn two stars in every course game.'),
    ('Math Mentor', 'Practice a foundational skill.'),
    ('Quest Legend', 'Complete all three courses.'),
  ];

  static const _badgeIcons = <IconData>[
    Icons.bolt_rounded,
    Icons.timer_rounded,
    Icons.explore_rounded,
    Icons.star_rounded,
    Icons.monetization_on_rounded,
    Icons.local_fire_department_rounded,
    Icons.style_rounded,
    Icons.grid_3x3_rounded,
    Icons.replay_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    final unlocked = List<bool>.generate(
      _achievementNames.length,
      (index) => switch (index) {
        0 => state.completedGameIds.isNotEmpty,
        2 => allGames
                .where((game) => state.completedGameIds.contains(game.id))
                .map((game) => game.course)
                .toSet()
                .length >=
            3,
        3 => state.gameStars.values.any((stars) => stars >= 3),
        4 => state.coins >= 50,
        5 => state.streak >= 3,
        6 => state.completedGameIds.length >= 5,
        7 => state.completedGameIds.contains('grid-hunt'),
        24 => state.completedGameIds.length >= 3,
        _ => false,
      },
    );
    final unlockedCount = unlocked.where((isUnlocked) => isUnlocked).length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to profile',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Achievements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$unlockedCount of ${_achievementNames.length} Unlocked',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _achievementNames.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (context, index) {
              final achievement = _achievementNames[index];
              final isUnlocked = unlocked[index];
              return Semantics(
                button: true,
                label: '${achievement.$1}, ${isUnlocked ? 'unlocked' : 'locked'}. ${achievement.$2}',
                child: Material(
                  color: isUnlocked ? const Color(0xFFFFF5CC) : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(achievement.$1),
                        content: Text(
                          '${achievement.$2}${isUnlocked ? ' You’ve unlocked this badge!' : ' Keep playing to unlock this badge.'}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUnlocked
                                ? _badgeIcons[index % _badgeIcons.length]
                                : Icons.lock_outline_rounded,
                            size: 32,
                            color: isUnlocked ? AppColors.primaryDark : AppColors.darkGrey,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            achievement.$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('More achievements unlock as you explore MathQuest.'),
        ],
      ),
    );
  }
}
