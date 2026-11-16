import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recommendation_engine.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/number_card.dart';
import 'number_builder_logic.dart';

class NumberBuilderScreen extends ConsumerStatefulWidget {
  const NumberBuilderScreen({
    this.initialDifficulty = GameDifficulty.medium,
    super.key,
  });

  final GameDifficulty initialDifficulty;

  @override
  ConsumerState<NumberBuilderScreen> createState() =>
      _NumberBuilderScreenState();
}

class _NumberBuilderScreenState extends ConsumerState<NumberBuilderScreen> {
  static const _difficultyKeyPrefix = 'number-builder.difficulty.profile.';
  static const _roundsPerGame = 5;

  final _random = Random();
  late NumberBuilderDifficulty _difficulty;
  late NumberBuilderPuzzle _puzzle;
  late List<int?> _slots;
  int? _selectedCard;
  int _round = 1;
  int _roundsWon = 0;
  int _coinsEarned = 0;
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

  NumberBuilderDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in NumberBuilderDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return NumberBuilderDifficulty.values[widget.initialDifficulty.index];
  }

  void _dealPuzzle() {
    _puzzle = createNumberBuilderPuzzle(
      seed: _random.nextInt(0x7fffffff),
      difficulty: _difficulty,
    );
    _slots = List<int?>.filled(_puzzle.slots, null);
    _selectedCard = null;
    _feedback = null;
    _resolved = false;
  }

  Future<void> _showTutorialIfNeeded() async {
    if (ProgressController.preferences.getBool('tutorial.number-builder') ==
        true) {
      return;
    }
    await ProgressController.preferences.setBool(
      'tutorial.number-builder',
      true,
    );
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _tutorialVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play Number Builder'),
        content: const Text(
          'Use each digit card at most once. Tap a card, then choose a place '
          'value slot. Build the smallest or largest number, or get closest '
          'to the target on Hard. A number cannot start with zero. You have '
          'unlimited time to think.',
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

  Future<void> _changeDifficulty(NumberBuilderDifficulty difficulty) async {
    if (_difficulty == difficulty || _gameFinished) return;
    setState(() {
      _difficulty = difficulty;
      _round = 1;
      _roundsWon = 0;
      _coinsEarned = 0;
      _dealPuzzle();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  void _selectCard(int index) {
    if (_resolved || _slots.any((digit) => digit == _puzzle.cards[index])) {
      return;
    }
    setState(() {
      _selectedCard = _selectedCard == index ? null : index;
      _feedback = null;
    });
  }

  void _placeCard(int slot) {
    final card = _selectedCard;
    if (_resolved || card == null) return;
    final digit = _puzzle.cards[card];
    if (slot == 0 && digit == 0) {
      setState(() => _feedback = 'A 2- or 3-digit number cannot start with 0.');
      return;
    }
    setState(() {
      for (var index = 0; index < _slots.length; index++) {
        if (_slots[index] == digit) _slots[index] = null;
      }
      _slots[slot] = digit;
      _selectedCard = null;
      _feedback = null;
    });
  }

  void _removeDigit(int slot) {
    if (_resolved || _slots[slot] == null) return;
    setState(() {
      _slots[slot] = null;
      _feedback = null;
    });
  }

  Future<void> _submit() async {
    if (_resolved) return;
    final digits = _slots.whereType<int>().toList();
    if (digits.length != _puzzle.slots) {
      setState(() => _feedback = 'Fill every place-value slot first.');
      return;
    }
    if (!isOptimalNumberBuilderAnswer(
      puzzle: _puzzle,
      selectedDigits: digits,
    )) {
      setState(
        () => _feedback =
            'Not the best number yet. Rearrange the digits and try again.',
      );
      return;
    }
    setState(() {
      _resolved = true;
      _roundsWon++;
      _coinsEarned += 12;
      _feedback = 'Excellent building! $numberBuilt is optimal.';
    });
    await ref
        .read(progressProvider.notifier)
        .awardRoundReward(xp: 8, coins: 12);
  }

  int get numberBuilt => int.parse(_slots.whereType<int>().join());

  String get _objectiveLabel => switch (_puzzle.objective) {
    NumberBuilderObjective.smallest =>
      'Build the SMALLEST ${_puzzle.slots}-digit number',
    NumberBuilderObjective.largest =>
      'Build the LARGEST ${_puzzle.slots}-digit number',
    NumberBuilderObjective.closestToTarget =>
      'Get CLOSEST to ${_puzzle.target}',
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
        .recordGameReward(
          gameId: 'number-builder',
          xp: 0,
          coins: 0,
          stars: stars,
        );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Great building!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'★' * stars}${'☆' * (3 - stars)}',
              style: const TextStyle(fontSize: 32, color: AppColors.gold),
            ),
            Text('Optimal rounds: $_roundsWon of $_roundsPerGame'),
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
      _coinsEarned = 0;
      _gameFinished = false;
      _dealPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to journey',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Number Builder',
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
                child: SegmentedButton<NumberBuilderDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: NumberBuilderDifficulty.easy,
                      label: Text('Easy'),
                    ),
                    ButtonSegment(
                      value: NumberBuilderDifficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: NumberBuilderDifficulty.hard,
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
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.courseOne.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.courseOne, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR OBJECTIVE',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _objectiveLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var slot = 0; slot < _slots.length; slot++) ...[
                      if (slot > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Semantics(
                        button: true,
                        label:
                            '${_placeLabel(slot, _puzzle.slots)} place, '
                            '${_slots[slot] ?? 'empty'}',
                        child: InkWell(
                          key: ValueKey('number-builder-slot-$slot'),
                          onTap: _resolved
                              ? null
                              : _selectedCard == null
                              ? () => _removeDigit(slot)
                              : () => _placeCard(slot),
                          onLongPress: () => _removeDigit(slot),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 64,
                            height: 84,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _slots[slot] == null
                                  ? Colors.white
                                  : const Color(0xFFDDF7E6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedCard != null && !_resolved
                                    ? AppColors.actionGreen
                                    : AppColors.darkGrey,
                                width: 2,
                              ),
                            ),
                            child: _slots[slot] == null
                                ? Text(
                                    _placeLabel(slot, _puzzle.slots),
                                    style: const TextStyle(
                                      color: AppColors.darkGrey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : Text(
                                    '${_slots[slot]}',
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Tap a digit, then tap a place-value slot.'),
                const SizedBox(height: 24),
                Text(
                  'Choose from your digit cards',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var index = 0; index < _puzzle.cards.length; index++)
                      SizedBox(
                        width: 58,
                        height: 76,
                        child: NumberCard(
                          value: _puzzle.cards[index],
                          selected: _selectedCard == index,
                          dimmed:
                              _resolved ||
                              _slots.contains(_puzzle.cards[index]),
                          onTap:
                              _resolved || _slots.contains(_puzzle.cards[index])
                              ? null
                              : () => _selectCard(index),
                        ),
                      ),
                  ],
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 16),
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
                const SizedBox(height: 18),
                if (_resolved)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _nextRound,
                      child: Text(
                        _round == _roundsPerGame ? 'See Results' : 'Next Round',
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _selectedCard == null &&
                                  _slots.every((digit) => digit == null)
                              ? null
                              : () => setState(() {
                                  _selectedCard = null;
                                  _slots = List<int?>.filled(
                                    _puzzle.slots,
                                    null,
                                  );
                                  _feedback = null;
                                }),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text('BUILD'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  'YOU  ·  $_roundsWon optimal',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String _placeLabel(int index, int slots) {
    final places = slots == 2 ? ['TENS', 'ONES'] : ['HUNDREDS', 'TENS', 'ONES'];
    return places[index];
  }
}
