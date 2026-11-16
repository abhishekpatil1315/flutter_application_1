import 'dart:math';

enum NumberBuilderDifficulty { easy, medium, hard }

enum NumberBuilderObjective { smallest, largest, closestToTarget }

class NumberBuilderPuzzle {
  const NumberBuilderPuzzle({
    required this.cards,
    required this.slots,
    required this.objective,
    this.target,
  });

  final List<int> cards;
  final int slots;
  final NumberBuilderObjective objective;
  final int? target;
}

NumberBuilderPuzzle createNumberBuilderPuzzle({
  required int seed,
  required NumberBuilderDifficulty difficulty,
}) {
  final random = Random(seed);
  final slots = difficulty == NumberBuilderDifficulty.easy ? 2 : 3;
  for (var attempt = 0; attempt < 1000; attempt++) {
    final cards = List<int>.generate(10, (digit) => digit)..shuffle(random);
    final available = List<int>.unmodifiable(cards.take(5));
    if (!available.any((digit) => digit != 0)) continue;
    final objectives = switch (difficulty) {
      NumberBuilderDifficulty.easy || NumberBuilderDifficulty.medium => const [
        NumberBuilderObjective.smallest,
        NumberBuilderObjective.largest,
      ],
      NumberBuilderDifficulty.hard => NumberBuilderObjective.values,
    };
    final objective = objectives[random.nextInt(objectives.length)];
    if (objective != NumberBuilderObjective.closestToTarget) {
      return NumberBuilderPuzzle(
        cards: available,
        slots: slots,
        objective: objective,
      );
    }

    final numbers = buildableNumbers(available, slots);
    for (var targetAttempt = 0; targetAttempt < 100; targetAttempt++) {
      final target = 100 + random.nextInt(900);
      final closestDistance = numbers
          .map((number) => (number - target).abs())
          .reduce(min);
      final closestNumbers = numbers
          .where((number) => (number - target).abs() == closestDistance)
          .toList();
      if (closestNumbers.length == 1) {
        return NumberBuilderPuzzle(
          cards: available,
          slots: slots,
          objective: objective,
          target: target,
        );
      }
    }
  }
  throw StateError('Unable to generate a valid Number Builder puzzle.');
}

List<int> buildableNumbers(List<int> cards, int slots) {
  if (slots < 2 || slots > 3) {
    throw ArgumentError.value(slots, 'slots', 'Must be 2 or 3.');
  }
  if (cards.any((card) => card < 0 || card > 9) ||
      cards.toSet().length != cards.length) {
    throw ArgumentError.value(
      cards,
      'cards',
      'Cards must be unique digits from 0 to 9.',
    );
  }
  final numbers = <int>[];
  void build(List<int> prefix, List<int> remaining) {
    if (prefix.length == slots) {
      numbers.add(int.parse(prefix.join()));
      return;
    }
    for (var index = 0; index < remaining.length; index++) {
      final digit = remaining[index];
      if (prefix.isEmpty && digit == 0) continue;
      build([...prefix, digit], [...remaining]..removeAt(index));
    }
  }

  build(const [], cards);
  return List.unmodifiable(numbers);
}

List<int> optimalNumberBuilderAnswers(NumberBuilderPuzzle puzzle) {
  final numbers = buildableNumbers(puzzle.cards, puzzle.slots);
  return switch (puzzle.objective) {
    NumberBuilderObjective.smallest => [numbers.reduce(min)],
    NumberBuilderObjective.largest => [numbers.reduce(max)],
    NumberBuilderObjective.closestToTarget => _closestAnswers(
      numbers,
      puzzle.target!,
    ),
  };
}

bool isOptimalNumberBuilderAnswer({
  required NumberBuilderPuzzle puzzle,
  required List<int> selectedDigits,
}) {
  if (selectedDigits.length != puzzle.slots ||
      selectedDigits.toSet().length != selectedDigits.length ||
      selectedDigits.any((digit) => !puzzle.cards.contains(digit)) ||
      selectedDigits.first == 0) {
    return false;
  }
  final number = int.parse(selectedDigits.join());
  return optimalNumberBuilderAnswers(puzzle).contains(number);
}

List<int> _closestAnswers(List<int> numbers, int target) {
  final distance = numbers.map((number) => (number - target).abs()).reduce(min);
  return List.unmodifiable(
    numbers.where((number) => (number - target).abs() == distance),
  );
}
