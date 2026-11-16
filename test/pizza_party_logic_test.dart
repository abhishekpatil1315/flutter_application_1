import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/games/pizza_party/pizza_party_logic.dart';

void main() {
  test('Easy creates eight distinct supported fraction questions', () {
    final used = <String>{};
    for (var round = 0; round < PizzaPartyDifficulty.easy.rounds; round++) {
      final puzzle = createPizzaPartyPuzzle(
        seed: round,
        difficulty: PizzaPartyDifficulty.easy,
        excludedFractions: used,
      );
      used.add(puzzle.signature);
      expect(puzzle.denominator, inInclusiveRange(2, 6));
      expect(puzzle.numerator, inInclusiveRange(1, puzzle.denominator - 1));
      expect(puzzle.redSliceIndexes, hasLength(puzzle.numerator));
      expect(puzzle.redSliceIndexes.toSet(), hasLength(puzzle.numerator));
      expect(puzzle.blueSliceIndexes, isEmpty);
      expect(
        isCorrectPizzaPartyAnswer(
          puzzle: puzzle,
          numerator: puzzle.numerator,
          denominator: puzzle.denominator,
        ),
        isTrue,
      );
    }
    expect(used, hasLength(8));
  });

  test('Medium creates non-repeating same-denominator addition puzzles', () {
    final used = <String>{};
    for (var round = 0; round < PizzaPartyDifficulty.medium.rounds; round++) {
      final puzzle = createPizzaPartyPuzzle(
        seed: round,
        difficulty: PizzaPartyDifficulty.medium,
        excludedFractions: used,
      );
      used.add(puzzle.signature);
      expect(puzzle.denominator, inInclusiveRange(5, 10));
      expect(puzzle.numerator, inInclusiveRange(1, 3));
      expect(puzzle.secondNumerator, inInclusiveRange(1, 3));
      expect(
        puzzle.numerator + puzzle.secondNumerator,
        lessThan(puzzle.denominator),
      );
      expect(puzzle.redSliceIndexes.length, puzzle.numerator);
      expect(puzzle.blueSliceIndexes.length, puzzle.secondNumerator);
      expect(
        puzzle.redSliceIndexes.toSet().intersection(
          puzzle.blueSliceIndexes.toSet(),
        ),
        isEmpty,
      );
      expect(
        isCorrectPizzaPartyAnswer(
          puzzle: puzzle,
          numerator: puzzle.answer,
          denominator: puzzle.denominator,
        ),
        isTrue,
      );
      expect(
        isCorrectPizzaPartyAnswer(
          puzzle: puzzle,
          numerator: puzzle.answer,
          denominator: puzzle.denominator + 1,
        ),
        isFalse,
      );
    }
    expect(used, hasLength(8));
  });

  test('Hard uses distinct approved equivalents and a whole missing numerator', () {
    final used = <String>{};
    for (var round = 0; round < PizzaPartyDifficulty.hard.rounds; round++) {
      final puzzle = createPizzaPartyPuzzle(
        seed: round,
        difficulty: PizzaPartyDifficulty.hard,
        excludedFractions: used,
      );
      used.add(puzzle.signature);
      final belongsToApprovedFamily = approvedEquivalentFractionFamilies.any(
        (family) =>
            family.any(
              (fraction) =>
                  fraction.numerator == puzzle.numerator &&
                  fraction.denominator == puzzle.firstDenominator,
            ) &&
            family.any(
              (fraction) =>
                  fraction.numerator == puzzle.answer &&
                  fraction.denominator == puzzle.targetDenominator,
            ),
      );
      expect(belongsToApprovedFamily, isTrue);
      expect(puzzle.firstDenominator, isNot(puzzle.targetDenominator));
      expect(puzzle.redSliceIndexes, hasLength(puzzle.numerator));
      expect(puzzle.targetRedSliceIndexes, hasLength(puzzle.answer));
      expect(
        puzzle.numerator * puzzle.targetDenominator,
        puzzle.answer * puzzle.firstDenominator,
      );
      expect(
        isCorrectPizzaPartyAnswer(
          puzzle: puzzle,
          numerator: puzzle.answer,
          denominator: null,
        ),
        isTrue,
      );
    }
    expect(used, hasLength(8));
  });
}
