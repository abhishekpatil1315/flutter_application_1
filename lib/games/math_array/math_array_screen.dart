import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import 'math_array_logic.dart';

class MathArrayScreen extends ConsumerStatefulWidget {
  const MathArrayScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<MathArrayScreen> createState() => _MathArrayScreenState();
}

class _MathArrayScreenState extends ConsumerState<MathArrayScreen> {
  static const _difficultyKeyPrefix = 'math-array.difficulty.profile.';
  static const _hintCost = 3;
  final _random = Random();
  final Set<String> _usedFacts = {};
  late MathArrayDifficulty _difficulty;
  late MathArrayPuzzle _puzzle;
  late List<int?> _answers;
  int _round = 1;
  int _roundsWon = 0;
  int _firstTryWins = 0;
  int _attempts = 0;
  int _activeSlot = 0;
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

  MathArrayDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in MathArrayDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return MathArrayDifficulty.values[widget.initialDifficulty.index];
  }

  void _dealPuzzle() {
    _puzzle = createMathArrayPuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
      excludedFacts: _usedFacts,
    );
    _usedFacts.add(_puzzle.signature);
    _answers = List<int?>.filled(2 + _puzzle.total.toString().length, null);
    _activeSlot = 0;
    _attempts = 0;
    _hintUsed = false;
    _resolved = false;
    _revealed = false;
  }

  Future<void> _showTutorialIfNeeded() async {
    if (ProgressController.preferences.getBool('tutorial.math-array') == true) {
      return;
    }
    await ProgressController.preferences.setBool('tutorial.math-array', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Math Array'),
        content: const Text(
          'Count the rows or groups first, then count the items in one row. '
          'Build rows × items = total using the digit pad. Each round gives '
          'you two tries. Hard may hide some equal rows. There is no timer.',
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

  Future<void> _changeDifficulty(MathArrayDifficulty difficulty) async {
    if (_difficulty == difficulty || _gameFinished) return;
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _roundsWon = 0;
      _firstTryWins = 0;
      _usedFacts.clear();
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  void _enterDigit(int digit) {
    if (_resolved) return;
    final slot = _activeSlot;
    if (_answers[slot] != null) return;
    setState(() {
      _answers[slot] = digit;
      final nextEmpty = _answers.indexWhere((answer) => answer == null);
      if (nextEmpty >= 0) _activeSlot = nextEmpty;
    });
  }

  void _selectSlot(int slot) {
    if (_resolved) return;
    setState(() {
      if (_answers[slot] != null) _answers[slot] = null;
      _activeSlot = slot;
    });
  }

  Future<void> _checkAnswer() async {
    if (_resolved) return;
    if (_answers.any((answer) => answer == null)) {
      _toast('Fill every answer slot first.');
      return;
    }
    _attempts++;
    final first = _answers[0]!;
    final second = _answers[1]!;
    final totalDigits = _answers.skip(2).cast<int>().toList();
    if (isCorrectMathArrayAnswer(
      puzzle: _puzzle,
      firstFactor: first,
      secondFactor: second,
      totalDigits: totalDigits,
    )) {
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
          '${_attempts == 1 ? 'Great job!' : 'You got it!'} '
          '$first × $second = ${_puzzle.total} · ${'★' * stars}',
        );
      }
      return;
    }

    final reversed =
        first == _puzzle.secondFactor &&
        second == _puzzle.firstFactor &&
        first != second;
    if (_attempts == 1) {
      _toast(
        reversed
            ? 'Same total! Groups come first.'
            : 'Almost! Look at the groups again.',
      );
    } else {
      setState(() {
        _revealed = true;
        _resolved = true;
      });
    }
  }

  Future<void> _showHint() async {
    if (_hintUsed || _resolved) return;
    final progress = ref.read(progressProvider);
    if (progress.coins < _hintCost) {
      _toast('You need 3 coins for a hint.');
      return;
    }
    await ref.read(progressProvider.notifier).spendCoins(_hintCost);
    if (!mounted) return;
    setState(() => _hintUsed = true);
    final hint = switch (_difficulty) {
      MathArrayDifficulty.easy => 'Count the rows first.',
      MathArrayDifficulty.medium => 'Count the groups, then one group.',
      MathArrayDifficulty.hard =>
        'Each hidden row has the same number of items as a visible row.',
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
        .recordGameReward(gameId: 'math-array', xp: 0, coins: 0, stars: stars);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Array complete!'),
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
      _usedFacts.clear();
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
      title: const Text('Math Array'),
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
                child: SegmentedButton<MathArrayDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: MathArrayDifficulty.easy,
                      label: Text('Easy'),
                    ),
                    ButtonSegment(
                      value: MathArrayDifficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: MathArrayDifficulty.hard,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Column(
              children: [
                Text(
                  _difficulty == MathArrayDifficulty.easy
                      ? 'Count the rows. Then count items in one row.'
                      : _difficulty == MathArrayDifficulty.medium
                      ? 'How many equal groups? How many in each group?'
                      : 'Use the visible equal rows to reason about the whole array.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _ArrayVisual(
                  puzzle: _puzzle,
                  hardMode: _difficulty == MathArrayDifficulty.hard,
                ),
                const SizedBox(height: 16),
                _EquationBuilder(
                  answers: _answers,
                  activeSlot: _activeSlot,
                  onSelect: _selectSlot,
                ),
                const SizedBox(height: 14),
                _DigitPad(onDigit: _enterDigit, enabled: !_resolved),
                const SizedBox(height: 8),
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
                            : _answers.any((answer) => answer == null)
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
                if (_revealed) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_puzzle.firstFactor} groups of ${_puzzle.secondFactor} '
                    'make ${_puzzle.total}.',
                    key: const Key('math-array-reveal'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
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

class _ArrayVisual extends StatelessWidget {
  const _ArrayVisual({required this.puzzle, required this.hardMode});

  final MathArrayPuzzle puzzle;
  final bool hardMode;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.courseOne.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.courseOne, width: 2),
    ),
    child: Column(
      children: [
        Text(
          '${puzzle.firstFactor} ${hardMode ? 'rows' : 'equal groups'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < puzzle.firstFactor; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: row >= puzzle.firstFactor - puzzle.hiddenRows
                  ? const Center(
                      child: Text(
                        'Hidden row · same number inside',
                        style: TextStyle(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var item = 0; item < puzzle.secondFactor; item++)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.circle,
                              size: 18,
                              color: AppColors.skyBlue,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
      ],
    ),
  );
}

class _EquationBuilder extends StatelessWidget {
  const _EquationBuilder({
    required this.answers,
    required this.activeSlot,
    required this.onSelect,
  });

  final List<int?> answers;
  final int activeSlot;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 5,
    children: [
      _AnswerSlot(
        slot: 0,
        value: answers[0],
        active: activeSlot == 0,
        onTap: () => onSelect(0),
      ),
      const Text(
        '×',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      ),
      _AnswerSlot(
        slot: 1,
        value: answers[1],
        active: activeSlot == 1,
        onTap: () => onSelect(1),
      ),
      const Text(
        '=',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      ),
      for (var index = 2; index < answers.length; index++)
        _AnswerSlot(
          slot: index,
          value: answers[index],
          active: activeSlot == index,
          onTap: () => onSelect(index),
        ),
    ],
  );
}

class _AnswerSlot extends StatelessWidget {
  const _AnswerSlot({
    required this.slot,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final int slot;
  final int? value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: value == null ? 'Empty answer digit' : 'Answer digit $value, clear',
    child: InkWell(
      key: ValueKey('math-array-slot-$slot'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value == null ? Colors.white : const Color(0xFFDDF7E6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.actionGreen : AppColors.darkGrey,
            width: active ? 3 : 1.5,
          ),
        ),
        child: Text(
          value?.toString() ?? '·',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}

class _DigitPad extends StatelessWidget {
  const _DigitPad({required this.onDigit, required this.enabled});

  final ValueChanged<int> onDigit;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var digit = 1; digit <= 9; digit++)
        _DigitButton(
          digit: digit,
          key: ValueKey('math-array-digit-$digit'),
          onTap: enabled ? () => onDigit(digit) : null,
        ),
      _DigitButton(
        digit: 0,
        key: const ValueKey('math-array-digit-0'),
        onTap: enabled ? () => onDigit(0) : null,
      ),
    ],
  );
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({required this.digit, required this.onTap, super.key});

  final int digit;
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
      child: Text('$digit'),
    ),
  );
}
