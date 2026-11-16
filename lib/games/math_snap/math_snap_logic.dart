import 'dart:math';

enum MathSnapDifficulty { easy, medium, hard }

enum MathSnapOperation { addition, multiplication }

class MathSnapPuzzle {
  const MathSnapPuzzle({required this.cards, required this.target});

  final List<int> cards;
  final int target;
}

class MathSnapSolution {
  const MathSnapSolution({
    required this.firstCard,
    required this.secondCard,
    required this.operation,
  });

  final int firstCard;
  final int secondCard;
  final MathSnapOperation operation;
}

class MathSnapAiProfile {
  const MathSnapAiProfile({
    required this.minReaction,
    required this.maxReaction,
    required this.minAccuracy,
    required this.maxAccuracy,
    required this.wrongSnapPenalty,
  });

  final Duration minReaction;
  final Duration maxReaction;
  final double minAccuracy;
  final double maxAccuracy;
  final int wrongSnapPenalty;

  static const easy = MathSnapAiProfile(
    minReaction: Duration(milliseconds: 1800),
    maxReaction: Duration(milliseconds: 3000),
    minAccuracy: 0.90,
    maxAccuracy: 0.95,
    wrongSnapPenalty: 0,
  );
  static const medium = MathSnapAiProfile(
    minReaction: Duration(milliseconds: 1200),
    maxReaction: Duration(milliseconds: 2200),
    minAccuracy: 0.93,
    maxAccuracy: 0.97,
    wrongSnapPenalty: 1,
  );
  static const hard = MathSnapAiProfile(
    minReaction: Duration(milliseconds: 700),
    maxReaction: Duration(milliseconds: 1500),
    minAccuracy: 0.95,
    maxAccuracy: 0.98,
    wrongSnapPenalty: 2,
  );
}

MathSnapAiProfile mathSnapAiProfile(MathSnapDifficulty difficulty) =>
    switch (difficulty) {
      MathSnapDifficulty.easy => MathSnapAiProfile.easy,
      MathSnapDifficulty.medium => MathSnapAiProfile.medium,
      MathSnapDifficulty.hard => MathSnapAiProfile.hard,
    };

List<MathSnapOperation> mathSnapOperations(MathSnapDifficulty difficulty) =>
    switch (difficulty) {
      MathSnapDifficulty.easy => const [MathSnapOperation.addition],
      MathSnapDifficulty.medium => const [MathSnapOperation.multiplication],
      MathSnapDifficulty.hard => MathSnapOperation.values,
    };

MathSnapPuzzle createMathSnapPuzzle({
  required int seed,
  required MathSnapDifficulty difficulty,
}) {
  final random = Random(seed);
  final cards = List<int>.generate(10, (index) => index)..shuffle(random);
  final answers = <MathSnapSolution>[];
  for (var first = 0; first < cards.length; first++) {
    for (var second = first + 1; second < cards.length; second++) {
      for (final operation in mathSnapOperations(difficulty)) {
        answers.add(
          MathSnapSolution(
            firstCard: first,
            secondCard: second,
            operation: operation,
          ),
        );
      }
    }
  }
  if (answers.isEmpty) {
    throw StateError('No valid Math Snap answers for the dealt cards.');
  }
  final solution = answers[random.nextInt(answers.length)];
  final first = cards[solution.firstCard];
  final second = cards[solution.secondCard];
  return MathSnapPuzzle(
    cards: List.unmodifiable(cards),
    target: _calculate(first, second, solution.operation),
  );
}

List<MathSnapSolution> findMathSnapSolutions({
  required List<int> cards,
  required int target,
  required MathSnapDifficulty difficulty,
}) {
  if (cards.any((card) => card < 0 || card > 9)) {
    throw ArgumentError.value(cards, 'cards', 'Cards must be between 0 and 9.');
  }
  final solutions = <MathSnapSolution>[];
  for (var first = 0; first < cards.length; first++) {
    for (var second = first + 1; second < cards.length; second++) {
      for (final operation in mathSnapOperations(difficulty)) {
        if (_calculate(cards[first], cards[second], operation) == target) {
          solutions.add(
            MathSnapSolution(
              firstCard: first,
              secondCard: second,
              operation: operation,
            ),
          );
        }
      }
    }
  }
  return List.unmodifiable(solutions);
}

bool isCorrectMathSnapAnswer({
  required List<int> cards,
  required List<int> selectedCards,
  required int target,
  required MathSnapDifficulty difficulty,
  required MathSnapOperation operation,
}) {
  if (!mathSnapOperations(difficulty).contains(operation) ||
      selectedCards.length != 2 ||
      selectedCards[0] == selectedCards[1] ||
      selectedCards.any((index) => index < 0 || index >= cards.length) ||
      cards.any((card) => card < 0 || card > 9)) {
    return false;
  }
  final first = cards[selectedCards[0]];
  final second = cards[selectedCards[1]];
  return _calculate(first, second, operation) == target;
}

int _calculate(int first, int second, MathSnapOperation operation) =>
    switch (operation) {
      MathSnapOperation.addition => first + second,
      MathSnapOperation.multiplication => first * second,
    };
