import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/progress_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/number_card.dart';
import 'grid_hunt_logic.dart';

class GridHuntScreen extends ConsumerStatefulWidget {
  const GridHuntScreen({
    this.initialDifficulty = GridHuntDifficulty.easy,
    super.key,
  });

  final GridHuntDifficulty initialDifficulty;

  @override
  ConsumerState<GridHuntScreen> createState() => _GridHuntScreenState();
}

class _GridHuntScreenState extends ConsumerState<GridHuntScreen> {
  static const _difficultyKeyPrefix = 'grid-hunt.difficulty.profile.';
  static const _cellGap = 8.0;
  final _random = Random();
  final List<int> _selected = [];
  final List<int> _opponentPicks = [];
  Timer? _opponentTimer;
  late GridHuntDifficulty _difficulty;
  late GridHuntRound _round;
  late List<int> _values;
  int _playerCards = 0;
  int _opponentCards = 0;
  int _boardVersion = 0;
  int _turnToken = 0;
  int _boardSeed = 0;
  int? _activePointer;
  int? _pointerStartCell;
  Offset? _pointerStartPosition;
  bool _isDragging = false;
  bool _opponentTurn = false;
  bool _tutorialVisible = false;

  String get _difficultyKey {
    final profile = ref.read(progressProvider).currentProfile;
    return '$_difficultyKeyPrefix${profile ?? 'guest'}';
  }

  @override
  void initState() {
    super.initState();
    _difficulty = _loadDifficulty();
    _dealBoard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTutorialIfNeeded());
    });
  }

  GridHuntDifficulty _loadDifficulty() {
    final saved = ProgressController.preferences.getString(_difficultyKey);
    for (final difficulty in GridHuntDifficulty.values) {
      if (difficulty.name == saved) return difficulty;
    }
    return widget.initialDifficulty;
  }

  @override
  void dispose() {
    _turnToken++;
    _opponentTimer?.cancel();
    super.dispose();
  }

  void _dealBoard() {
    _boardSeed = _random.nextInt(0x7fffffff);
    _round = createGridHuntRound(seed: _boardSeed, difficulty: _difficulty);
    _values = [..._round.values];
    _boardVersion++;
  }

  Future<void> _showTutorialIfNeeded() async {
    final preferences = ProgressController.preferences;
    if (preferences.getBool('tutorial.grid-hunt') == true) return;
    await preferences.setBool('tutorial.grid-hunt', true);
    if (mounted) await _showTutorial();
  }

  Future<void> _showTutorial() async {
    if (!mounted || _tutorialVisible) return;
    _pauseOpponentTurn();
    _tutorialVisible = true;
    var step = 0;
    const instructions = [
      (
        'Find the target',
        'The target is made from two touching cards on the board.',
        Icons.flag_rounded,
      ),
      (
        'Link cards',
        'Press and drag through neighboring cards. Drag back to undo a link.',
        Icons.grid_3x3_rounded,
      ),
      (
        'Race Prof Penguin',
        'Release to check your sum. A correct set earns 8 XP and 12 coins.',
        Icons.ac_unit_rounded,
      ),
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setTutorialState) => AlertDialog(
          title: Text('How to play · ${step + 1}/3'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                instructions[step].$3,
                size: 48,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 8),
              Text(
                instructions[step].$1,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(instructions[step].$2, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            if (step > 0)
              TextButton(
                onPressed: () => setTutorialState(() => step--),
                child: const Text('Back'),
              ),
            FilledButton(
              onPressed: () {
                if (step == instructions.length - 1) {
                  Navigator.pop(dialogContext);
                } else {
                  setTutorialState(() => step++);
                }
              },
              child: Text(step == instructions.length - 1 ? 'Got it' : 'Next'),
            ),
          ],
        ),
      ),
    );
    _tutorialVisible = false;
    if (mounted && _opponentTurn) _scheduleOpponentTurn();
  }

  Future<void> _changeDifficulty(GridHuntDifficulty difficulty) async {
    if (difficulty == _difficulty) return;
    _opponentTimer?.cancel();
    _turnToken++;
    setState(() {
      _difficulty = difficulty;
      _opponentTurn = false;
      _opponentPicks.clear();
      _selected.clear();
      _dealBoard();
    });
    await ProgressController.preferences.setString(
      _difficultyKey,
      difficulty.name,
    );
  }

  int? _cellAt(Offset position, double side) {
    final cellSide = (side - _cellGap * 2) / 3;
    final column = (position.dx / (cellSide + _cellGap)).floor();
    final row = (position.dy / (cellSide + _cellGap)).floor();
    if (column < 0 || column > 2 || row < 0 || row > 2) return null;
    final inCellX = position.dx - column * (cellSide + _cellGap);
    final inCellY = position.dy - row * (cellSide + _cellGap);
    if (inCellX > cellSide || inCellY > cellSide) return null;
    return row * 3 + column;
  }

  void _releaseSelection() {
    if (_selected.length >= 2) unawaited(_submitSelection());
  }

  void _onPointerDown(PointerDownEvent event, double side) {
    if (_opponentTurn) return;
    _activePointer = event.pointer;
    _pointerStartPosition = event.localPosition;
    _pointerStartCell = _cellAt(event.localPosition, side);
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event, double side) {
    if (_opponentTurn ||
        event.pointer != _activePointer ||
        _pointerStartCell == null) {
      return;
    }
    if (!_isDragging) {
      if ((event.localPosition - _pointerStartPosition!).distance <
          kTouchSlop) {
        return;
      }
      _isDragging = true;
      setState(() {
        _selected
          ..clear()
          ..add(_pointerStartCell!);
      });
    }
    _extendSelection(event.localPosition, side);
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    if (_isDragging) {
      _releaseSelection();
    } else if (_pointerStartCell case final index?) {
      _selectCard(index);
    }
    _clearPointerState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    if (_isDragging && mounted) setState(_selected.clear);
    _clearPointerState();
  }

  void _clearPointerState() {
    _activePointer = null;
    _pointerStartCell = null;
    _pointerStartPosition = null;
    _isDragging = false;
  }

  void _extendSelection(Offset position, double side) {
    if (_opponentTurn) return;
    final index = _cellAt(position, side);
    if (index == null || _selected.isEmpty) return;
    if (_selected.length > 1 && index == _selected[_selected.length - 2]) {
      setState(() => _selected.removeLast());
      return;
    }
    if (_selected.contains(index) ||
        !areAdjacentGridCells(_selected.last, index)) {
      return;
    }
    setState(() => _selected.add(index));
  }

  void _selectCard(int index) {
    if (_opponentTurn) return;
    setState(() {
      if (_selected.isEmpty) {
        _selected.add(index);
      } else if (_selected.length > 1 &&
          index == _selected[_selected.length - 2]) {
        _selected.removeLast();
      } else if (!_selected.contains(index) &&
          areAdjacentGridCells(_selected.last, index)) {
        _selected.add(index);
      } else if (!_selected.contains(index)) {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  void _clearSelection() {
    if (_opponentTurn) return;
    setState(_selected.clear);
  }

  void _undoSelection() {
    if (_opponentTurn || _selected.isEmpty) return;
    setState(_selected.removeLast);
  }

  Future<void> _submitSelection() async {
    if (_opponentTurn) return;
    if (_selected.length < 2) {
      _feedback('Link at least two cards.', AppColors.warning);
      return;
    }
    final sum = sumGridHuntPath(_values, _selected);
    if (sum != _round.target) {
      _feedback('Sum is $sum, target ${_round.target}', AppColors.error);
      setState(_selected.clear);
      return;
    }

    final claimed = List<int>.of(_selected);
    setState(() {
      _playerCards++;
      _selected.clear();
      _replaceCards(claimed);
      _opponentTurn = true;
    });
    await ref
        .read(progressProvider.notifier)
        .recordGameReward(gameId: 'grid-hunt', xp: 8, coins: 12, stars: 3);
    if (!mounted) return;
    _feedback('Claimed! +8 XP · +12 coins', AppColors.primaryGreen);
    _scheduleOpponentTurn();
  }

  void _replaceCards(Iterable<int> indices) {
    for (final index in indices) {
      _values[index] = _random.nextInt(5) + 1;
    }
    _boardVersion++;
  }

  void _scheduleOpponentTurn() {
    _opponentTimer?.cancel();
    if (_opponentPicks.isNotEmpty) {
      setState(_opponentPicks.clear);
    }
    final token = ++_turnToken;
    _opponentTimer = Timer(
      const Duration(milliseconds: 2800),
      () => unawaited(_playOpponentTurn(token)),
    );
  }

  Future<void> _playOpponentTurn(int token) async {
    if (!_isCurrentOpponentTurn(token)) return;
    final pair = findFirstMatchingPair(_values, _round.target);
    if (pair == null) {
      _feedback('Prof Penguin passes...', AppColors.skyBlue);
      _finishOpponentTurn(token);
      return;
    }

    for (var index = 0; index < pair.length; index++) {
      if (index > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
      if (!_isCurrentOpponentTurn(token)) return;
      setState(() => _opponentPicks.add(pair[index]));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_isCurrentOpponentTurn(token)) return;
    setState(() {
      _opponentCards++;
      _opponentPicks.clear();
      _replaceCards(pair);
    });
    _feedback('Prof Penguin claimed a set!', AppColors.skyBlue);
    _finishOpponentTurn(token);
  }

  bool _isCurrentOpponentTurn(int token) {
    return mounted && _opponentTurn && token == _turnToken;
  }

  void _pauseOpponentTurn() {
    _opponentTimer?.cancel();
    if (!_opponentTurn) return;
    _turnToken++;
    if (_opponentPicks.isNotEmpty) {
      setState(_opponentPicks.clear);
    }
  }

  void _finishOpponentTurn(int token) {
    if (!_isCurrentOpponentTurn(token)) return;
    _opponentTimer?.cancel();
    _turnToken++;
    setState(() {
      _opponentPicks.clear();
      _opponentTurn = false;
      if (hasGridHuntTarget(_values)) {
        _round = createGridHuntRoundFromValues(
          values: _values,
          seed: _random.nextInt(0x7fffffff),
        );
      } else {
        _dealBoard();
      }
    });
  }

  void _refreshBoard() {
    _opponentTimer?.cancel();
    _turnToken++;
    setState(() {
      _opponentTurn = false;
      _opponentPicks.clear();
      _selected.clear();
      _dealBoard();
    });
  }

  Future<void> _showPauseMenu() async {
    _pauseOpponentTurn();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Game paused',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'resume'),
                child: const Text('Resume'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'help'),
                child: const Text('How to Play'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'refresh'),
                child: const Text('Refresh Board'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'exit'),
                child: const Text('Exit to Home'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'resume':
        if (_opponentTurn) _scheduleOpponentTurn();
        break;
      case 'help':
        await _showTutorial();
        break;
      case 'refresh':
        _refreshBoard();
        break;
      case 'exit':
        context.pop();
        break;
      case null:
        if (_opponentTurn) _scheduleOpponentTurn();
        break;
    }
  }

  void _feedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == AppColors.error
                    ? Icons.error_outline_rounded
                    : color == AppColors.warning
                    ? Icons.warning_amber_rounded
                    : color == AppColors.primaryGreen
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    title: 'Grid Hunt',
    round: _boardVersion,
    showRound: false,
    difficulty: _difficulty,
    onDifficultyChanged: _changeDifficulty,
    onInfoPressed: _showTutorial,
    onPausePressed: _showPauseMenu,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth - 40)
            .clamp(0.0, 480.0)
            .toDouble();
        final gridSide = contentWidth.clamp(0.0, 420.0).toDouble();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
          children: [
            Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: AppColors.skyBlue,
                          size: 28,
                        ),
                        Text(
                          'PROF PENGUIN $_opponentCards Cards  —  YOU $_playerCards Cards',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _opponentTurn
                            ? AppColors.skyBlue
                            : AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _opponentTurn ? "Prof Penguin's Turn" : 'Your Turn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      color: AppColors.skyBlue.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TARGET',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${_round.target}',
                              key: const ValueKey('grid-hunt-target'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: SizedBox(
                        width: gridSide,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, gridConstraints) {
                              final side = gridConstraints.maxWidth;
                              return RawGestureDetector(
                                behavior: HitTestBehavior.opaque,
                                excludeFromSemantics: true,
                                gestures: {
                                  EagerGestureRecognizer:
                                      GestureRecognizerFactoryWithHandlers<
                                        EagerGestureRecognizer
                                      >(
                                        EagerGestureRecognizer.new,
                                        (recognizer) {},
                                      ),
                                },
                                child: Stack(
                                  children: [
                                    GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: 9,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: _cellGap,
                                            mainAxisSpacing: _cellGap,
                                          ),
                                      itemBuilder: (context, index) {
                                        final selected = _selected.contains(
                                          index,
                                        );
                                        final opponentSelected = _opponentPicks
                                            .contains(index);
                                        return AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                                  ),
                                          child: DecoratedBox(
                                            key: ValueKey(
                                              '$index-$_boardVersion-${_values[index]}',
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: opponentSelected
                                                  ? Border.all(
                                                      color: AppColors.skyBlue,
                                                      width: 4,
                                                    )
                                                  : null,
                                            ),
                                            child: NumberCard(
                                              value: _values[index],
                                              selected: selected,
                                              onTap: _opponentTurn
                                                  ? null
                                                  : () => _selectCard(index),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: Size.square(side),
                                        painter: _SelectionPathPainter(
                                          List.of(_selected),
                                          _cellGap,
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Listener(
                                        behavior: HitTestBehavior.translucent,
                                        onPointerDown: (event) =>
                                            _onPointerDown(event, side),
                                        onPointerMove: (event) =>
                                            _onPointerMove(event, side),
                                        onPointerUp: _onPointerUp,
                                        onPointerCancel: _onPointerCancel,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selected.isEmpty
                          ? _opponentTurn
                                ? _opponentPicks.isEmpty
                                      ? 'Prof Penguin is thinking...'
                                      : 'Prof Penguin is choosing a pair...'
                                : 'Drag across neighboring cards to link them'
                          : 'Sum: ${sumGridHuntPath(_values, _selected)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _opponentTurn ? null : _clearSelection,
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _opponentTurn || _selected.isEmpty
                                ? null
                                : _undoSelection,
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Undo'),
                          ),
                        ),
                      ],
                    ),
                    if (!_opponentTurn && _selected.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => unawaited(_submitSelection()),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Claim selected set'),
                        ),
                      ),
                    ],
                    if (_opponentTurn && _opponentPicks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Prof Penguin: ${_opponentPicks.map((index) => _values[index]).join(' + ')}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _SelectionPathPainter extends CustomPainter {
  _SelectionPathPainter(List<int> path, this.gap)
    : path = List.unmodifiable(path);

  final List<int> path;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final cellSide = (size.width - gap * 2) / 3;
    Offset centerOf(int index) => Offset(
      (index % 3) * (cellSide + gap) + cellSide / 2,
      (index ~/ 3) * (cellSide + gap) + cellSide / 2,
    );
    final paint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;
    for (var index = 1; index < path.length; index++) {
      final start = centerOf(path[index - 1]);
      final end = centerOf(path[index]);
      final distance = (end - start).distance;
      const dotSpacing = 9.0;
      for (
        var offset = dotSpacing / 2;
        offset < distance;
        offset += dotSpacing
      ) {
        final point = Offset.lerp(start, end, offset / distance)!;
        canvas.drawCircle(point, 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPathPainter oldDelegate) {
    if (oldDelegate.gap != gap || oldDelegate.path.length != path.length) {
      return true;
    }
    for (var index = 0; index < path.length; index++) {
      if (oldDelegate.path[index] != path[index]) return true;
    }
    return false;
  }
}
