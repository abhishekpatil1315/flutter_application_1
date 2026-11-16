import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/number_card.dart';
import 'math_snap_logic.dart';

class MathSnapScreen extends ConsumerStatefulWidget {
  const MathSnapScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<MathSnapScreen> createState() => _MathSnapScreenState();
}

class _MathSnapScreenState extends ConsumerState<MathSnapScreen> {
  static const _difficultyKeyPrefix = 'math-snap.difficulty.profile.';
  static const _coinsPerWin = 12;
  static const _roundsPerGame = 5;

  final _random = Random();
  final List<int> _selectedCards = [];
  Timer? _aiTimer;
  late MathSnapDifficulty _difficulty;
  late MathSnapPuzzle _puzzle;
  MathSnapOperation _operation = MathSnapOperation.addition;
  MathSnapSolution? _aiGuess;
  MathSnapSolution? _revealedSolution;
  String? _feedback;
  int _round = 1;
  int _playerWins = 0;
  int _profPenguinWins = 0;
  int _coinsEarned = 0;
  bool _roundResolved = false;
  bool _paused = false;
  bool _tutorialVisible = false;
  bool _gameFinished = false;

  String get _difficultyKey {
    final profile = ref.read(progressProvider).currentProfile;
    return '$_difficultyKeyPrefix${profile ?? 'guest'}';
  }

  @override
  void initState() {
    super.initState();
    _difficulty = _loadDifficulty();
    _dealPuzzle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTutorialIfNeeded());
    });
  }

  MathSnapDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in MathSnapDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return MathSnapDifficulty.values[widget.initialDifficulty.index];
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  void _dealPuzzle() {
    _puzzle = createMathSnapPuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
    );
    _selectedCards.clear();
    _aiGuess = null;
    _revealedSolution = null;
    _roundResolved = false;
    _feedback = null;
    _operation = _difficulty == MathSnapDifficulty.medium
        ? MathSnapOperation.multiplication
        : MathSnapOperation.addition;
  }

  Future<void> _showTutorialIfNeeded() async {
    final preferences = ProgressController.preferences;
    if (preferences.getBool('tutorial.math-snap') == true) {
      _scheduleAiAttempt();
      return;
    }
    await preferences.setBool('tutorial.math-snap', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Math Snap'),
        content: const Text(
          'Use two number cards to make the target. Easy uses addition, '
          'Medium uses multiplication, and Hard lets you choose either. '
          'Tap SNAP! when you have an answer. A wrong SNAP costs no coins '
          'on Easy, 1 coin on Medium, and 2 coins on Hard. First correct '
          'answer wins the round.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    _tutorialVisible = false;
    if (mounted) _scheduleAiAttempt();
  }

  Future<void> _changeDifficulty(MathSnapDifficulty difficulty) async {
    if (difficulty == _difficulty || _gameFinished) return;
    _aiTimer?.cancel();
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _playerWins = 0;
      _profPenguinWins = 0;
      _coinsEarned = 0;
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
    if (mounted && !_paused) _scheduleAiAttempt();
  }

  void _selectCard(int index) {
    if (_roundResolved || _paused) return;
    setState(() {
      if (_selectedCards.contains(index)) {
        _selectedCards.remove(index);
      } else if (_selectedCards.length < 2) {
        _selectedCards.add(index);
      } else {
        _selectedCards
          ..clear()
          ..add(index);
      }
    });
  }

  Future<void> _snap() async {
    if (_roundResolved || _paused) return;
    if (_selectedCards.length != 2) {
      setState(() => _feedback = 'Choose two number cards first.');
      return;
    }
    final correct = isCorrectMathSnapAnswer(
      cards: _puzzle.cards,
      selectedCards: _selectedCards,
      target: _puzzle.target,
      difficulty: _difficulty,
      operation: _operation,
    );
    if (correct) {
      _aiTimer?.cancel();
      final solution = MathSnapSolution(
        firstCard: _selectedCards[0],
        secondCard: _selectedCards[1],
        operation: _operation,
      );
      setState(() {
        _roundResolved = true;
        _playerWins++;
        _coinsEarned += _coinsPerWin;
        _revealedSolution = solution;
        _feedback = 'SNAP! You got it first!';
      });
      await ref.read(progressProvider.notifier).awardCoins(_coinsPerWin);
      return;
    }

    final penalty = mathSnapAiProfile(_difficulty).wrongSnapPenalty;
    final availableCoins = ref.read(progressProvider).coins;
    final coinsToLose = min(penalty, availableCoins);
    setState(() {
      _selectedCards.clear();
      _feedback = coinsToLose == 0
          ? 'Not quite. Keep trying!'
          : 'Not quite. You lost $coinsToLose coin${coinsToLose == 1 ? '' : 's'}. Try again!';
    });
    if (coinsToLose > 0) {
      await ref.read(progressProvider.notifier).spendCoins(coinsToLose);
    }
  }

  void _scheduleAiAttempt() {
    if (!mounted || _paused || _roundResolved || _tutorialVisible) return;
    final profile = mathSnapAiProfile(_difficulty);
    final minMilliseconds = profile.minReaction.inMilliseconds;
    final maxMilliseconds = profile.maxReaction.inMilliseconds;
    final delay =
        minMilliseconds +
        _random.nextInt(maxMilliseconds - minMilliseconds + 1);
    _aiTimer?.cancel();
    _aiTimer = Timer(Duration(milliseconds: delay), _makeAiAttempt);
  }

  void _makeAiAttempt() {
    if (!mounted || _paused || _roundResolved) return;
    final solutions = findMathSnapSolutions(
      cards: _puzzle.cards,
      target: _puzzle.target,
      difficulty: _difficulty,
    );
    if (solutions.isEmpty) {
      throw StateError('Generated Math Snap puzzle has no valid answer.');
    }
    final profile = mathSnapAiProfile(_difficulty);
    final accuracy =
        profile.minAccuracy +
        _random.nextDouble() * (profile.maxAccuracy - profile.minAccuracy);
    if (_random.nextDouble() < accuracy) {
      final solution = solutions[_random.nextInt(solutions.length)];
      setState(() {
        _roundResolved = true;
        _profPenguinWins++;
        _revealedSolution = solution;
        _feedback = 'Prof Penguin snapped first this round!';
      });
      return;
    }

    final wrongGuesses = <MathSnapSolution>[];
    for (var first = 0; first < _puzzle.cards.length; first++) {
      for (var second = first + 1; second < _puzzle.cards.length; second++) {
        for (final operation in mathSnapOperations(_difficulty)) {
          if (!isCorrectMathSnapAnswer(
            cards: _puzzle.cards,
            selectedCards: [first, second],
            target: _puzzle.target,
            difficulty: _difficulty,
            operation: operation,
          )) {
            wrongGuesses.add(
              MathSnapSolution(
                firstCard: first,
                secondCard: second,
                operation: operation,
              ),
            );
          }
        }
      }
    }
    final guess = wrongGuesses[_random.nextInt(wrongGuesses.length)];
    setState(() {
      _aiGuess = guess;
      _feedback = 'Prof Penguin snapped too soon! You can still win.';
    });
    _aiTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _roundResolved) return;
      setState(() {
        _aiGuess = null;
        _feedback = null;
      });
      _scheduleAiAttempt();
    });
  }

  void _pauseGame() {
    if (_roundResolved || _paused) return;
    _aiTimer?.cancel();
    setState(() => _paused = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Game paused'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _paused = false);
              unawaited(_showTutorial());
            },
            child: const Text('How to Play'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _paused = false);
              _scheduleAiAttempt();
            },
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Exit to Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _nextRound() async {
    if (_round >= _roundsPerGame) {
      await _finishGame();
      return;
    }
    setState(() {
      _round++;
      _dealPuzzle();
    });
    _scheduleAiAttempt();
  }

  Future<void> _finishGame() async {
    if (_gameFinished) return;
    _gameFinished = true;
    final stars = _playerWins >= 5
        ? 3
        : _playerWins >= 3
        ? 2
        : _playerWins > 0
        ? 1
        : 0;
    await ref
        .read(progressProvider.notifier)
        .recordGameReward(gameId: 'math-snap', xp: 0, coins: 0, stars: stars);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _playerWins > _profPenguinWins ? 'Great Snap!' : 'Game Over',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'★' * stars}${'☆' * (3 - stars)}',
              style: const TextStyle(fontSize: 32, color: AppColors.gold),
            ),
            const SizedBox(height: 8),
            Text('You: $_playerWins  ·  Prof Penguin: $_profPenguinWins'),
            Text('Coins earned: +$_coinsEarned'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Back to Journey'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _restartGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _round = 1;
      _playerWins = 0;
      _profPenguinWins = 0;
      _coinsEarned = 0;
      _gameFinished = false;
      _dealPuzzle();
    });
    _scheduleAiAttempt();
  }

  String _solutionText(MathSnapSolution solution) {
    final first = _puzzle.cards[solution.firstCard];
    final second = _puzzle.cards[solution.secondCard];
    final symbol = solution.operation == MathSnapOperation.addition ? '+' : '×';
    return '$first $symbol $second = ${_puzzle.target}';
  }

  @override
  Widget build(BuildContext context) {
    final availableOperations = mathSnapOperations(_difficulty);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to journey',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Math Snap',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'How to play',
            onPressed: _showTutorial,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: 'Pause game',
            onPressed: _pauseGame,
            icon: const Icon(Icons.pause_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$_round/$_roundsPerGame',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<MathSnapDifficulty>(
                    segments: const [
                      ButtonSegment(
                        value: MathSnapDifficulty.easy,
                        label: Text('Easy'),
                      ),
                      ButtonSegment(
                        value: MathSnapDifficulty.medium,
                        label: Text('Medium'),
                      ),
                      ButtonSegment(
                        value: MathSnapDifficulty.hard,
                        label: Text('Hard'),
                      ),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (selection) =>
                        unawaited(_changeDifficulty(selection.first)),
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _scoreCard('PROF PENGUIN', _profPenguinWins),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _scoreCard('YOU', _playerWins, player: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.skyBlue, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${_puzzle.target}',
                          key: const Key('math-snap-target'),
                          style: const TextStyle(
                            fontSize: 44,
                            height: 1.05,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, _) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _puzzle.cards.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.76,
                            ),
                        itemBuilder: (context, index) {
                          final selected = _selectedCards.contains(index);
                          final aiSelected =
                              _aiGuess?.firstCard == index ||
                              _aiGuess?.secondCard == index;
                          return Semantics(
                            label:
                                'Number card ${_puzzle.cards[index]}${selected ? ', selected' : ''}',
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: aiSelected
                                    ? Border.all(
                                        color: AppColors.skyBlue,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: NumberCard(
                                value: _puzzle.cards[index],
                                selected: selected,
                                onTap: _roundResolved || _paused
                                    ? null
                                    : () => _selectCard(index),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  if (availableOperations.length == 1)
                    _operationPill(availableOperations.single)
                  else
                    SegmentedButton<MathSnapOperation>(
                      segments: const [
                        ButtonSegment(
                          value: MathSnapOperation.addition,
                          label: Text('Add  +'),
                        ),
                        ButtonSegment(
                          value: MathSnapOperation.multiplication,
                          label: Text('Multiply  ×'),
                        ),
                      ],
                      selected: {_operation},
                      onSelectionChanged: _roundResolved || _paused
                          ? null
                          : (selection) =>
                                setState(() => _operation = selection.first),
                      showSelectedIcon: false,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedCards.isEmpty
                        ? 'Choose two cards, then press SNAP!'
                        : _selectedCards.length == 1
                        ? 'Choose one more card'
                        : 'Your answer: ${_puzzle.cards[_selectedCards[0]]} '
                              '${_operation == MathSnapOperation.addition ? '+' : '×'} '
                              '${_puzzle.cards[_selectedCards[1]]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _feedback!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _roundResolved
                            ? AppColors.primaryDark
                            : AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (_roundResolved && _revealedSolution != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'One correct answer: ${_solutionText(_revealedSolution!)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_roundResolved)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => unawaited(_nextRound()),
                        child: Text(
                          _round == _roundsPerGame
                              ? 'See Results'
                              : 'Next Round',
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectedCards.isEmpty || _paused
                                ? null
                                : () => setState(_selectedCards.clear),
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _paused
                                  ? null
                                  : () => unawaited(_snap()),
                              child: const Text(
                                'SNAP!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Wrong SNAP penalty: ${mathSnapAiProfile(_difficulty).wrongSnapPenalty} coins',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _operationPill(MathSnapOperation operation) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      operation == MathSnapOperation.addition
          ? 'Addition only  ·  +'
          : 'Multiplication only  ·  ×',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );

  Widget _scoreCard(String label, int score, {bool player = false}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: player ? AppColors.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryDark),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: player ? Colors.white : AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: player ? Colors.white : AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
