import 'package:flutter/material.dart';

import '../games/grid_hunt/grid_hunt_logic.dart';
import '../theme/app_theme.dart';

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    required this.title,
    required this.round,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.onInfoPressed,
    required this.onPausePressed,
    required this.child,
    this.showRound = true,
    super.key,
  });

  final String title;
  final int round;
  final GridHuntDifficulty difficulty;
  final ValueChanged<GridHuntDifficulty> onDifficultyChanged;
  final VoidCallback onInfoPressed;
  final VoidCallback onPausePressed;
  final Widget child;
  final bool showRound;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to journey',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          tooltip: 'How to play',
          onPressed: onInfoPressed,
          icon: const Icon(Icons.info_outline_rounded),
        ),
        IconButton(
          tooltip: 'Pause game',
          onPressed: onPausePressed,
          icon: const Icon(Icons.pause_rounded),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              if (showRound) ...[
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
                    '$round/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SegmentedButton<GridHuntDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: GridHuntDifficulty.easy,
                      label: Text('Easy'),
                    ),
                    ButtonSegment(
                      value: GridHuntDifficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: GridHuntDifficulty.hard,
                      label: Text('Hard'),
                    ),
                  ],
                  selected: {difficulty},
                  onSelectionChanged: (selection) =>
                      onDifficultyChanged(selection.first),
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    body: SafeArea(child: child),
  );
}
