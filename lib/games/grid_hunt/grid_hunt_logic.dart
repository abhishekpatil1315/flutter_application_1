import 'dart:math';

enum GridHuntDifficulty { easy, medium, hard }

class GridHuntRound {
  const GridHuntRound({
    required this.values,
    required this.target,
    required this.solutionPath,
  });

  final List<int> values;
  final int target;
  final List<int> solutionPath;
}

GridHuntRound createGridHuntRound({
  required int seed,
  required GridHuntDifficulty difficulty,
}) {
  final random = Random(seed);
  while (true) {
    final values = List<int>.generate(9, (_) {
      return switch (difficulty) {
        GridHuntDifficulty.easy => random.nextInt(5) + 1,
        GridHuntDifficulty.medium => random.nextInt(8) + 2,
        GridHuntDifficulty.hard => random.nextInt(9) + 2,
      };
    });
    final paths = <List<int>>[];
    for (var index = 0; index < values.length; index++) {
      for (var next = index + 1; next < values.length; next++) {
        if (areAdjacentGridCells(index, next) &&
            values[index] + values[next] <= 10) {
          paths.add([index, next]);
        }
      }
    }
    if (paths.isNotEmpty) {
      final path = paths[random.nextInt(paths.length)];
      return GridHuntRound(
        values: List.unmodifiable(values),
        target: values[path[0]] + values[path[1]],
        solutionPath: List.unmodifiable(path),
      );
    }
  }
}

GridHuntRound createGridHuntRoundFromValues({
  required List<int> values,
  required int seed,
}) {
  if (values.length != 9) {
    throw ArgumentError.value(values.length, 'values.length', 'Must be 9.');
  }
  final paths = <List<int>>[];
  for (var index = 0; index < values.length; index++) {
    for (var next = index + 1; next < values.length; next++) {
      if (areAdjacentGridCells(index, next) &&
          values[index] + values[next] <= 10) {
        paths.add([index, next]);
      }
    }
  }
  if (paths.isEmpty) {
    throw ArgumentError.value(
      values,
      'values',
      'Must contain at least one adjacent pair summing to 10 or less.',
    );
  }
  final path = paths[Random(seed).nextInt(paths.length)];
  return GridHuntRound(
    values: List.unmodifiable(values),
    target: values[path[0]] + values[path[1]],
    solutionPath: List.unmodifiable(path),
  );
}

bool hasGridHuntTarget(List<int> values) {
  if (values.length != 9) return false;
  for (var index = 0; index < values.length; index++) {
    for (var next = index + 1; next < values.length; next++) {
      if (areAdjacentGridCells(index, next) &&
          values[index] + values[next] <= 10) {
        return true;
      }
    }
  }
  return false;
}

List<int>? findAdjacentMatchingPair(List<int> values, int target) {
  if (values.length != 9) return null;
  for (var index = 0; index < values.length; index++) {
    for (var next = index + 1; next < values.length; next++) {
      if (areAdjacentGridCells(index, next) &&
          values[index] + values[next] == target) {
        return [index, next];
      }
    }
  }
  return null;
}

bool areAdjacentGridCells(int first, int second) {
  if (first < 0 || first >= 9 || second < 0 || second >= 9 || first == second) {
    return false;
  }
  final rowDistance = (first ~/ 3 - second ~/ 3).abs();
  final columnDistance = (first % 3 - second % 3).abs();
  return rowDistance <= 1 && columnDistance <= 1;
}

List<int>? findFirstMatchingPair(List<int> values, int target) {
  for (var first = 0; first < values.length; first++) {
    for (var second = first + 1; second < values.length; second++) {
      if (values[first] + values[second] == target) {
        return [first, second];
      }
    }
  }
  return null;
}

bool isLinkedPath(List<int> path) {
  if (path.length < 2 || path.any((index) => index < 0 || index >= 9)) {
    return false;
  }
  if (path.toSet().length != path.length) return false;
  for (var index = 1; index < path.length; index++) {
    if (!areAdjacentGridCells(path[index - 1], path[index])) return false;
  }
  return true;
}

int sumGridHuntPath(List<int> values, List<int> path) {
  if (!isLinkedPath(path)) return 0;
  return path.fold<int>(0, (total, index) => total + values[index]);
}

bool isCorrectGridHuntAnswer(GridHuntRound round, List<int> path) {
  return isLinkedPath(path) &&
      sumGridHuntPath(round.values, path) == round.target;
}
