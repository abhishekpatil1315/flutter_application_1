import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game.dart';
import '../providers/progress_provider.dart';
import '../models/recommendation_engine.dart';
import '../games/grid_hunt/grid_hunt_logic.dart';
import '../games/grid_hunt/grid_hunt_screen.dart';
import '../games/math_array/math_array_screen.dart';
import '../games/combo_forge/combo_forge_screen.dart';
import '../games/math_snap/math_snap_screen.dart';
import '../games/number_leap/number_leap_screen.dart';
import '../games/number_builder/number_builder_screen.dart';
import '../games/pizza_party/pizza_party_screen.dart';
import '../theme/app_assets.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_avatar.dart';
import '../widgets/number_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const JourneyTab(), const RankTab(), const SettingsTab()];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          NavigationDestination(
            icon: Image.asset(
              AppAssets.home,
              width: 28,
              height: 28,
              color: Colors.white,
            ),
            selectedIcon: Image.asset(
              AppAssets.home,
              width: 28,
              height: 28,
              color: AppColors.primaryDark,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Image.asset(
              AppAssets.rank,
              width: 28,
              height: 28,
              color: Colors.white,
            ),
            selectedIcon: Image.asset(
              AppAssets.rank,
              width: 28,
              height: 28,
              color: AppColors.primaryDark,
            ),
            label: 'Rank',
          ),
          NavigationDestination(
            icon: Image.asset(
              AppAssets.settings,
              width: 28,
              height: 28,
              color: Colors.white,
            ),
            selectedIcon: Image.asset(
              AppAssets.settings,
              width: 28,
              height: 28,
              color: AppColors.primaryDark,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class JourneyTab extends ConsumerStatefulWidget {
  const JourneyTab({super.key});

  @override
  ConsumerState<JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends ConsumerState<JourneyTab> {
  int? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final currentIndex = progress.currentProfile;
    final profile = currentIndex == null
        ? null
        : progress.profiles[currentIndex];
    final startingCourse = profile?.startingCourse ?? 1;
    final recommendedGame =
        allGames
            .where((game) => game.id == progress.recommendedGameId)
            .firstOrNull ??
        allGames.firstWhere(
          (game) => game.course == startingCourse && game.available,
          orElse: () =>
              allGames.firstWhere((game) => game.course == startingCourse),
        );
    final selectedCourse = _selectedCourse ?? recommendedGame.course;
    final canOpenCourse = const RecommendationEngine().isCourseAvailable(
      learnerStartingCourse: startingCourse,
      course: selectedCourse,
      masteredCourses: progress.masteredCourses,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${profile?.name ?? 'Adventurer'}!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Text('Ready for today’s quest?'),
                  ],
                ),
              ),
              Semantics(
                label: 'Switch player profile',
                button: true,
                child: IconButton(
                  tooltip: 'Switch player',
                  onPressed: () => context.go('/profiles'),
                  icon: const Icon(Icons.switch_account_rounded),
                ),
              ),
              _CoinPill(coins: progress.coins),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              AnimalAvatar(name: profile?.avatar ?? '', size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      'Open ${profile?.name ?? 'player'} profile, ${progress.xp} XP, ${progress.coins} coins',
                  child: InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'XP ${progress.xp}  ·  🔥 ${progress.streak}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _ContinueQuestCard(
            game: recommendedGame,
            stars: progress.gameStars[recommendedGame.id] ?? 0,
            onTap: () => _showGameQuickView(
              context,
              recommendedGame,
              progress.gameStars[recommendedGame.id] ?? 0,
              initialDifficulty:
                  progress.recommendedDifficulty ?? GameDifficulty.medium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var index = 1; index <= 3; index++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Course $index'),
                          selected: selectedCourse == index,
                          onSelected: (_) {
                            final available = const RecommendationEngine()
                                .isCourseAvailable(
                                  learnerStartingCourse: startingCourse,
                                  course: index,
                                  masteredCourses: progress.masteredCourses,
                                );
                            if (!available) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Complete your current course to unlock this adventure.',
                                  ),
                                ),
                              );
                            } else {
                              setState(() => _selectedCourse = index);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _JourneyMap(
                  course: selectedCourse,
                  courseAvailable: canOpenCourse,
                  completedGameIds: progress.completedGameIds,
                  gameStars: progress.gameStars,
                  recommendedGameId: progress.recommendedGameId,
                  recommendedDifficulty: progress.recommendedDifficulty,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyMap extends StatelessWidget {
  const _JourneyMap({
    required this.course,
    required this.courseAvailable,
    required this.completedGameIds,
    required this.gameStars,
    required this.recommendedGameId,
    required this.recommendedDifficulty,
  });

  final int course;
  final bool courseAvailable;
  final Set<String> completedGameIds;
  final Map<String, int> gameStars;
  final String? recommendedGameId;
  final GameDifficulty? recommendedDifficulty;

  @override
  Widget build(BuildContext context) {
    final courseTheme = CourseTheme.forCourse(course);
    final color = courseTheme.primary;
    final courseTitle =
        'Course $course · ${courseTheme.title} · ${courseTheme.region}';
    final games = allGames.where((game) => game.course == course).toList();
    final nextGame = games
        .where((game) => !completedGameIds.contains(game.id))
        .firstOrNull;
    final suggestedGameId = recommendedGameId ?? nextGame?.id;
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          excludeSemantics: true,
          child: Image.asset(
            courseTheme.backgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: courseTheme.surface),
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Semantics(
                      label: 'MathQuest journey map',
                      child: Image.asset(
                        AppAssets.journey,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: courseTheme.surface),
                      ),
                    ),
                    ColoredBox(color: Colors.white.withValues(alpha: 0.56)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.landscape_rounded,
                            size: 38,
                            color: AppColors.navy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              courseTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < games.length; index++) ...[
              Semantics(
                button: true,
                label: courseAvailable
                    ? '${games[index].title}, ${_gameStatus(games[index], suggestedGameId, gameStars, completedGameIds)}'
                    : '${games[index].title}, locked. Complete course requirements to unlock.',
                child: Card(
                  color: Colors.white.withValues(alpha: 0.94),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    minTileHeight: 64,
                    leading: CircleAvatar(
                      backgroundColor: courseAvailable
                          ? courseTheme.surface
                          : AppColors.lightGrey,
                      foregroundColor: AppColors.navy,
                      child: Icon(
                        !courseAvailable
                            ? Icons.lock_outline_rounded
                            : gameStars[games[index].id] == 3
                            ? Icons.star_rounded
                            : completedGameIds.contains(games[index].id)
                            ? Icons.check_rounded
                            : games[index].icon,
                      ),
                    ),
                    title: Text(
                      '${index + 1}. ${games[index].title}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      !courseAvailable
                          ? 'Locked'
                          : gameStars[games[index].id] == 3
                          ? 'Mastered · 3 stars'
                          : completedGameIds.contains(games[index].id)
                          ? 'Completed · ${gameStars[games[index].id] ?? 0} stars'
                          : games[index].id == suggestedGameId
                          ? 'Recommended next'
                          : 'Available',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (!courseAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Master the previous course to unlock this adventure.',
                            ),
                          ),
                        );
                        return;
                      }
                      _showGameQuickView(
                        context,
                        games[index],
                        gameStars[games[index].id] ?? 0,
                        initialDifficulty: games[index].id == recommendedGameId
                            ? recommendedDifficulty ?? GameDifficulty.medium
                            : GameDifficulty.medium,
                      );
                    },
                  ),
                ),
              ),
              if (index < games.length - 1)
                Center(
                  child: Container(
                    width: 4,
                    height: 25,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }

  String _gameStatus(
    GameEntry game,
    String? suggestedGameId,
    Map<String, int> stars,
    Set<String> completed,
  ) {
    if (stars[game.id] == 3) return 'mastered';
    if (completed.contains(game.id)) return 'completed';
    if (game.id == suggestedGameId) return 'recommended next';
    return 'available';
  }
}

class _ContinueQuestCard extends StatelessWidget {
  const _ContinueQuestCard({
    required this.game,
    required this.stars,
    required this.onTap,
  });

  final GameEntry game;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.primaryDark,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.explore_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue Your Quest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Your best: ${'★' * stars}${'☆' * (3 - stars)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            onPressed: onTap,
            child: const Text('Play'),
          ),
        ],
      ),
    ),
  );
}

void _showGameQuickView(
  BuildContext context,
  GameEntry game,
  int stars, {
  GameDifficulty initialDifficulty = GameDifficulty.medium,
}) {
  final pageContext = context;
  showModalBottomSheet<void>(
    context: pageContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(game.icon, size: 48, color: AppColors.primaryDark),
              const SizedBox(height: 8),
              Text(
                game.title,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (game.id == 'number-builder') ...[
                const Text(
                  'Sample: build the smallest number from 3, 6, 1',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 3),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 6),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'combo-forge') ...[
                const Text(
                  'Sample: target 15 · 3 × 5',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 3),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'math-snap') ...[
                const Text(
                  'Sample: 2 + 3 = target 5',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 2),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'math-array') ...[
                const Text(
                  'Sample: 3 rows · 4 dots in each row',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '3 × 4 = ?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'number-leap') ...[
                const Text(
                  'Sample: 5 → 8 → ? → 14 → 17',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'pizza-party') ...[
                const Text(
                  'Sample: 3 red slices · 5 equal slices',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'What fraction is red?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
              ] else if (game.id == 'grid-hunt') ...[
                const Text(
                  'Sample cards · target 9',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 2),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 3),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 80,
                      child: NumberCard(value: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                game.id == 'number-builder'
                    ? 'Arrange digit cards into the best place-value number.'
                    : game.id == 'combo-forge'
                    ? 'Build an expression that reaches the target.'
                    : game.id == 'math-snap'
                    ? 'Race Prof Penguin to reach the target using two cards.'
                    : game.id == 'grid-hunt'
                    ? 'Trace a path through touching number cards to reach the target.'
                    : game.id == 'math-array'
                    ? 'Read equal rows and build the matching multiplication fact.'
                    : game.id == 'number-leap'
                    ? 'Find the number pattern and fill each missing step.'
                    : game.id == 'pizza-party'
                    ? 'Explore fraction puzzles with colorful, equal pizza slices.'
                    : 'Practice ${_skillForGame(game)} through a quick maths challenge.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Skill: ${_skillForGame(game)}  ·  Your best: ${'★' * stars}${'☆' * (3 - stars)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showGameSetup(
                    pageContext,
                    game,
                    initialDifficulty: initialDifficulty,
                  );
                },
                child: const Text('Play'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showDialog<void>(
                    context: pageContext,
                    builder: (context) => AlertDialog(
                      title: Text('How to play ${game.title}'),
                      content: Text(
                        game.id == 'number-builder'
                            ? 'Place each digit into a slot to build the smallest or largest number. On Hard, get closest to the target. Leading zero is not allowed, and ties for closest answers are accepted.'
                            : game.id == 'combo-forge'
                            ? 'Build an expression from the available digit and operator cards. The result is hidden until you submit. Hard expressions must include multiplication; wrong submissions deduct game points, not coins.'
                            : game.id == 'math-snap'
                            ? 'Choose two number cards and use the operation for your difficulty to make the target. Press SNAP! to submit. A correct answer wins the round; wrong SNAP penalties apply on Medium and Hard. Online Player vs Player needs a server and is not available yet.'
                            : game.id == 'grid-hunt'
                            ? 'Select touching cards by dragging or tapping. Their sum must equal the target. A wrong claim does not advance the round.'
                            : game.id == 'math-array'
                            ? 'Count rows or groups first, then items in one row. Build rows × items = total using the digit pad. Each round has two tries; Hard may hide equal rows. Hints cost 3 coins. There is no timer.'
                            : game.id == 'number-leap'
                            ? 'Find one consistent skip-counting or multiplication pattern and enter each missing number with the digit pad. Hard can have two blanks. Each round has two tries; hints cost 3 coins. There is no timer.'
                            : game.id == 'pizza-party'
                            ? 'Easy names the red fraction, Medium adds two shares with the same denominator, and Hard finds an equivalent fraction. Each level has eight rounds, two tries per round, and one 3-coin hint per round. Solo is available now; online multiplayer needs a shared session backend.'
                            : 'Follow the instructions shown when this game is available.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('How to Play'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _skillForGame(GameEntry game) => switch (game.id) {
  'grid-hunt' => 'Addition',
  'math-snap' => 'Addition & multiplication',
  'number-builder' => 'Place value',
  'combo-forge' => 'Arithmetic & operations',
  'math-array' => 'Multiplication & equal groups',
  'number-leap' => 'Number patterns & skip counting',
  'pizza-party' => 'Fractions & equivalent fractions',
  'fraction-clash' || 'fair-share' => 'Fractions',
  'decimal-dash' => 'Decimals',
  'quick-grab' => 'Averages',
  _ => 'Number sense',
};

// TODO(multiplayer): Add online Pizza Party only after a shared session service
// can distribute identical challenges and resolve competing submissions.
void _showGameSetup(
  BuildContext context,
  GameEntry game, {
  required GameDifficulty initialDifficulty,
}) {
  final pageContext = context;
  var difficulty = initialDifficulty;
  var mode = game.id == 'math-snap' ? 'vs AI' : 'Solo';
  final soloOnlyGame = {
    'number-builder',
    'combo-forge',
    'math-array',
    'number-leap',
    'pizza-party',
  }.contains(game.id);
  showModalBottomSheet<void>(
    context: pageContext,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up ${game.title}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (!soloOnlyGame) ...[
                const SizedBox(height: 12),
                const Text('Choose a mode'),
                SegmentedButton<String>(
                  segments: game.id == 'math-snap'
                      ? const [
                          ButtonSegment(value: 'vs AI', label: Text('vs AI')),
                          ButtonSegment(
                            value: 'Online PvP',
                            label: Text('Online PvP'),
                            enabled: false,
                          ),
                        ]
                      : const [
                          ButtonSegment(value: 'Solo', label: Text('Solo')),
                          ButtonSegment(value: 'vs AI', label: Text('vs AI')),
                          ButtonSegment(value: 'Local', label: Text('Local')),
                        ],
                  selected: {mode},
                  onSelectionChanged: (selection) =>
                      setSheetState(() => mode = selection.first),
                  showSelectedIcon: false,
                ),
              ],
              if (game.id == 'math-snap') ...[
                const SizedBox(height: 6),
                Text(
                  'Online PvP will be available when server-based sessions are connected.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              const Text('Difficulty  ·  Recommended: Medium'),
              SegmentedButton<GameDifficulty>(
                segments: const [
                  ButtonSegment(
                    value: GameDifficulty.easy,
                    label: Text('Easy'),
                  ),
                  ButtonSegment(
                    value: GameDifficulty.medium,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(
                    value: GameDifficulty.hard,
                    label: Text('Hard'),
                  ),
                ],
                selected: {difficulty},
                onSelectionChanged: (selection) =>
                    setSheetState(() => difficulty = selection.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: game.id == 'grid-hunt'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GridHuntScreen(
                              initialDifficulty:
                                  GridHuntDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'math-snap'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MathSnapScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'number-builder'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NumberBuilderScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'combo-forge'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ComboForgeScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'math-array'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MathArrayScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'number-leap'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NumberLeapScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : game.id == 'pizza-party'
                    ? () {
                        Navigator.pop(context);
                        Navigator.of(pageContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PizzaPartyScreen(
                              initialDifficulty:
                                  GameDifficulty.values[difficulty.index],
                            ),
                          ),
                        );
                      }
                    : null,
                child: Text(game.available ? 'Start Game' : 'Coming soon'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog<void>(
                    context: pageContext,
                    builder: (context) => AlertDialog(
                      title: Text('How to play ${game.title}'),
                      content: Text(
                        game.id == 'number-builder'
                            ? 'Use digit cards 0–9 to build the optimal 2- or 3-digit number. Do not start with zero. Hard adds a closest-to-target challenge. There is no timer.'
                            : game.id == 'combo-forge'
                            ? 'Build a valid arithmetic expression from digit cards. The result stays hidden until submission. Hard requires multiplication. There is no timer.'
                            : game.id == 'math-snap'
                            ? 'Select two cards that make the target. Easy uses addition, Medium uses multiplication, and Hard lets you choose. Press SNAP! to submit. Wrong SNAP penalties are 0, 1, and 2 coins for Easy, Medium, and Hard.'
                            : game.id == 'grid-hunt'
                            ? 'Select touching cards by dragging or tapping. Their sum must equal the target. A wrong claim does not advance the round.'
                            : game.id == 'math-array'
                            ? 'Count equal rows or groups first, then items in one row. Enter the ordered equation with the digit pad. You have two tries per round; hints cost 3 coins. There is no timer.'
                            : game.id == 'number-leap'
                            ? 'Find a consistent skip-counting or multiplication pattern. Enter each missing number using the digit pad. You have two tries per round; hints cost 3 coins. There is no timer.'
                            : game.id == 'pizza-party'
                            ? 'Solve eight fraction puzzles using the number-card keypad. Easy names fractions, Medium adds matching denominators, and Hard finds equivalent fractions. Hints cost 3 coins. Online multiplayer is planned after a shared session backend is available.'
                            : 'Follow the instructions shown when this game is available.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('How to Play'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.monetization_on_rounded,
          size: 18,
          color: AppColors.navy,
        ),
        const SizedBox(width: 5),
        Text('$coins', style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class RankTab extends StatefulWidget {
  const RankTab({super.key});

  @override
  State<RankTab> createState() => _RankTabState();
}

class _RankTabState extends State<RankTab> {
  String _period = 'This Week';

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Rank',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final period in ['This Week', 'Monthly', 'All Time'])
            ChoiceChip(
              label: Text(period),
              selected: period == _period,
              onSelected: (_) => setState(() => _period = period),
            ),
        ],
      ),
      const SizedBox(height: 16),
      // TODO(backend/leaderboard): Fetch ranked players for the selected period.
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Your adventure is your own',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Leaderboard rankings will appear when online play is connected.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    final index = state.currentProfile;
    final profile = index == null ? null : state.profiles[index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Player profile',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to quest'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            minTileHeight: 86,
            leading: AnimalAvatar(name: profile?.avatar ?? '', size: 56),
            title: Text(
              profile?.name ?? 'Adventurer',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              profile == null
                  ? 'Add a profile to start'
                  : 'Grade ${profile.grade} · Course ${profile.startingCourse}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              icon: Icons.circle,
              label: 'Coins',
              value: '${state.coins}',
              color: AppColors.gold,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '${state.streak} days',
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.bolt_rounded,
              label: 'Level ${state.xp ~/ 100 + 1}',
              value: '${state.xp} XP',
              color: AppColors.skyBlue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journey progress',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (state.completedGameIds.length / allGames.length)
                      .clamp(0.0, 1.0),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.completedGameIds.length} of ${allGames.length} games completed',
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.warning,
            ),
            title: const Text('Achievements'),
            subtitle: const Text('View badges and achievements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/achievements'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.workspace_premium_outlined),
            title: Text('Certificates'),
            subtitle: Text('Course certificates will appear here.'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.star_rounded, color: AppColors.gold),
            title: Text('Game stars'),
            subtitle: Text('Keep playing to collect stars!'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _effects = true;
  bool _music = true;
  bool _draggableCards = true;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Settings',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      SwitchListTile(
        title: const Text('Sound effects'),
        value: _effects,
        onChanged: (value) => setState(() => _effects = value),
      ),
      SwitchListTile(
        title: const Text('Background music'),
        value: _music,
        onChanged: (value) => setState(() => _music = value),
      ),
      SwitchListTile(
        title: const Text('Draggable cards'),
        value: _draggableCards,
        onChanged: (value) => setState(() => _draggableCards = value),
      ),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('How to play'),
        onTap: () => _showInfo(
          context,
          'How to play',
          'Choose a game node on the journey map and follow the on-screen challenge.',
        ),
      ),
      ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('Contact us'),
        onTap: () => _showInfo(
          context,
          'Contact us',
          'Sommer Learning contact support will be connected in a future release.',
        ),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Privacy policy'),
        onTap: () => _showInfo(
          context,
          'Privacy policy',
          'Privacy information will be provided before account services launch.',
        ),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Parent area'),
        subtitle: const Text('Solve a quick maths question to continue'),
        onTap: () => _showParentGate(context),
      ),
      // TODO(backend/subscriptions): Add parent-managed subscription controls.
    ],
  );
}

void _showInfo(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showParentGate(BuildContext context) {
  final answer = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Parent check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('What is 8 + 7?'),
          const SizedBox(height: 10),
          TextField(
            controller: answer,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Answer',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final valid = answer.text.trim() == '15';
            Navigator.pop(dialogContext);
            if (valid) {
              _showInfo(
                context,
                'Parent area',
                'Parent controls and subscription options will be connected in a future release.',
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'That answer is not quite right. Please try again.',
                  ),
                ),
              );
            }
          },
          child: const Text('Continue'),
        ),
      ],
    ),
  ).whenComplete(answer.dispose);
}
