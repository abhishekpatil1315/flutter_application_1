import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/games/grid_hunt/grid_hunt_logic.dart';

void main() {
  group('createGridHuntRound', () {
    test(
      'deals nine in-range cards and an achievable target no higher than 10',
      () {
        const ranges = {
          GridHuntDifficulty.easy: (1, 5),
          GridHuntDifficulty.medium: (2, 9),
          GridHuntDifficulty.hard: (2, 10),
        };
        for (final difficulty in GridHuntDifficulty.values) {
          for (var seed = 0; seed < 100; seed++) {
            final round = createGridHuntRound(
              seed: seed,
              difficulty: difficulty,
            );
            final range = ranges[difficulty]!;

            expect(round.values, hasLength(9));
            expect(
              round.values.every(
                (value) => value >= range.$1 && value <= range.$2,
              ),
              isTrue,
            );
            expect(round.target, inInclusiveRange(2, 10));
            expect(isLinkedPath(round.solutionPath), isTrue);
            expect(isCorrectGridHuntAnswer(round, round.solutionPath), isTrue);
          }
        }
      },
    );

    test('is deterministic for a given seed and difficulty', () {
      final first = createGridHuntRound(
        seed: 3,
        difficulty: GridHuntDifficulty.hard,
      );
      final second = createGridHuntRound(
        seed: 3,
        difficulty: GridHuntDifficulty.hard,
      );

      expect(first.values, second.values);
      expect(first.target, second.target);
      expect(first.solutionPath, second.solutionPath);
    });
  });

  test('chooses a solvable target from the live board', () {
    final round = createGridHuntRoundFromValues(
      values: [10, 4, 3, 8, 2, 9, 7, 5, 6],
      seed: 15,
    );

    expect(round.target, lessThanOrEqualTo(10));
    expect(isCorrectGridHuntAnswer(round, round.solutionPath), isTrue);
    expect(hasGridHuntTarget(round.values), isTrue);
  });

  test('reports when a board has no legal adjacent target', () {
    expect(hasGridHuntTarget(List.filled(9, 10)), isFalse);
    expect(
      () => createGridHuntRoundFromValues(values: List.filled(9, 10), seed: 1),
      throwsArgumentError,
    );
  });

  group('findFirstMatchingPair', () {
    test('returns the first matching pair in row-major card order', () {
      expect(findFirstMatchingPair([1, 4, 3, 5, 2, 7, 8, 9, 6], 7), [0, 8]);
    });

    test('returns null when no two cards make the target', () {
      expect(findFirstMatchingPair(List.filled(9, 2), 10), isNull);
    });
  });

  group('isLinkedPath', () {
    test('accepts neighboring horizontal, vertical, and diagonal cells', () {
      expect(isLinkedPath([0, 1, 5, 8]), isTrue);
      expect(isLinkedPath([0, 3]), isTrue);
      expect(isLinkedPath([0, 4]), isTrue);
    });

    test('rejects non-neighbors, repeated cells, and short paths', () {
      expect(isLinkedPath([0, 2]), isFalse);
      expect(isLinkedPath([1, 1]), isFalse);
      expect(isLinkedPath([0]), isFalse);
      expect(isLinkedPath([0, 9]), isFalse);
    });
  });

  test('calculates only valid linked-path sums', () {
    expect(sumGridHuntPath([1, 3, 4, 5, 2, 1, 3, 2, 1], [0, 1]), 4);
    expect(sumGridHuntPath([1, 3, 4, 5, 2, 1, 3, 2, 1], [0, 2]), 0);
  });

  test('rejects a linked path whose values do not make the target', () {
    const round = GridHuntRound(
      values: [1, 2, 3, 4, 5, 1, 2, 3, 4],
      target: 9,
      solutionPath: [0, 1],
    );

    expect(isCorrectGridHuntAnswer(round, [0, 1]), isFalse);
  });
}
