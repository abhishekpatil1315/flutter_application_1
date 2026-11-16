import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/games/number_builder/number_builder_logic.dart';

void main() {
  test(
    'each difficulty generates a valid puzzle with the correct digit count',
    () {
      for (final difficulty in NumberBuilderDifficulty.values) {
        for (var seed = 0; seed < 100; seed++) {
          final puzzle = createNumberBuilderPuzzle(
            seed: seed,
            difficulty: difficulty,
          );
          expect(puzzle.cards, hasLength(5));
          expect(puzzle.cards.toSet(), hasLength(5));
          expect(
            puzzle.cards.every((digit) => digit >= 0 && digit <= 9),
            isTrue,
          );
          expect(
            puzzle.slots,
            difficulty == NumberBuilderDifficulty.easy ? 2 : 3,
          );
          expect(buildableNumbers(puzzle.cards, puzzle.slots), isNotEmpty);
        }
      }
    },
  );

  test('Easy and Medium only generate smallest and largest objectives', () {
    for (final difficulty in [
      NumberBuilderDifficulty.easy,
      NumberBuilderDifficulty.medium,
    ]) {
      for (var seed = 0; seed < 50; seed++) {
        final puzzle = createNumberBuilderPuzzle(
          seed: seed,
          difficulty: difficulty,
        );
        expect(
          puzzle.objective,
          isIn([
            NumberBuilderObjective.smallest,
            NumberBuilderObjective.largest,
          ]),
        );
      }
    }
  });

  test('Hard closest-to-target challenges have one unique optimal answer', () {
    for (var seed = 0; seed < 100; seed++) {
      final puzzle = createNumberBuilderPuzzle(
        seed: seed,
        difficulty: NumberBuilderDifficulty.hard,
      );
      if (puzzle.objective != NumberBuilderObjective.closestToTarget) continue;
      final answers = optimalNumberBuilderAnswers(puzzle);
      expect(puzzle.target, inInclusiveRange(100, 999));
      expect(answers, hasLength(1));
      expect(
        isOptimalNumberBuilderAnswer(
          puzzle: puzzle,
          selectedDigits: [
            for (final digit in answers.single.toString().split(''))
              int.parse(digit),
          ],
        ),
        isTrue,
      );
    }
  });

  test('buildable numbers reject leading zero and never reuse a digit', () {
    final numbers = buildableNumbers(const [0, 1, 2, 3], 2);
    expect(numbers, isNotEmpty);
    expect(numbers.every((number) => number >= 10 && number <= 99), isTrue);
    expect(() => buildableNumbers(const [1, 1, 2], 2), throwsArgumentError);
  });

  test('smallest and largest compare actual place-value arrangements', () {
    const cards = [0, 3, 6, 8, 1];
    const smallest = NumberBuilderPuzzle(
      cards: cards,
      slots: 2,
      objective: NumberBuilderObjective.smallest,
    );
    const largest = NumberBuilderPuzzle(
      cards: cards,
      slots: 2,
      objective: NumberBuilderObjective.largest,
    );
    expect(optimalNumberBuilderAnswers(smallest), [10]);
    expect(optimalNumberBuilderAnswers(largest), [86]);
    expect(
      isOptimalNumberBuilderAnswer(
        puzzle: smallest,
        selectedDigits: const [1, 0],
      ),
      isTrue,
    );
    expect(
      isOptimalNumberBuilderAnswer(
        puzzle: largest,
        selectedDigits: const [6, 8],
      ),
      isFalse,
    );
  });

  test('closest objective accepts tied optimal arrangements', () {
    const puzzle = NumberBuilderPuzzle(
      cards: [1, 2, 3, 4],
      slots: 2,
      objective: NumberBuilderObjective.closestToTarget,
      target: 22,
    );
    expect(optimalNumberBuilderAnswers(puzzle), [21, 23]);
    expect(
      isOptimalNumberBuilderAnswer(
        puzzle: puzzle,
        selectedDigits: const [2, 1],
      ),
      isTrue,
    );
    expect(
      isOptimalNumberBuilderAnswer(
        puzzle: puzzle,
        selectedDigits: const [2, 3],
      ),
      isTrue,
    );
  });
}
