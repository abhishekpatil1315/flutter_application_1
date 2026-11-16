import 'dart:math';

enum PizzaPartyDifficulty { easy, medium, hard }

extension PizzaPartyDifficultyRules on PizzaPartyDifficulty {
  int get rounds => 8;

  String get title => switch (this) {
    PizzaPartyDifficulty.easy => 'Name the Fraction',
    PizzaPartyDifficulty.medium => 'Add the Slices',
    PizzaPartyDifficulty.hard => 'Equal Fractions',
  };
}

class PizzaPartyFraction {
  const PizzaPartyFraction(this.numerator, this.denominator);

  final int numerator;
  final int denominator;

  String get signature => '$numerator/$denominator';
}

const approvedEquivalentFractionFamilies = <List<PizzaPartyFraction>>[
  [
    PizzaPartyFraction(1, 2),
    PizzaPartyFraction(2, 4),
    PizzaPartyFraction(3, 6),
    PizzaPartyFraction(4, 8),
    PizzaPartyFraction(5, 10),
  ],
  [
    PizzaPartyFraction(1, 3),
    PizzaPartyFraction(2, 6),
    PizzaPartyFraction(3, 9),
  ],
  [
    PizzaPartyFraction(2, 3),
    PizzaPartyFraction(4, 6),
    PizzaPartyFraction(6, 9),
  ],
  [PizzaPartyFraction(1, 4), PizzaPartyFraction(2, 8)],
  [PizzaPartyFraction(3, 4), PizzaPartyFraction(6, 8)],
  [PizzaPartyFraction(1, 5), PizzaPartyFraction(2, 10)],
  [PizzaPartyFraction(2, 5), PizzaPartyFraction(4, 10)],
  [PizzaPartyFraction(3, 5), PizzaPartyFraction(6, 10)],
  [PizzaPartyFraction(4, 5), PizzaPartyFraction(8, 10)],
];

class PizzaPartyPuzzle {
  const PizzaPartyPuzzle({
    required this.difficulty,
    required this.denominator,
    required this.numerator,
    required this.secondNumerator,
    required this.firstDenominator,
    required this.targetDenominator,
    required this.answer,
    required this.redSliceIndexes,
    required this.blueSliceIndexes,
    this.targetRedSliceIndexes = const [],
  });

  final PizzaPartyDifficulty difficulty;
  final int denominator;
  final int numerator;
  final int secondNumerator;
  final int firstDenominator;
  final int targetDenominator;
  final int answer;
  final List<int> redSliceIndexes;
  final List<int> blueSliceIndexes;
  final List<int> targetRedSliceIndexes;

  String get signature => switch (difficulty) {
    PizzaPartyDifficulty.easy => '$numerator/$denominator',
    PizzaPartyDifficulty.medium =>
      '${numerator + secondNumerator}/$denominator',
    PizzaPartyDifficulty.hard =>
      '$numerator/$firstDenominator=$answer/$targetDenominator',
  };

  int get secondPizzaNumerator =>
      difficulty == PizzaPartyDifficulty.hard ? answer : 0;
}

PizzaPartyPuzzle createPizzaPartyPuzzle({
  required int seed,
  required PizzaPartyDifficulty difficulty,
  Set<String> excludedFractions = const {},
}) {
  final random = Random(seed);
  return switch (difficulty) {
    PizzaPartyDifficulty.easy => _createEasyPuzzle(random, excludedFractions),
    PizzaPartyDifficulty.medium =>
      _createMediumPuzzle(random, excludedFractions),
    PizzaPartyDifficulty.hard => _createHardPuzzle(random, excludedFractions),
  };
}

PizzaPartyPuzzle _createEasyPuzzle(Random random, Set<String> excluded) {
  final fractions = [
    for (var denominator = 2; denominator <= 6; denominator++)
      for (var numerator = 1; numerator < denominator; numerator++)
        PizzaPartyFraction(numerator, denominator),
  ]..removeWhere((fraction) => excluded.contains(fraction.signature));
  if (fractions.isEmpty) {
    throw StateError('No unused Pizza Party Easy fractions remain.');
  }
  fractions.shuffle(random);
  final fraction = fractions.first;
  final positions = _shuffledIndexes(random, fraction.denominator)
      .take(fraction.numerator)
      .toList(growable: false);
  return PizzaPartyPuzzle(
    difficulty: PizzaPartyDifficulty.easy,
    denominator: fraction.denominator,
    numerator: fraction.numerator,
    secondNumerator: 0,
    firstDenominator: 0,
    targetDenominator: 0,
    answer: fraction.numerator,
    redSliceIndexes: positions,
    blueSliceIndexes: const [],
  );
}

PizzaPartyPuzzle _createMediumPuzzle(Random random, Set<String> excluded) {
  final possibilities = <(int, int, int)>[];
  for (var denominator = 5; denominator <= 10; denominator++) {
    for (var first = 1; first <= 3; first++) {
      for (var second = 1; second <= 3; second++) {
        if (first + second >= denominator) continue;
        if (excluded.contains('${first + second}/$denominator')) continue;
        possibilities.add((first, second, denominator));
      }
    }
  }
  if (possibilities.isEmpty) {
    throw StateError('No unused Pizza Party Medium fractions remain.');
  }
  possibilities.shuffle(random);
  final (first, second, denominator) = possibilities.first;
  final positions = _shuffledIndexes(random, denominator);
  return PizzaPartyPuzzle(
    difficulty: PizzaPartyDifficulty.medium,
    denominator: denominator,
    numerator: first,
    secondNumerator: second,
    firstDenominator: 0,
    targetDenominator: 0,
    answer: first + second,
    redSliceIndexes: positions.take(first).toList(growable: false),
    blueSliceIndexes: positions.skip(first).take(second).toList(growable: false),
  );
}

PizzaPartyPuzzle _createHardPuzzle(Random random, Set<String> excluded) {
  final pairs = <(PizzaPartyFraction, PizzaPartyFraction)>[];
  for (final family in approvedEquivalentFractionFamilies) {
    for (var first = 0; first < family.length; first++) {
      for (var second = 0; second < family.length; second++) {
        if (first == second) continue;
        final visible = family[first];
        final hidden = family[second];
        if (visible.denominator == hidden.denominator) continue;
        if (visible.numerator * hidden.denominator % visible.denominator != 0) {
          continue;
        }
        final missingNumerator =
            visible.numerator * hidden.denominator ~/ visible.denominator;
        final signature =
            '${visible.signature}=$missingNumerator/${hidden.denominator}';
        if (!excluded.contains(signature)) pairs.add((visible, hidden));
      }
    }
  }
  if (pairs.isEmpty) {
    throw StateError('No unused Pizza Party Hard fractions remain.');
  }
  pairs.shuffle(random);
  final (visible, hidden) = pairs.first;
  final red = _shuffledIndexes(random, visible.denominator)
      .take(visible.numerator)
      .toList(growable: false);
  final hiddenRed = _shuffledIndexes(random, hidden.denominator)
      .take(hidden.numerator)
      .toList(growable: false);
  return PizzaPartyPuzzle(
    difficulty: PizzaPartyDifficulty.hard,
    denominator: 0,
    numerator: visible.numerator,
    secondNumerator: hidden.numerator,
    firstDenominator: visible.denominator,
    targetDenominator: hidden.denominator,
    answer: visible.numerator * hidden.denominator ~/ visible.denominator,
    redSliceIndexes: red,
    blueSliceIndexes: const [],
    targetRedSliceIndexes: hiddenRed,
  );
}

List<int> _shuffledIndexes(Random random, int length) =>
    List<int>.generate(length, (index) => index)..shuffle(random);

bool isCorrectPizzaPartyAnswer({
  required PizzaPartyPuzzle puzzle,
  required int numerator,
  required int? denominator,
}) {
  if (numerator != puzzle.answer) return false;
  return switch (puzzle.difficulty) {
    PizzaPartyDifficulty.easy || PizzaPartyDifficulty.medium =>
      denominator == puzzle.denominator,
    PizzaPartyDifficulty.hard => denominator == null,
  };
}
