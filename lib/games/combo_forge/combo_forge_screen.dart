import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/number_card.dart';
import 'combo_forge_logic.dart';

class ComboForgeScreen extends ConsumerStatefulWidget {
  const ComboForgeScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<ComboForgeScreen> createState() => _ComboForgeScreenState();
}

class _ComboForgeScreenState extends ConsumerState<ComboForgeScreen> {
  static const _difficultyKeyPrefix = 'combo-forge.difficulty.profile.';
  static const _roundsPerGame = 5;
  static const _pointsPerWin = 10;

  final _random = Random();
  final List<int> _selectedCards = [];
  final List<ComboForgeOperation> _selectedOperations = [];
  late ComboForgeDifficulty _difficulty;
  late ComboForgePuzzle _puzzle;
  int _round = 1;
  int _roundsWon = 0;
  int _points = 0;
  int _coinsEarned = 0;
  int? _lastCalculatedResult;
  String? _feedback;
  bool _resolved = false;
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

  ComboForgeDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in ComboForgeDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return ComboForgeDifficulty.values[widget.initialDifficulty.index];
  }

  void _dealPuzzle() {
    _puzzle = createComboForgePuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
    );
    _selectedCards.clear();
    _selectedOperations.clear();
    _lastCalculatedResult = null;
    _feedback = null;
    _resolved = false;
  }

  Future<void> _showTutorialIfNeeded() async {
    if (ProgressController.preferences.getBool('tutorial.combo-forge') ==
        true) {
      return;
    }
    await ProgressController.preferences.setBool('tutorial.combo-forge', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Combo Forge'),
        content: const Text(
          'Build an expression from the digit cards and allowed operators. '
          'Your expression stays visible, but its result is hidden until you '
          'submit. Easy uses addition, Medium adds subtraction, and Hard uses '
          'all four operations and must include multiplication. Wrong '
          'submissions cost 0, 1, or 2 game points. There is no timer.',
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

  Future<void> _changeDifficulty(ComboForgeDifficulty difficulty) async {
    if (_difficulty == difficulty || _gameFinished) return;
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _roundsWon = 0;
      _points = 0;
      _coinsEarned = 0;
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  void _selectCard(int index) {
    if (_resolved ||
        _selectedCards.length != _selectedOperations.length ||
        _selectedCards.length >= _puzzle.maxOperands ||
        _selectedCards.contains(index)) {
      return;
    }
    setState(() {
      _selectedCards.add(index);
      _lastCalculatedResult = null;
      _feedback = null;
    });
  }

  void _selectOperation(ComboForgeOperation operation) {
    if (_resolved ||
        _selectedCards.length != _selectedOperations.length + 1 ||
        _selectedCards.length >= _puzzle.maxOperands ||
        !comboForgeOperations(_difficulty).contains(operation)) {
      return;
    }
    setState(() {
      _selectedOperations.add(operation);
      _lastCalculatedResult = null;
      _feedback = null;
    });
  }

  void _undo() {
    if (_resolved || (_selectedCards.isEmpty && _selectedOperations.isEmpty)) {
      return;
    }
    setState(() {
      if (_selectedCards.length > _selectedOperations.length) {
        _selectedCards.removeLast();
      } else {
        _selectedOperations.removeLast();
      }
      _lastCalculatedResult = null;
      _feedback = null;
    });
  }

  void _clearExpression() {
    if (_resolved) return;
    setState(() {
      _selectedCards.clear();
      _selectedOperations.clear();
      _lastCalculatedResult = null;
      _feedback = null;
    });
  }

  Future<void> _submit() async {
    if (_resolved) return;
    if (_selectedCards.length < 2 ||
        _selectedCards.length != _selectedOperations.length + 1) {
      setState(() => _feedback = 'Build a complete expression first.');
      return;
    }
    final values = _selectedCards.map((index) => _puzzle.cards[index]).toList();
    final result = evaluateComboForgeExpression(values, _selectedOperations);
    if (result == null) {
      _applyWrongPenalty(
        result: null,
        message: 'That expression has no whole-number result. Try again.',
      );
      return;
    }
    setState(() => _lastCalculatedResult = result);
    final correct = isValidComboForgeAnswer(
      cards: _puzzle.cards,
      selectedCards: _selectedCards,
      operations: _selectedOperations,
      target: _puzzle.target,
      difficulty: _difficulty,
    );
    if (correct) {
      setState(() {
        _resolved = true;
        _roundsWon++;
        _points += _pointsPerWin;
        _coinsEarned += 12;
        _feedback = 'Forged! Your expression reaches the target.';
      });
      await ref
          .read(progressProvider.notifier)
          .awardRoundReward(xp: 8, coins: 12);
      return;
    }
    _applyWrongPenalty(result: result);
  }

  void _applyWrongPenalty({required int? result, String? message}) {
    final penalty = comboForgeWrongSubmissionPenalty(_difficulty);
    setState(() {
      _points = max(0, _points - penalty);
      _lastCalculatedResult = result;
      _feedback =
          message ?? 'Your expression equals $result, not ${_puzzle.target}.';
      if (_difficulty == ComboForgeDifficulty.hard &&
          !_selectedOperations.contains(ComboForgeOperation.multiply)) {
        _feedback = 'Hard expressions must include multiplication.';
      }
      if (penalty > 0) _feedback = '$_feedback (−$penalty points)';
    });
  }

  String get _expressionText {
    if (_selectedCards.isEmpty) return 'Tap a number card to begin';
    final buffer = StringBuffer('${_puzzle.cards[_selectedCards.first]}');
    for (var index = 0; index < _selectedOperations.length; index++) {
      buffer.write(' ${_selectedOperations[index].symbol} ');
      if (index + 1 < _selectedCards.length) {
        buffer.write('${_puzzle.cards[_selectedCards[index + 1]]}');
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  String get _targetRange => switch (_difficulty) {
    ComboForgeDifficulty.easy => '10–15',
    ComboForgeDifficulty.medium => '8–18',
    ComboForgeDifficulty.hard => '4–48',
  };

  Future<void> _nextRound() async {
    if (_round == _roundsPerGame) {
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
    final stars = _roundsWon >= 5
        ? 3
        : _roundsWon >= 3
        ? 2
        : _roundsWon > 0
        ? 1
        : 0;
    await ref
        .read(progressProvider.notifier)
        .recordGameReward(gameId: 'combo-forge', xp: 0, coins: 0, stars: stars);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quest results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'★' * stars}${'☆' * (3 - stars)}',
              style: const TextStyle(fontSize: 32, color: AppColors.gold),
            ),
            Text('Targets reached: $_roundsWon of $_roundsPerGame'),
            Text('Score: $_points points'),
            Text('Rewards: +${_roundsWon * 8} XP · +$_coinsEarned coins'),
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
      _points = 0;
      _coinsEarned = 0;
      _gameFinished = false;
      _dealPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final operations = comboForgeOperations(_difficulty);
    final canPickCard =
        !_resolved &&
        _selectedCards.length == _selectedOperations.length &&
        _selectedCards.length < _puzzle.maxOperands;
    final canPickOperation =
        !_resolved &&
        _selectedCards.length == _selectedOperations.length + 1 &&
        _selectedCards.length < _puzzle.maxOperands;
    final canSubmit =
        !_resolved &&
        _selectedCards.length >= 2 &&
        _selectedCards.length == _selectedOperations.length + 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to journey',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Combo Forge',
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
                  child: SegmentedButton<ComboForgeDifficulty>(
                    segments: const [
                      ButtonSegment(
                        value: ComboForgeDifficulty.easy,
                        label: Text('Easy'),
                      ),
                      ButtonSegment(
                        value: ComboForgeDifficulty.medium,
                        label: Text('Medium'),
                      ),
                      ButtonSegment(
                        value: ComboForgeDifficulty.hard,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 36,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _scorePill('ROUND SCORE', '$_points pts'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _scorePill('TARGETS', '$_roundsWon')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.courseOne.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.courseOne, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TARGET  ·  $_targetRange',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${_puzzle.target}',
                          key: const Key('combo-forge-target'),
                          style: const TextStyle(
                            fontSize: 42,
                            height: 1.1,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 76),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkGrey),
                    ),
                    child: Text(
                      _expressionText,
                      key: const Key('combo-forge-expression'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your answer stays hidden until you submit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (var index = 0; index < _puzzle.cards.length; index++)
                        SizedBox(
                          width: 54,
                          height: 72,
                          child: NumberCard(
                            value: _puzzle.cards[index],
                            selected: _selectedCards.contains(index),
                            dimmed:
                                !canPickCard || _selectedCards.contains(index),
                            onTap:
                                canPickCard && !_selectedCards.contains(index)
                                ? () => _selectCard(index)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose an operator',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final operation in operations)
                        SizedBox(
                          width: 64,
                          height: 52,
                          child: FilledButton.tonal(
                            onPressed: canPickOperation
                                ? () => _selectOperation(operation)
                                : null,
                            child: Text(
                              operation.symbol,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _feedback!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _resolved
                            ? AppColors.primaryDark
                            : AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (_lastCalculatedResult != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Submitted result: $_lastCalculatedResult',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_resolved)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _nextRound,
                        child: Text(
                          _round == _roundsPerGame
                              ? 'See Results'
                              : 'Next Round',
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _selectedCards.isEmpty &&
                                    _selectedOperations.isEmpty
                                ? null
                                : _undo,
                            child: const Text('Undo'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _selectedCards.isEmpty &&
                                    _selectedOperations.isEmpty
                                ? null
                                : _clearExpression,
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        child: const Text('SUBMIT'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Wrong submission: −${comboForgeWrongSubmissionPenalty(_difficulty)} points',
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

  Widget _scorePill(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
