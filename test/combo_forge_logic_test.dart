import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/games/combo_forge/combo_forge_logic.dart';

void main() {
  test('each difficulty generates in-range puzzles with only digit cards', () {
    for (final difficulty in ComboForgeDifficulty.values) {
      for (var seed = 0; seed < 100; seed++) {
        final puzzle = createComboForgePuzzle(
          seed: seed,
          difficulty: difficulty,
        );
        expect(puzzle.cards, hasLength(10));
        expect(
          puzzle.cards.toSet(),
          Set<int>.from(List.generate(10, (i) => i)),
        );
        expect(
          puzzle.target,
          inInclusiveRange(
            switch (difficulty) {
              ComboForgeDifficulty.easy => 10,
              ComboForgeDifficulty.medium => 8,
              ComboForgeDifficulty.hard => 4,
            },
            switch (difficulty) {
              ComboForgeDifficulty.easy => 15,
              ComboForgeDifficulty.medium => 18,
              ComboForgeDifficulty.hard => 48,
            },
          ),
        );
        expect(_hasSolution(puzzle, difficulty), isTrue);
      }
    }
  });

  test(
    'difficulty operation sets and wrong-answer penalties match the rules',
    () {
      expect(comboForgeOperations(ComboForgeDifficulty.easy), [
        ComboForgeOperation.add,
      ]);
      expect(comboForgeOperations(ComboForgeDifficulty.medium), [
        ComboForgeOperation.add,
        ComboForgeOperation.subtract,
      ]);
      expect(
        comboForgeOperations(ComboForgeDifficulty.hard),
        ComboForgeOperation.values,
      );
      expect(comboForgeWrongSubmissionPenalty(ComboForgeDifficulty.easy), 0);
      expect(comboForgeWrongSubmissionPenalty(ComboForgeDifficulty.medium), 1);
      expect(comboForgeWrongSubmissionPenalty(ComboForgeDifficulty.hard), 2);
    },
  );

  test('expression evaluation uses standard precedence and exact division', () {
    expect(
      evaluateComboForgeExpression(
        const [4, 5, 2],
        const [ComboForgeOperation.add, ComboForgeOperation.multiply],
      ),
      14,
    );
    expect(
      evaluateComboForgeExpression(
        const [8, 2, 3],
        const [ComboForgeOperation.divide, ComboForgeOperation.multiply],
      ),
      12,
    );
    expect(
      evaluateComboForgeExpression(
        const [8, 3],
        const [ComboForgeOperation.divide],
      ),
      isNull,
    );
    expect(
      evaluateComboForgeExpression(
        const [8, 0],
        const [ComboForgeOperation.divide],
      ),
      isNull,
    );
  });

  test(
    'validates actual selected expression and requires multiplication on Hard',
    () {
      const cards = [3, 5, 2, 7, 0, 1, 4, 6, 8, 9];
      expect(
        isValidComboForgeAnswer(
          cards: cards,
          selectedCards: const [0, 1],
          operations: const [ComboForgeOperation.multiply],
          target: 15,
          difficulty: ComboForgeDifficulty.hard,
        ),
        isTrue,
      );
      expect(
        isValidComboForgeAnswer(
          cards: cards,
          selectedCards: const [0, 1, 3],
          operations: const [ComboForgeOperation.add, ComboForgeOperation.add],
          target: 15,
          difficulty: ComboForgeDifficulty.hard,
        ),
        isFalse,
      );
      expect(
        isValidComboForgeAnswer(
          cards: cards,
          selectedCards: const [0, 1],
          operations: const [ComboForgeOperation.multiply],
          target: 16,
          difficulty: ComboForgeDifficulty.hard,
        ),
        isFalse,
      );
    },
  );

  test(
    'Medium accepts addition and subtraction but Easy rejects subtraction',
    () {
      const cards = [7, 5, 2, 3];
      expect(
        isValidComboForgeAnswer(
          cards: cards,
          selectedCards: const [0, 1, 2],
          operations: const [
            ComboForgeOperation.subtract,
            ComboForgeOperation.add,
          ],
          target: 4,
          difficulty: ComboForgeDifficulty.medium,
        ),
        isTrue,
      );
      expect(
        isValidComboForgeAnswer(
          cards: cards,
          selectedCards: const [0, 1],
          operations: const [ComboForgeOperation.subtract],
          target: 2,
          difficulty: ComboForgeDifficulty.easy,
        ),
        isFalse,
      );
    },
  );
}

bool _hasSolution(ComboForgePuzzle puzzle, ComboForgeDifficulty difficulty) {
  final operations = comboForgeOperations(difficulty);
  final selectedIndices = <int>[];
  final selectedOperations = <ComboForgeOperation>[];

  bool search() {
    if (selectedIndices.length >= 2 &&
        isValidComboForgeAnswer(
          cards: puzzle.cards,
          selectedCards: selectedIndices,
          operations: selectedOperations,
          target: puzzle.target,
          difficulty: difficulty,
        )) {
      return true;
    }
    if (selectedIndices.length == puzzle.maxOperands) return false;
    if (selectedIndices.length == selectedOperations.length) {
      for (var index = 0; index < puzzle.cards.length; index++) {
        if (selectedIndices.contains(index)) continue;
        selectedIndices.add(index);
        if (search()) return true;
        selectedIndices.removeLast();
      }
      return false;
    }
    for (final operation in operations) {
      selectedOperations.add(operation);
      if (search()) return true;
      selectedOperations.removeLast();
    }
    return false;
  }

  return search();
}
