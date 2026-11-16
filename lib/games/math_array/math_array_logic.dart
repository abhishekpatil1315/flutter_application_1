import 'dart:math';

enum MathArrayDifficulty { easy, medium, hard }

extension MathArrayDifficultyRules on MathArrayDifficulty {
  int get rounds => switch (this) {
    MathArrayDifficulty.easy => 6,
    MathArrayDifficulty.medium => 8,
    MathArrayDifficulty.hard => 10,
  };

  List<int> get firstFactors => switch (this) {
    MathArrayDifficulty.easy => const [2, 3],
    MathArrayDifficulty.medium => const [4, 5],
    MathArrayDifficulty.hard => const [2, 3, 4, 5],
  };

  int get minimumSecondFactor => this == MathArrayDifficulty.hard ? 3 : 2;

  int get maximumSecondFactor => switch (this) {
    MathArrayDifficulty.easy => 5,
    MathArrayDifficulty.medium => 7,
    MathArrayDifficulty.hard => 9,
  };

  int get maximumTotal => switch (this) {
    MathArrayDifficulty.easy => 15,
    MathArrayDifficulty.medium => 35,
    MathArrayDifficulty.hard => 45,
  };
}

class MathArrayPuzzle {
  const MathArrayPuzzle({
    required this.firstFactor,
    required this.secondFactor,
    required this.hiddenRows,
  });

  final int firstFactor;
  final int secondFactor;
  final int hiddenRows;

  int get total => firstFactor * secondFactor;

  String get signature => '$firstFactor×$secondFactor';
}

MathArrayPuzzle createMathArrayPuzzle({
  required int seed,
  required MathArrayDifficulty difficulty,
  Set<String> excludedFacts = const {},
}) {
  final facts = <MathArrayPuzzle>[];
  for (final first in difficulty.firstFactors) {
    for (
      var second = difficulty.minimumSecondFactor;
      second <= difficulty.maximumSecondFactor;
      second++
    ) {
      if (first * second > difficulty.maximumTotal) continue;
      final puzzle = MathArrayPuzzle(
        firstFactor: first,
        secondFactor: second,
        hiddenRows: difficulty == MathArrayDifficulty.hard
            ? 1 + ((first + second) % (first - 1))
            : 0,
      );
      if (!excludedFacts.contains(puzzle.signature)) facts.add(puzzle);
    }
  }
  if (facts.isEmpty) {
    throw StateError('No unused Math Array facts remain for this level.');
  }
  facts.shuffle(Random(seed));
  return facts.first;
}

bool isCorrectMathArrayAnswer({
  required MathArrayPuzzle puzzle,
  required int firstFactor,
  required int secondFactor,
  required List<int> totalDigits,
}) {
  if (firstFactor != puzzle.firstFactor ||
      secondFactor != puzzle.secondFactor ||
      totalDigits.isEmpty ||
      totalDigits.any((digit) => digit < 0 || digit > 9)) {
    return false;
  }
  return int.tryParse(totalDigits.join()) == puzzle.total;
}
