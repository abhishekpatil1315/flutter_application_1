enum PerformanceBand { doingWell, onTrack, struggling }

enum GameDifficulty { easy, medium, hard }

class PerformanceThresholds {
  const PerformanceThresholds({
    this.doingWellAccuracy = 0.85,
    this.strugglingAccuracy = 0.50,
    this.quickAverageSeconds = 30,
    this.strugglingMistakes = 3,
  }) : assert(doingWellAccuracy >= 0 && doingWellAccuracy <= 1),
       assert(strugglingAccuracy >= 0 && strugglingAccuracy <= 1),
       assert(quickAverageSeconds >= 0),
       assert(strugglingMistakes >= 0);

  final double doingWellAccuracy;
  final double strugglingAccuracy;
  final double quickAverageSeconds;
  final int strugglingMistakes;
}

class GamePerformance {
  const GamePerformance({
    required this.gameId,
    required this.course,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.averageSeconds,
    required this.mistakes,
    required this.difficulty,
  });

  final String gameId;
  final int course;
  final int correctAnswers;
  final int totalQuestions;
  final double averageSeconds;
  final int mistakes;
  final GameDifficulty difficulty;

  double get accuracy =>
      totalQuestions <= 0 ? 0 : correctAnswers / totalQuestions;
}

class GameRecommendation {
  const GameRecommendation({
    required this.band,
    required this.gameId,
    required this.difficulty,
    this.needsFollowUp = false,
    this.skillGapGameIds = const [],
  });

  final PerformanceBand band;
  final String gameId;
  final GameDifficulty difficulty;
  final bool needsFollowUp;
  final List<String> skillGapGameIds;
}

class RecommendationEngine {
  const RecommendationEngine({
    this.thresholds = const PerformanceThresholds(),
  });

  final PerformanceThresholds thresholds;

  // TODO(product): Tune these placeholder cut-offs with learning data.
  PerformanceBand classify(GamePerformance performance) {
    if (performance.totalQuestions <= 0) {
      throw ArgumentError.value(
        performance.totalQuestions,
        'totalQuestions',
        'Must be greater than zero.',
      );
    }
    if (performance.correctAnswers < 0 ||
        performance.correctAnswers > performance.totalQuestions) {
      throw ArgumentError.value(
        performance.correctAnswers,
        'correctAnswers',
        'Must be between zero and totalQuestions.',
      );
    }
    if (performance.averageSeconds < 0 || performance.mistakes < 0) {
      throw ArgumentError('Time and mistake count must not be negative.');
    }
    if (performance.course < 1 || performance.course > 3) {
      throw RangeError.range(performance.course, 1, 3, 'course');
    }
    if (performance.accuracy < thresholds.strugglingAccuracy ||
        performance.mistakes >= thresholds.strugglingMistakes) {
      return PerformanceBand.struggling;
    }
    if (performance.accuracy >= thresholds.doingWellAccuracy &&
        performance.averageSeconds <= thresholds.quickAverageSeconds) {
      return PerformanceBand.doingWell;
    }
    return PerformanceBand.onTrack;
  }

  int startingCourseForGrade(int grade) {
    if (grade < 1 || grade > 6) {
      throw RangeError.range(grade, 1, 6, 'grade');
    }
    if (grade <= 2) return 1;
    if (grade <= 4) return 2;
    return 3;
  }

  bool isCourseAvailable({
    required int learnerStartingCourse,
    required int course,
    required Set<int> masteredCourses,
  }) {
    if (learnerStartingCourse < 1 || learnerStartingCourse > 3) {
      throw RangeError.range(learnerStartingCourse, 1, 3, 'learnerStartingCourse');
    }
    if (course < 1 || course > 3) {
      throw RangeError.range(course, 1, 3, 'course');
    }
    if (learnerStartingCourse == 3 || course < learnerStartingCourse) {
      return true;
    }
    if (course == learnerStartingCourse) return true;
    for (var prerequisiteCourse = learnerStartingCourse;
        prerequisiteCourse < course;
        prerequisiteCourse++) {
      if (!masteredCourses.contains(prerequisiteCourse)) return false;
    }
    return true;
  }

  GameRecommendation evaluate({
    required GamePerformance performance,
    required List<String> courseGameIds,
    required Set<String> completedGameIds,
    required Map<String, List<String>> skillPrerequisites,
  }) {
    if (courseGameIds.isEmpty) {
      throw ArgumentError.value(courseGameIds, 'courseGameIds', 'Must not be empty.');
    }
    final band = classify(performance);
    final currentIndex = courseGameIds.indexOf(performance.gameId);
    final nextGame = currentIndex < 0
        ? courseGameIds.first
        : courseGameIds[(currentIndex + 1) % courseGameIds.length];

    if (band == PerformanceBand.doingWell) {
      return GameRecommendation(
        band: band,
        gameId: nextGame,
        difficulty: performance.difficulty == GameDifficulty.hard
            ? GameDifficulty.hard
            : GameDifficulty.values[performance.difficulty.index + 1],
      );
    }
    if (band == PerformanceBand.onTrack) {
      return GameRecommendation(
        band: band,
        gameId: nextGame,
        difficulty: performance.difficulty,
      );
    }

    final prerequisites = skillPrerequisites[performance.gameId] ?? const [];
    final availablePrerequisites = prerequisites
        .where((gameId) => !completedGameIds.contains(gameId))
        .toList(growable: false);
    if (availablePrerequisites.isNotEmpty) {
      return GameRecommendation(
        band: band,
        gameId: availablePrerequisites.first,
        difficulty: GameDifficulty.easy,
        needsFollowUp: true,
        skillGapGameIds: availablePrerequisites,
      );
    }
    return GameRecommendation(
      band: band,
      gameId: performance.gameId,
      difficulty: GameDifficulty.easy,
    );
  }
}

const skillPrerequisites = <String, List<String>>{
  'fraction-clash': ['number-builder', 'math-snap'],
  'decimal-dash': ['number-builder', 'math-snap'],
  'ratio-balance': ['fraction-clash', 'fair-share'],
  'percent-match': ['fraction-clash', 'decimal-dash'],
  'quick-grab': ['math-bingo', 'factor-frenzy'],
};
