import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/games/math_array/math_array_logic.dart';

void main() {
  test('generates unique, ordered equal-group facts within each level', () {
    for (final difficulty in MathArrayDifficulty.values) {
      final used = <String>{};
      for (var round = 0; round < difficulty.rounds; round++) {
        final puzzle = createMathArrayPuzzle(
          seed: round,
          difficulty: difficulty,
          excludedFacts: used,
        );
        used.add(puzzle.signature);

        expect(difficulty.firstFactors.contains(puzzle.firstFactor), isTrue);
        expect(
          puzzle.secondFactor,
          inInclusiveRange(
            difficulty.minimumSecondFactor,
            difficulty.maximumSecondFactor,
          ),
        );
        expect(puzzle.total, lessThanOrEqualTo(difficulty.maximumTotal));
        expect(puzzle.total, puzzle.firstFactor * puzzle.secondFactor);
        expect(puzzle.hiddenRows, inInclusiveRange(0, puzzle.firstFactor - 1));
      }
      expect(used, hasLength(difficulty.rounds));
    }
  });

  test('accepts only the visible row-first equation and total digits', () {
    const puzzle = MathArrayPuzzle(
      firstFactor: 3,
      secondFactor: 4,
      hiddenRows: 0,
    );

    expect(
      isCorrectMathArrayAnswer(
        puzzle: puzzle,
        firstFactor: 3,
        secondFactor: 4,
        totalDigits: [1, 2],
      ),
      isTrue,
    );
    expect(
      isCorrectMathArrayAnswer(
        puzzle: puzzle,
        firstFactor: 4,
        secondFactor: 3,
        totalDigits: [1, 2],
      ),
      isFalse,
    );
    expect(
      isCorrectMathArrayAnswer(
        puzzle: puzzle,
        firstFactor: 3,
        secondFactor: 4,
        totalDigits: [2, 1],
      ),
      isFalse,
    );
  });
}
