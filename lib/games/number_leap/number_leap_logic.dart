import 'dart:math';

enum NumberLeapDifficulty { easy, medium, hard }

enum NumberLeapOperation { add, multiply }

extension NumberLeapDifficultyRules on NumberLeapDifficulty {
  int get rounds => switch (this) {
    NumberLeapDifficulty.easy => 6,
    NumberLeapDifficulty.medium => 8,
    NumberLeapDifficulty.hard => 10,
  };

  List<NumberLeapOperation> get operations => switch (this) {
    NumberLeapDifficulty.easy => const [NumberLeapOperation.add],
    NumberLeapDifficulty.medium => NumberLeapOperation.values,
    NumberLeapDifficulty.hard => NumberLeapOperation.values,
  };

  List<int> get jumps => switch (this) {
    NumberLeapDifficulty.easy => const [2, 3],
    NumberLeapDifficulty.medium => const [2, 3, 4],
    NumberLeapDifficulty.hard => const [2, 3, 4, 5],
  };
}

class NumberLeapPattern {
  const NumberLeapPattern({required this.operation, required this.value});

  final NumberLeapOperation operation;
  final int value;

  int apply(int number) => switch (operation) {
    NumberLeapOperation.add => number + value,
    NumberLeapOperation.multiply => number * value,
  };

  String get label =>
      operation == NumberLeapOperation.add ? '+$value' : '×$value';

  String get signature => '${operation.name}:$value';
}

class NumberLeapPuzzle {
  const NumberLeapPuzzle({
    required this.pattern,
    required this.sequence,
    required this.missingIndexes,
  });

  final NumberLeapPattern pattern;
  final List<int> sequence;
  final List<int> missingIndexes;

  String get signature =>
      '${pattern.signature}:${sequence.join(",")}:${missingIndexes.join(",")}';

  List<int> get answers => [
    for (final index in missingIndexes) sequence[index],
  ];
}

NumberLeapPuzzle createNumberLeapPuzzle({
  required int seed,
  required NumberLeapDifficulty difficulty,
  Set<String> excludedPuzzles = const {},
}) {
  final random = Random(seed);
  final patterns = [
    for (final operation in difficulty.operations)
      for (final jump in difficulty.jumps)
        NumberLeapPattern(operation: operation, value: jump),
  ];
  final candidates = <NumberLeapPuzzle>[];

  for (final pattern in patterns) {
    for (var start = 1; start <= 12; start++) {
      final sequence = <int>[start];
      while (sequence.length < 5) {
        final next = pattern.apply(sequence.last);
        if (next > 45) break;
        sequence.add(next);
      }
      if (sequence.length < 3) continue;

      final positionSets =
          difficulty == NumberLeapDifficulty.hard && sequence.length >= 5
          ? const [
              [1, 3],
              [0, 3],
              [1, 4],
              [0, 4],
              [1, 2],
              [2, 4],
            ]
          : [
              for (var index = 0; index < sequence.length; index++) [index],
            ];
      for (final positions in positionSets) {
        if (difficulty == NumberLeapDifficulty.easy &&
            pattern.operation != NumberLeapOperation.add) {
          continue;
        }
        if (!_hasUniqueVisiblePattern(sequence, positions, patterns)) continue;
        final puzzle = NumberLeapPuzzle(
          pattern: pattern,
          sequence: List.unmodifiable(sequence),
          missingIndexes: List.unmodifiable(positions),
        );
        if (!excludedPuzzles.contains(puzzle.signature)) {
          candidates.add(puzzle);
        }
      }
    }
  }

  if (candidates.isEmpty) {
    throw StateError('No unused solvable Number Leap puzzles remain.');
  }
  candidates.shuffle(random);
  return candidates.first;
}

bool _hasUniqueVisiblePattern(
  List<int> sequence,
  List<int> missingIndexes,
  List<NumberLeapPattern> allowedPatterns,
) {
  final visible = [
    for (var index = 0; index < sequence.length; index++)
      if (!missingIndexes.contains(index)) index,
  ];
  if (visible.length < 2) return false;

  final matches = allowedPatterns.where((candidate) {
    final firstIndex = visible.first;
    final firstValue = sequence[firstIndex];
    for (final index in visible.skip(1)) {
      var expected = firstValue;
      for (var step = firstIndex; step < index; step++) {
        expected = candidate.apply(expected);
      }
      if (expected != sequence[index]) return false;
    }
    return true;
  });
  return matches.length == 1;
}

bool isCorrectNumberLeapAnswer({
  required NumberLeapPuzzle puzzle,
  required List<int> answers,
}) {
  if (answers.length != puzzle.missingIndexes.length) return false;
  for (var index = 0; index < answers.length; index++) {
    if (answers[index] != puzzle.sequence[puzzle.missingIndexes[index]]) {
      return false;
    }
  }
  return true;
}
