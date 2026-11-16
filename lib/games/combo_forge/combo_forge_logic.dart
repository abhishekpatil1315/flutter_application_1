import 'dart:math';

enum ComboForgeDifficulty { easy, medium, hard }

enum ComboForgeOperation {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const ComboForgeOperation(this.symbol);

  final String symbol;
}

class ComboForgePuzzle {
  const ComboForgePuzzle({
    required this.cards,
    required this.target,
    required this.maxOperands,
  });

  final List<int> cards;
  final int target;
  final int maxOperands;
}

List<ComboForgeOperation> comboForgeOperations(
  ComboForgeDifficulty difficulty,
) => switch (difficulty) {
  ComboForgeDifficulty.easy => const [ComboForgeOperation.add],
  ComboForgeDifficulty.medium => const [
    ComboForgeOperation.add,
    ComboForgeOperation.subtract,
  ],
  ComboForgeDifficulty.hard => ComboForgeOperation.values,
};

int comboForgeWrongSubmissionPenalty(ComboForgeDifficulty difficulty) =>
    switch (difficulty) {
      ComboForgeDifficulty.easy => 0,
      ComboForgeDifficulty.medium => 1,
      ComboForgeDifficulty.hard => 2,
    };

ComboForgePuzzle createComboForgePuzzle({
  required int seed,
  required ComboForgeDifficulty difficulty,
}) {
  final random = Random(seed);
  final cards = List<int>.generate(10, (digit) => digit)..shuffle(random);
  final maxOperands = switch (difficulty) {
    ComboForgeDifficulty.easy => 2,
    ComboForgeDifficulty.medium => 3,
    ComboForgeDifficulty.hard => 4,
  };
  final range = switch (difficulty) {
    ComboForgeDifficulty.easy => (10, 15),
    ComboForgeDifficulty.medium => (8, 18),
    ComboForgeDifficulty.hard => (4, 48),
  };
  final availableOperations = comboForgeOperations(difficulty);
  for (var attempt = 0; attempt < 100000; attempt++) {
    final selectedCards = cards.take(maxOperands).toList();
    final operations = List<ComboForgeOperation>.generate(
      maxOperands - 1,
      (_) => availableOperations[random.nextInt(availableOperations.length)],
    );
    if (difficulty == ComboForgeDifficulty.hard &&
        !operations.contains(ComboForgeOperation.multiply)) {
      operations[random.nextInt(operations.length)] =
          ComboForgeOperation.multiply;
    }
    final target = evaluateComboForgeExpression(selectedCards, operations);
    if (target != null && target >= range.$1 && target <= range.$2) {
      return ComboForgePuzzle(
        cards: List.unmodifiable(cards),
        target: target,
        maxOperands: maxOperands,
      );
    }
    cards.shuffle(random);
  }
  throw StateError('Unable to generate a valid Combo Forge puzzle.');
}

int? evaluateComboForgeExpression(
  List<int> cards,
  List<ComboForgeOperation> operations,
) {
  if (cards.length < 2 ||
      operations.length != cards.length - 1 ||
      cards.any((card) => card < 0 || card > 9) ||
      cards.toSet().length != cards.length) {
    return null;
  }

  final terms = <int>[cards.first];
  final additiveOperations = <ComboForgeOperation>[];
  for (var index = 0; index < operations.length; index++) {
    final operation = operations[index];
    final next = cards[index + 1];
    switch (operation) {
      case ComboForgeOperation.add:
      case ComboForgeOperation.subtract:
        additiveOperations.add(operation);
        terms.add(next);
      case ComboForgeOperation.multiply:
        terms[terms.length - 1] *= next;
      case ComboForgeOperation.divide:
        if (next == 0 || terms.last % next != 0) return null;
        terms[terms.length - 1] ~/= next;
    }
  }

  var total = terms.first;
  for (var index = 0; index < additiveOperations.length; index++) {
    final term = terms[index + 1];
    total = additiveOperations[index] == ComboForgeOperation.add
        ? total + term
        : total - term;
  }
  return total;
}

bool isValidComboForgeAnswer({
  required List<int> cards,
  required List<int> selectedCards,
  required List<ComboForgeOperation> operations,
  required int target,
  required ComboForgeDifficulty difficulty,
}) {
  if (selectedCards.length < 2 ||
      selectedCards.length > _maxOperands(difficulty) ||
      selectedCards.toSet().length != selectedCards.length ||
      selectedCards.any((index) => index < 0 || index >= cards.length) ||
      !comboForgeOperations(difficulty).toSet().containsAll(operations) ||
      operations.length != selectedCards.length - 1) {
    return false;
  }
  if (difficulty == ComboForgeDifficulty.hard &&
      !operations.contains(ComboForgeOperation.multiply)) {
    return false;
  }
  final values = selectedCards.map((index) => cards[index]).toList();
  return evaluateComboForgeExpression(values, operations) == target;
}

int _maxOperands(ComboForgeDifficulty difficulty) => switch (difficulty) {
  ComboForgeDifficulty.easy => 2,
  ComboForgeDifficulty.medium => 3,
  ComboForgeDifficulty.hard => 4,
};
