import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/number_card.dart';
import 'pizza_party_logic.dart';

enum _AnswerField { numerator, denominator }

class PizzaPartyScreen extends ConsumerStatefulWidget {
  const PizzaPartyScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<PizzaPartyScreen> createState() => _PizzaPartyScreenState();
}

class _PizzaPartyScreenState extends ConsumerState<PizzaPartyScreen> {
  static const _difficultyKeyPrefix = 'pizza-party.difficulty.profile.';
  static const _hintCost = 3;
  final _random = Random();
  final Set<String> _usedFractions = {};
  late PizzaPartyDifficulty _difficulty;
  late PizzaPartyPuzzle _puzzle;
  String _numeratorInput = '';
  String _denominatorInput = '';
  _AnswerField _activeField = _AnswerField.numerator;
  int _round = 1;
  int _starsEarned = 0;
  int _firstTryCorrect = 0;
  int _attempts = 0;
  bool _hintUsed = false;
  bool _roundResolved = false;
  bool _answerRevealed = false;
  bool _hardPizzaRevealed = false;
  bool _tutorialVisible = false;
  bool _gameFinished = false;
  String? _hintText;

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

  PizzaPartyDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in PizzaPartyDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return PizzaPartyDifficulty.values[widget.initialDifficulty.index];
  }

  void _dealPuzzle() {
    _puzzle = createPizzaPartyPuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
      excludedFractions: _usedFractions,
    );
    _usedFractions.add(_puzzle.signature);
    _numeratorInput = '';
    _denominatorInput = '';
    _activeField = _AnswerField.numerator;
    _attempts = 0;
    _hintUsed = false;
    _roundResolved = false;
    _answerRevealed = false;
    _hardPizzaRevealed = false;
    _hintText = null;
  }

  Future<void> _showTutorialIfNeeded() async {
    if (ProgressController.preferences.getBool('tutorial.pizza-party') ==
        true) {
      return;
    }
    await ProgressController.preferences.setBool('tutorial.pizza-party', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Pizza Party'),
        content: const Text(
          'Use the number-card keypad to answer each pizza puzzle. Easy names '
          'the red fraction, Medium adds red and blue shares with the same '
          'denominator, and Hard finds a matching fraction. You get two tries '
          'and can buy one hint per round. There is no timer.',
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

  Future<void> _changeDifficulty(PizzaPartyDifficulty difficulty) async {
    if (_difficulty == difficulty || _gameFinished) return;
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _starsEarned = 0;
      _firstTryCorrect = 0;
      _usedFractions.clear();
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  String get _activeInput => _activeField == _AnswerField.numerator
      ? _numeratorInput
      : _denominatorInput;

  void _selectField(_AnswerField field) {
    if (_roundResolved ||
        (_difficulty == PizzaPartyDifficulty.hard &&
            field == _AnswerField.denominator)) {
      return;
    }
    setState(() => _activeField = field);
  }

  void _enterDigit(int digit) {
    if (_roundResolved || _activeInput.length >= 2) return;
    if (_activeInput.isEmpty && digit == 0) {
      _showToast('Fractions must have a non-zero first digit.');
      return;
    }
    setState(() {
      if (_activeField == _AnswerField.numerator) {
        _numeratorInput += '$digit';
      } else {
        _denominatorInput += '$digit';
      }
    });
  }

  void _deleteDigit() {
    if (_roundResolved || _activeInput.isEmpty) return;
    setState(() {
      if (_activeField == _AnswerField.numerator) {
        _numeratorInput = _numeratorInput.substring(
          0,
          _numeratorInput.length - 1,
        );
      } else {
        _denominatorInput = _denominatorInput.substring(
          0,
          _denominatorInput.length - 1,
        );
      }
    });
  }

  void _clearAnswer() {
    if (_roundResolved) return;
    setState(() {
      _numeratorInput = '';
      _denominatorInput = '';
      _activeField = _AnswerField.numerator;
    });
  }

  bool get _answerComplete =>
      _numeratorInput.isNotEmpty &&
      (_difficulty == PizzaPartyDifficulty.hard ||
          _denominatorInput.isNotEmpty);

  Future<void> _checkAnswer() async {
    if (_roundResolved || !_answerComplete) return;
    _attempts++;
    final numerator = int.parse(_numeratorInput);
    final denominator = _difficulty == PizzaPartyDifficulty.hard
        ? null
        : int.parse(_denominatorInput);
    if (isCorrectPizzaPartyAnswer(
      puzzle: _puzzle,
      numerator: numerator,
      denominator: denominator,
    )) {
      final earnedStars = _attempts == 1 ? 3 : 1;
      setState(() {
        _roundResolved = true;
        _hardPizzaRevealed = true;
        _starsEarned += earnedStars;
        if (_attempts == 1) _firstTryCorrect++;
      });
      _showToast(
        _attempts == 1
            ? 'Perfect slice! +$earnedStars stars'
            : 'That’s it! +$earnedStars star',
      );
      return;
    }

    if (_attempts == 1) {
      _showToast(
        _difficulty == PizzaPartyDifficulty.medium &&
                denominator != _puzzle.denominator
            ? 'Keep the same denominator. Add only the numerators.'
            : 'Almost! Count the equal slices one more time.',
      );
    } else {
      setState(_revealAnswer);
      _showToast('Here is the answer and how the slices match.');
    }
  }

  void _revealAnswer() {
    _answerRevealed = true;
    _hardPizzaRevealed = true;
    _roundResolved = true;
    _numeratorInput = '${_puzzle.answer}';
    if (_difficulty != PizzaPartyDifficulty.hard) {
      _denominatorInput = '${_puzzle.denominator}';
    }
  }

  Future<void> _showHint() async {
    if (_hintUsed || _roundResolved) return;
    if (ref.read(progressProvider).coins < _hintCost) {
      _showToast('You need 3 coins for a hint.');
      return;
    }
    await ref.read(progressProvider.notifier).spendCoins(_hintCost);
    if (!mounted) return;
    setState(() {
      _hintUsed = true;
      _hintText = switch (_difficulty) {
        PizzaPartyDifficulty.easy =>
          'The pizza has ${_puzzle.denominator} equal slices. '
              '${_puzzle.numerator} are red.',
        PizzaPartyDifficulty.medium =>
          'Count the coloured slices: ${_puzzle.numerator} + '
              '${_puzzle.secondNumerator} = ${_puzzle.answer}. The pizza '
              'still has ${_puzzle.denominator} equal slices.',
        PizzaPartyDifficulty.hard =>
          'Multiply or divide the top and bottom by the same number. '
              'The hidden red portion is shown as a guide.',
      };
      if (_difficulty == PizzaPartyDifficulty.hard) {
        _hardPizzaRevealed = true;
      }
    });
  }

  Future<void> _nextRound() async {
    if (_round == _difficulty.rounds) {
      await _finishLevel();
      return;
    }
    setState(() {
      _round++;
      _dealPuzzle();
    });
  }

  Future<void> _finishLevel() async {
    if (_gameFinished) return;
    _gameFinished = true;
    final stars = _starsEarned / (_difficulty.rounds * 3) >= 0.85
        ? 3
        : _starsEarned / (_difficulty.rounds * 3) >= 0.55
        ? 2
        : 1;
    await ref
        .read(progressProvider.notifier)
        .recordGameReward(
          gameId: 'pizza-party',
          xp: 0,
          coins: _starsEarned,
          stars: stars,
        );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pizza Party complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'★' * stars}${'☆' * (3 - stars)}',
              style: const TextStyle(fontSize: 32, color: AppColors.gold),
            ),
            Text('Stars earned: $_starsEarned of 24'),
            Text('First-try answers: $_firstTryCorrect of 8'),
            Text('Wallet reward: +$_starsEarned coins'),
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
              _restartLevel();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartLevel() {
    setState(() {
      _round = 1;
      _starsEarned = 0;
      _firstTryCorrect = 0;
      _usedFractions.clear();
      _gameFinished = false;
      _dealPuzzle();
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _prompt => switch (_difficulty) {
    PizzaPartyDifficulty.easy => 'What fraction of the pizza is red?',
    PizzaPartyDifficulty.medium =>
      'Share A ate ${_puzzle.numerator}/${_puzzle.denominator}. Share B ate '
          '${_puzzle.secondNumerator}/${_puzzle.denominator}. How much did '
          'they eat altogether?',
    PizzaPartyDifficulty.hard =>
      'The red amount is the same on both pizzas. Find the missing top number.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to journey',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Pizza Party',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'How to play',
          onPressed: _showTutorial,
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(102),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<PizzaPartyDifficulty>(
                      segments: const [
                        ButtonSegment(
                          value: PizzaPartyDifficulty.easy,
                          label: Text('Easy'),
                        ),
                        ButtonSegment(
                          value: PizzaPartyDifficulty.medium,
                          label: Text('Medium'),
                        ),
                        ButtonSegment(
                          value: PizzaPartyDifficulty.hard,
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
              const SizedBox(height: 8),
              _RoundProgressBar(
                round: _round,
                starsEarned: _starsEarned,
                roundResolved: _roundResolved,
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
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _difficulty.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text('Round $_round of ${_difficulty.rounds}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_starsEarned ★',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _roundResolved
                              ? 'Round complete'
                              : 'Try ${_attempts + 1} of 2',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _QuestionCard(
                  prompt: _prompt,
                  puzzle: _puzzle,
                  difficulty: _difficulty,
                  revealHardPizza: _hardPizzaRevealed,
                  hintText: _hintText,
                  answerRevealed: _answerRevealed,
                ),
                const SizedBox(height: 14),
                _FractionAnswer(
                  difficulty: _difficulty,
                  numerator: _numeratorInput,
                  denominator: _denominatorInput,
                  fixedDenominator: _puzzle.targetDenominator,
                  activeField: _activeField,
                  enabled: !_roundResolved,
                  onSelect: _selectField,
                ),
                const SizedBox(height: 10),
                _NumberCardPad(enabled: !_roundResolved, onDigit: _enterDigit),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _roundResolved ? null : _clearAnswer,
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _roundResolved ? null : _deleteDigit,
                        icon: const Icon(Icons.backspace_outlined),
                        label: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hintUsed || _roundResolved
                            ? null
                            : _showHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: Text(_hintUsed ? 'Hint used' : 'Hint · 3'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: !_answerComplete
                      ? null
                      : _roundResolved
                      ? _nextRound
                      : _checkAnswer,
                  child: Text(
                    _roundResolved
                        ? _round == _difficulty.rounds
                              ? 'Finish Level'
                              : 'Next Round'
                        : 'Check',
                  ),
                ),
                const SizedBox(height: 6),
                const Text('NO TIMER · Two tries per round'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoundProgressBar extends StatelessWidget {
  const _RoundProgressBar({
    required this.round,
    required this.starsEarned,
    required this.roundResolved,
  });

  final int round;
  final int starsEarned;
  final bool roundResolved;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Round $round of 8, $starsEarned stars earned',
    child: Row(
      children: [
        for (var index = 1; index <= 8; index++)
          Expanded(
            child: Container(
              height: 10,
              margin: EdgeInsets.only(right: index == 8 ? 0 : 4),
              decoration: BoxDecoration(
                color: index < round || (index == round && roundResolved)
                    ? AppColors.actionGreen
                    : index == round
                    ? AppColors.gold
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
                border: index == round
                    ? Border.all(color: AppColors.navy, width: 1.5)
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.prompt,
    required this.puzzle,
    required this.difficulty,
    required this.revealHardPizza,
    required this.hintText,
    required this.answerRevealed,
  });

  final String prompt;
  final PizzaPartyPuzzle puzzle;
  final PizzaPartyDifficulty difficulty;
  final bool revealHardPizza;
  final String? hintText;
  final bool answerRevealed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBF2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.beachSand, width: 2),
      boxShadow: const [AppElevation.low],
    ),
    child: Column(
      children: [
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (difficulty == PizzaPartyDifficulty.hard)
          Row(
            children: [
              Expanded(
                child: _PizzaFraction(
                  label: 'Same red amount',
                  numerator: puzzle.numerator,
                  denominator: puzzle.firstDenominator,
                  reveal: true,
                  redSliceIndexes: puzzle.redSliceIndexes,
                  blueSliceIndexes: const [],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('='),
              ),
              Expanded(
                child: _PizzaFraction(
                  label: 'Find the top number',
                  numerator: puzzle.secondPizzaNumerator,
                  denominator: puzzle.targetDenominator,
                  reveal: revealHardPizza,
                  redSliceIndexes: puzzle.targetRedSliceIndexes,
                  blueSliceIndexes: const [],
                ),
              ),
            ],
          )
        else
          _PizzaFraction(
            label: difficulty == PizzaPartyDifficulty.easy
                ? 'One pizza'
                : 'Two shares · same-sized slices',
            numerator: puzzle.answer,
            denominator: puzzle.denominator,
            reveal: true,
            redSliceIndexes: puzzle.redSliceIndexes,
            blueSliceIndexes: puzzle.blueSliceIndexes,
            showFractionLabel: false,
          ),
        if (difficulty == PizzaPartyDifficulty.medium) ...[
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SliceLegend(color: Color(0xFFF06459), label: 'Share A'),
              SizedBox(width: 14),
              _SliceLegend(color: Color(0xFF63B8E8), label: 'Share B'),
            ],
          ),
        ],
        if (answerRevealed) ...[
          const SizedBox(height: 10),
          Text(
            difficulty == PizzaPartyDifficulty.easy
                ? 'There are ${puzzle.numerator} red slices out of '
                      '${puzzle.denominator} equal slices.'
                : difficulty == PizzaPartyDifficulty.medium
                ? 'Add the tops and keep the bottom: ${puzzle.numerator} + '
                      '${puzzle.secondNumerator} = ${puzzle.answer}.'
                : '${puzzle.numerator}/${puzzle.firstDenominator} and '
                      '${puzzle.answer}/${puzzle.targetDenominator} show the '
                      'same amount.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (hintText != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold),
            ),
            child: Text(
              hintText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _PizzaFraction extends StatelessWidget {
  const _PizzaFraction({
    required this.label,
    required this.numerator,
    required this.denominator,
    required this.reveal,
    required this.redSliceIndexes,
    required this.blueSliceIndexes,
    this.showFractionLabel = true,
  });

  final String label;
  final int numerator;
  final int denominator;
  final bool reveal;
  final List<int> redSliceIndexes;
  final List<int> blueSliceIndexes;
  final bool showFractionLabel;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Semantics(
        label: reveal
            ? 'Pizza divided into $denominator equal slices'
            : 'Pizza divided into $denominator equal slices, red portion hidden',
        child: CustomPaint(
          size: const Size(138, 138),
          painter: _PizzaPainter(
            denominator: denominator,
            redSliceIndexes: redSliceIndexes,
            blueSliceIndexes: blueSliceIndexes,
            reveal: reveal,
          ),
        ),
      ),
      if (showFractionLabel && numerator > 0) ...[
        const SizedBox(height: 3),
        _FractionLabel(
          numerator: reveal ? '$numerator' : '?',
          denominator: '$denominator',
        ),
      ],
    ],
  );
}

class _FractionLabel extends StatelessWidget {
  const _FractionLabel({required this.numerator, required this.denominator});

  final String numerator;
  final String denominator;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        numerator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      Container(width: 28, height: 2, color: AppColors.navy),
      Text(
        denominator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _SliceLegend extends StatelessWidget {
  const _SliceLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _PizzaPainter extends CustomPainter {
  const _PizzaPainter({
    required this.denominator,
    required this.redSliceIndexes,
    required this.blueSliceIndexes,
    required this.reveal,
  });

  final int denominator;
  final List<int> redSliceIndexes;
  final List<int> blueSliceIndexes;
  final bool reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 7;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()..color = const Color(0xFFFFD979);
    canvas.drawCircle(center, radius, base);
    final angle = 2 * pi / denominator;
    for (var slice = 0; slice < denominator; slice++) {
      final start = -pi / 2 + slice * angle;
      final fill = Paint()
        ..color = reveal && redSliceIndexes.contains(slice)
            ? const Color(0xFFF06459)
            : reveal && blueSliceIndexes.contains(slice)
            ? const Color(0xFF63B8E8)
            : const Color(0xFFFFD979);
      canvas.drawArc(bounds, start, angle, true, fill);
      final separator = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      final end = Offset(
        center.dx + radius * cos(start),
        center.dy + radius * sin(start),
      );
      canvas.drawLine(center, end, separator);
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFB97435)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) =>
      oldDelegate.denominator != denominator ||
      oldDelegate.reveal != reveal ||
      oldDelegate.redSliceIndexes != redSliceIndexes ||
      oldDelegate.blueSliceIndexes != blueSliceIndexes;
}

class _FractionAnswer extends StatelessWidget {
  const _FractionAnswer({
    required this.difficulty,
    required this.numerator,
    required this.denominator,
    required this.fixedDenominator,
    required this.activeField,
    required this.enabled,
    required this.onSelect,
  });

  final PizzaPartyDifficulty difficulty;
  final String numerator;
  final String denominator;
  final int fixedDenominator;
  final _AnswerField activeField;
  final bool enabled;
  final ValueChanged<_AnswerField> onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Fraction answer',
    child: Column(
      children: [
        const Text('Build the fraction'),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FractionInputBox(
              label: 'Numerator',
              value: numerator,
              selected: activeField == _AnswerField.numerator,
              enabled: enabled,
              onTap: () => onSelect(_AnswerField.numerator),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(width: 3, height: 80, color: AppColors.navy),
            ),
            difficulty == PizzaPartyDifficulty.hard
                ? _FractionInputBox(
                    label: 'Fixed denominator',
                    value: '$fixedDenominator',
                    selected: false,
                    enabled: false,
                    onTap: () {},
                  )
                : _FractionInputBox(
                    label: 'Denominator',
                    value: denominator,
                    selected: activeField == _AnswerField.denominator,
                    enabled: enabled,
                    onTap: () => onSelect(_AnswerField.denominator),
                  ),
          ],
        ),
      ],
    ),
  );
}

class _FractionInputBox extends StatelessWidget {
  const _FractionInputBox({
    required this.label,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    label: '$label${value.isEmpty ? ', empty' : ', $value'}',
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 86,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.info : AppColors.darkGrey,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Text(
          value.isEmpty ? ' ' : value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}

class _NumberCardPad extends StatelessWidget {
  const _NumberCardPad({required this.enabled, required this.onDigit});

  final bool enabled;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final digit in const [1, 2, 3, 4, 5, 6, 7, 8, 9, 0])
        SizedBox(
          width: 56,
          height: 62,
          child: NumberCard(
            key: ValueKey('pizza-party-digit-$digit'),
            value: digit,
            dimmed: !enabled,
            onTap: enabled ? () => onDigit(digit) : null,
          ),
        ),
    ],
  );
}
