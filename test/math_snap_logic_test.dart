import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/games/math_snap/math_snap_logic.dart';

void main() {
  test('puzzle generation deals every card from zero through nine once', () {
    for (final difficulty in MathSnapDifficulty.values) {
      for (var seed = 0; seed < 100; seed++) {
        final puzzle = createMathSnapPuzzle(seed: seed, difficulty: difficulty);
        expect(
          puzzle.cards.toSet(),
          Set<int>.from(List.generate(10, (i) => i)),
        );
        expect(
          findMathSnapSolutions(
            cards: puzzle.cards,
            target: puzzle.target,
            difficulty: difficulty,
          ),
          isNotEmpty,
        );
      }
    }
  });

  test(
    'generator produces targets above nine using only single-digit cards',
    () {
      for (final difficulty in MathSnapDifficulty.values) {
        final puzzles = [
          for (var seed = 0; seed < 100; seed++)
            createMathSnapPuzzle(seed: seed, difficulty: difficulty),
        ];
        expect(puzzles.any((puzzle) => puzzle.target > 9), isTrue);
        expect(
          puzzles.every((puzzle) => puzzle.cards.every((card) => card <= 9)),
          isTrue,
        );
      }
    },
  );

  test('all correct addition pairs are accepted on Easy', () {
    const cards = [2, 3, 4, 5, 6, 7, 8, 9, 0, 1];
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [0, 3],
        target: 7,
        difficulty: MathSnapDifficulty.easy,
        operation: MathSnapOperation.addition,
      ),
      isTrue,
    );
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [1, 2],
        target: 7,
        difficulty: MathSnapDifficulty.easy,
        operation: MathSnapOperation.addition,
      ),
      isTrue,
    );
  });

  test('Medium accepts multiplication but not addition', () {
    const cards = [2, 3, 4, 6, 5, 7, 8, 9, 0, 1];
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [0, 3],
        target: 12,
        difficulty: MathSnapDifficulty.medium,
        operation: MathSnapOperation.multiplication,
      ),
      isTrue,
    );
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [1, 2],
        target: 12,
        difficulty: MathSnapDifficulty.medium,
        operation: MathSnapOperation.multiplication,
      ),
      isTrue,
    );
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [0, 3],
        target: 8,
        difficulty: MathSnapDifficulty.medium,
        operation: MathSnapOperation.addition,
      ),
      isFalse,
    );
  });

  test('Hard accepts either operation and multiplication by zero or one', () {
    const cards = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [2, 3],
        target: 5,
        difficulty: MathSnapDifficulty.hard,
        operation: MathSnapOperation.addition,
      ),
      isTrue,
    );
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [1, 4],
        target: 4,
        difficulty: MathSnapDifficulty.hard,
        operation: MathSnapOperation.multiplication,
      ),
      isTrue,
    );
    expect(
      isCorrectMathSnapAnswer(
        cards: cards,
        selectedCards: [0, 8],
        target: 0,
        difficulty: MathSnapDifficulty.hard,
        operation: MathSnapOperation.multiplication,
      ),
      isTrue,
    );
  });

  test(
    'rejects invalid selections, illegal operations, and non-digit cards',
    () {
      const cards = [2, 3, 4, 5];
      for (final selected in [
        const [0],
        const [0, 0],
        const [0, 1, 2],
        const [-1, 1],
        const [0, 4],
      ]) {
        expect(
          isCorrectMathSnapAnswer(
            cards: cards,
            selectedCards: selected,
            target: 5,
            difficulty: MathSnapDifficulty.easy,
            operation: MathSnapOperation.addition,
          ),
          isFalse,
        );
      }
      expect(
        isCorrectMathSnapAnswer(
          cards: cards,
          selectedCards: [0, 1],
          target: 6,
          difficulty: MathSnapDifficulty.easy,
          operation: MathSnapOperation.multiplication,
        ),
        isFalse,
      );
      expect(
        () => findMathSnapSolutions(
          cards: const [2, 10],
          target: 12,
          difficulty: MathSnapDifficulty.easy,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'AI difficulty profiles match the reaction, accuracy, and penalty spec',
    () {
      final easy = mathSnapAiProfile(MathSnapDifficulty.easy);
      final medium = mathSnapAiProfile(MathSnapDifficulty.medium);
      final hard = mathSnapAiProfile(MathSnapDifficulty.hard);
      expect(easy.minReaction, const Duration(milliseconds: 1800));
      expect(easy.maxReaction, const Duration(milliseconds: 3000));
      expect(easy.minAccuracy, 0.90);
      expect(easy.maxAccuracy, 0.95);
      expect(easy.wrongSnapPenalty, 0);
      expect(medium.minReaction, const Duration(milliseconds: 1200));
      expect(medium.maxReaction, const Duration(milliseconds: 2200));
      expect(medium.minAccuracy, 0.93);
      expect(medium.maxAccuracy, 0.97);
      expect(medium.wrongSnapPenalty, 1);
      expect(hard.minReaction, const Duration(milliseconds: 700));
      expect(hard.maxReaction, const Duration(milliseconds: 1500));
      expect(hard.minAccuracy, 0.95);
      expect(hard.maxAccuracy, 0.98);
      expect(hard.wrongSnapPenalty, 2);
    },
  );
}
