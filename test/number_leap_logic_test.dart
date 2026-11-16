import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/games/number_leap/number_leap_logic.dart';

void main() {
  test('generates unique solvable puzzles within each difficulty range', () {
    for (final difficulty in NumberLeapDifficulty.values) {
      final used = <String>{};
      for (var round = 0; round < difficulty.rounds; round++) {
        final puzzle = createNumberLeapPuzzle(
          seed: round,
          difficulty: difficulty,
          excludedPuzzles: used,
        );
        used.add(puzzle.signature);

        expect(puzzle.sequence, hasLength(greaterThanOrEqualTo(3)));
        expect(puzzle.sequence, hasLength(lessThanOrEqualTo(5)));
        expect(puzzle.sequence.last, lessThanOrEqualTo(45));
        expect(puzzle.missingIndexes, isNotEmpty);
        expect(
          difficulty.operations.contains(puzzle.pattern.operation),
          isTrue,
        );
        expect(difficulty.jumps.contains(puzzle.pattern.value), isTrue);
        for (var index = 1; index < puzzle.sequence.length; index++) {
          expect(
            puzzle.sequence[index],
            puzzle.pattern.apply(puzzle.sequence[index - 1]),
          );
        }
        expect(
          isCorrectNumberLeapAnswer(puzzle: puzzle, answers: puzzle.answers),
          isTrue,
        );
      }
      expect(used, hasLength(difficulty.rounds));
    }
  });

  test('supports each defined multiplication jump without exceeding 45', () {
    final mediumAndHard = <NumberLeapDifficulty>[
      NumberLeapDifficulty.medium,
      NumberLeapDifficulty.hard,
    ];
    for (final difficulty in mediumAndHard) {
      for (final jump in difficulty.jumps) {
        final puzzles = <NumberLeapPuzzle>[];
        for (var seed = 0; seed < 1000; seed++) {
          puzzles.add(
            createNumberLeapPuzzle(seed: seed, difficulty: difficulty),
          );
          if (puzzles.any(
            (candidate) =>
                candidate.pattern.operation == NumberLeapOperation.multiply &&
                candidate.pattern.value == jump,
          )) {
            break;
          }
        }
        final puzzle = puzzles.firstWhere(
          (candidate) =>
              candidate.pattern.operation == NumberLeapOperation.multiply &&
              candidate.pattern.value == jump,
        );
        expect(puzzle.sequence.last, lessThanOrEqualTo(45));
      }
    }
  });

  test('Hard can generate two separate missing values', () {
    final puzzles = List.generate(
      80,
      (seed) => createNumberLeapPuzzle(
        seed: seed,
        difficulty: NumberLeapDifficulty.hard,
      ),
    );

    expect(puzzles.any((puzzle) => puzzle.missingIndexes.length == 2), isTrue);
  });

  test('checks multiple missing answers in their displayed order', () {
    const puzzle = NumberLeapPuzzle(
      pattern: NumberLeapPattern(operation: NumberLeapOperation.add, value: 5),
      sequence: [5, 10, 15, 20, 25],
      missingIndexes: [1, 3],
    );

    expect(
      isCorrectNumberLeapAnswer(puzzle: puzzle, answers: [10, 20]),
      isTrue,
    );
    expect(
      isCorrectNumberLeapAnswer(puzzle: puzzle, answers: [20, 10]),
      isFalse,
    );
  });
}
