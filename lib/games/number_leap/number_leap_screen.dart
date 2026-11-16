import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import 'number_leap_logic.dart';

class NumberLeapScreen extends ConsumerStatefulWidget {
  const NumberLeapScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<NumberLeapScreen> createState() => _NumberLeapScreenState();
}

class _NumberLeapScreenState extends ConsumerState<NumberLeapScreen> {
  static const _difficultyKeyPrefix = 'number-leap.difficulty.profile.';
  static const _hintCost = 3;
  final _random = Random();
  final Set<String> _usedPuzzles = {};
  late NumberLeapDifficulty _difficulty;
  late NumberLeapPuzzle _puzzle;
  late List<String> _answers;
  int _round = 1;
  int _roundsWon = 0;
  int _firstTryWins = 0;
  int _attempts = 0;
  int _activeAnswer = 0;
  bool _hintUsed = false;
  bool _resolved = false;
  bool _revealed = false;
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
      _showTutorialIfNeeded();
    });
  }

  NumberLeapDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in NumberLeapDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return NumberLeapDifficulty.values[widget.initialDifficulty.index];
  }

  void _dealPuzzle() {
    _puzzle = createNumberLeapPuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
      excludedPuzzles: _usedPuzzles,
    );
    _usedPuzzles.add(_puzzle.signature);
    _answers = List<String>.filled(_puzzle.missingIndexes.length, '');
    _activeAnswer = 0;
    _attempts = 0;
    _hintUsed = false;
    _resolved = false;
    _revealed = false;
  }

  Future<void> _showTutorialIfNeeded() async {
    if (ProgressController.preferences.getBool('tutorial.number-leap') ==
        true) {
      return;
    }
    await ProgressController.preferences.setBool('tutorial.number-leap', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Number Leap'),
        content: const Text(
          'Find the same jump between each number. Select each blank and '
          'build its answer with the digit pad. You have two tries per round. '
          'Hard can have two missing numbers. There is no timer.',
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
  }

  Future<void> _changeDifficulty(NumberLeapDifficulty difficulty) async {
    if (_difficulty == difficulty || _gameFinished) return;
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _roundsWon = 0;
      _firstTryWins = 0;
      _usedPuzzles.clear();
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  void _selectAnswer(int index) {
    if (_resolved) return;
    setState(() {
      if (_answers[index].isNotEmpty) _answers[index] = '';
      _activeAnswer = index;
    });
  }

  void _enterDigit(int digit) {
    if (_resolved || _answers[_activeAnswer].length >= 2) return;
    final current = _answers[_activeAnswer];
    if (current.isEmpty && digit == 0) return;
    setState(() {
      _answers[_activeAnswer] = '$current$digit';
      if (_answers[_activeAnswer].length == 2) {
        final nextEmpty = _answers.indexWhere((answer) => answer.isEmpty);
        if (nextEmpty >= 0) _activeAnswer = nextEmpty;
      }
    });
  }

  void _deleteDigit() {
    if (_resolved || _answers[_activeAnswer].isEmpty) return;
    setState(() {
      _answers[_activeAnswer] = _answers[_activeAnswer].substring(
        0,
        _answers[_activeAnswer].length - 1,
      );
    });
  }

  Future<void> _checkAnswer() async {
    if (_resolved) return;
    if (_answers.any((answer) => answer.isEmpty)) {
      _toast('Fill every missing number first.');
      return;
    }
    _attempts++;
    final values = _answers.map(int.parse).toList();
    if (isCorrectNumberLeapAnswer(puzzle: _puzzle, answers: values)) {
      final stars = _attempts == 1 ? 3 : 1;
      setState(() {
        _resolved = true;
        _roundsWon++;
        if (_attempts == 1) _firstTryWins++;
      });
      await ref
          .read(progressProvider.notifier)
          .awardRoundReward(xp: 8, coins: 12);
      if (mounted) {
        _toast(
          '${_attempts == 1 ? 'Great leap!' : 'You got it!'} '
          '${values.join(', ')} · ${'★' * stars}',
        );
      }
      return;
    }
    if (_attempts == 1) {
      _toast('Almost! Look at the jump again.');
    } else {
      setState(() {
        _revealed = true;
        _resolved = true;
      });
    }
  }

  Future<void> _showHint() async {
    if (_hintUsed || _resolved) return;
    if (ref.read(progressProvider).coins < _hintCost) {
      _toast('You need 3 coins for a hint.');
      return;
    }
    await ref.read(progressProvider.notifier).spendCoins(_hintCost);
    if (!mounted) return;
    setState(() => _hintUsed = true);
    final hint = switch (_difficulty) {
      NumberLeapDifficulty.easy => 'Look at how much the numbers go up.',
      NumberLeapDifficulty.medium => 'Compare the first two visible numbers.',
      NumberLeapDifficulty.hard =>
        _puzzle.pattern.operation == NumberLeapOperation.multiply
            ? 'Each number is multiplied by the same number.'
            : 'Check the jump from one number to the next.',
    };
    _toast(hint);
  }

  Future<void> _nextRound() async {
    if (_round == _difficulty.rounds) {
      await _finishGame();
      return;
    }
    setState(() {
      _round++;
      _dealPuzzle();
    });
  }

  Future<void> _finishGame() async {
    if (_gameFinished) return;
    _gameFinished = true;
    final accuracy = _roundsWon / _difficulty.rounds;
    final stars = accuracy >= 0.85
        ? 3
        : accuracy >= 0.55
        ? 2
        : 1;
    await ref
        .read(progressProvider.notifier)
        .recordGameReward(gameId: 'number-leap', xp: 0, coins: 0, stars: stars);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leap complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'★' * stars}${'☆' * (3 - stars)}',
              style: const TextStyle(fontSize: 32, color: AppColors.gold),
            ),
            Text('Correct rounds: $_roundsWon of ${_difficulty.rounds}'),
            Text('First try: $_firstTryWins · +${_roundsWon * 8} XP'),
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
      _roundsWon = 0;
      _firstTryWins = 0;
      _usedPuzzles.clear();
      _gameFinished = false;
      _dealPuzzle();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to journey',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Number Leap'),
      actions: [
        IconButton(
          tooltip: 'How to play',
          onPressed: _showTutorial,
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              _RoundPill(round: _round, total: _difficulty.rounds),
              const SizedBox(width: 10),
              Expanded(
                child: SegmentedButton<NumberLeapDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: NumberLeapDifficulty.easy,
                      label: Text('Easy'),
                    ),
                    ButtonSegment(
                      value: NumberLeapDifficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: NumberLeapDifficulty.hard,
                      label: Text('Hard'),
                    ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) =>
                      _changeDifficulty(selection.first),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Column(
              children: [
                const Text(
                  'Find the jump. Follow the pattern. Fill the blank.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (
                        var index = 0;
                        index < _puzzle.sequence.length;
                        index++
                      ) ...[
                        if (index > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        if (_puzzle.missingIndexes.contains(index))
                          _MissingNumberSlot(
                            answerIndex: _puzzle.missingIndexes.indexOf(index),
                            value:
                                _answers[_puzzle.missingIndexes.indexOf(index)],
                            active:
                                _activeAnswer ==
                                _puzzle.missingIndexes.indexOf(index),
                            onTap: () => _selectAnswer(
                              _puzzle.missingIndexes.indexOf(index),
                            ),
                          )
                        else
                          _NumberTile(
                            value: _puzzle.sequence[index],
                            index: index,
                          ),
                      ],
                    ],
                  ),
                ),
                if (_revealed) ...[
                  const SizedBox(height: 16),
                  Text(
                    'The pattern is ${_puzzle.pattern.label}: '
                    '${_puzzle.sequence.join(' → ')}',
                    key: const Key('number-leap-reveal'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _DigitPad(
                  onDigit: _enterDigit,
                  onDelete: _deleteDigit,
                  enabled: !_resolved,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hintUsed || _resolved ? null : _showHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: Text(
                          _hintUsed
                              ? 'Hint used'
                              : 'Hint · ${ref.watch(progressProvider).coins} coins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _resolved
                            ? _nextRound
                            : _answers.any((answer) => answer.isEmpty)
                            ? null
                            : _checkAnswer,
                        child: Text(
                          _resolved
                              ? _round == _difficulty.rounds
                                    ? 'Finish Level'
                                    : 'Next Round'
                              : 'CHECK',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('NO TIMER · Two tries per round'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoundPill extends StatelessWidget {
  const _RoundPill({required this.round, required this.total});

  final int round;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      'Round $round of $total',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
    ),
  );
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, required this.index});

  final int value;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('number-leap-number-$index'),
    width: 48,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.courseOne, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1410233F),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      '$value',
      style: const TextStyle(
        fontSize: 22,
        color: AppColors.navy,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MissingNumberSlot extends StatelessWidget {
  const _MissingNumberSlot({
    required this.answerIndex,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final int answerIndex;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: value.isEmpty
        ? 'Missing number ${answerIndex + 1}, empty'
        : 'Missing number ${answerIndex + 1}, $value; tap to clear',
    child: InkWell(
      key: ValueKey('number-leap-answer-$answerIndex'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value.isEmpty
              ? const Color(0xFFFFF4C8)
              : const Color(0xFFDDF7E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.actionGreen : AppColors.gold,
            width: active ? 3 : 2,
          ),
        ),
        child: Text(
          value.isEmpty ? '?' : value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}

class _DigitPad extends StatelessWidget {
  const _DigitPad({
    required this.onDigit,
    required this.onDelete,
    required this.enabled,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var digit = 1; digit <= 9; digit++)
        _DigitButton(
          digit: '$digit',
          key: ValueKey('number-leap-digit-$digit'),
          onTap: enabled ? () => onDigit(digit) : null,
        ),
      _DigitButton(
        digit: '0',
        key: const ValueKey('number-leap-digit-0'),
        onTap: enabled ? () => onDigit(0) : null,
      ),
      SizedBox(
        width: 52,
        height: 52,
        child: OutlinedButton(
          onPressed: enabled ? onDelete : null,
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          child: const Icon(Icons.backspace_outlined),
        ),
      ),
    ],
  );
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({required this.digit, required this.onTap, super.key});

  final String digit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      child: Text(digit),
    ),
  );
}
