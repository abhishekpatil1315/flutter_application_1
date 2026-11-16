import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/recommendation_engine.dart';

void main() {
  const engine = RecommendationEngine();

  GamePerformance performance({
    String gameId = 'math-snap',
    int course = 1,
    int correct = 4,
    int total = 5,
    double seconds = 20,
    int mistakes = 0,
    GameDifficulty difficulty = GameDifficulty.medium,
  }) => GamePerformance(
    gameId: gameId,
    course: course,
    correctAnswers: correct,
    totalQuestions: total,
    averageSeconds: seconds,
    mistakes: mistakes,
    difficulty: difficulty,
  );

  test('maps grade to starting course and validates grade bounds', () {
    expect(engine.startingCourseForGrade(1), 1);
    expect(engine.startingCourseForGrade(3), 2);
    expect(engine.startingCourseForGrade(6), 3);
    expect(() => engine.startingCourseForGrade(7), throwsRangeError);
  });

  test('keeps earlier courses open and gates future courses by mastery', () {
    expect(
      engine.isCourseAvailable(
        learnerStartingCourse: 2,
        course: 1,
        masteredCourses: {},
      ),
      isTrue,
    );
    expect(
      engine.isCourseAvailable(
        learnerStartingCourse: 2,
        course: 3,
        masteredCourses: {},
      ),
      isFalse,
    );
    expect(
      engine.isCourseAvailable(
        learnerStartingCourse: 2,
        course: 3,
        masteredCourses: {2},
      ),
      isTrue,
    );
    expect(
      engine.isCourseAvailable(
        learnerStartingCourse: 3,
        course: 1,
        masteredCourses: {},
      ),
      isTrue,
    );
  });

  test(
    'classifies performance and recommends higher difficulty when doing well',
    () {
      final result = engine.evaluate(
        performance: performance(correct: 5),
        courseGameIds: const ['math-snap', 'number-builder'],
        completedGameIds: const {},
        skillPrerequisites: skillPrerequisites,
      );

      expect(result.band, PerformanceBand.doingWell);
      expect(result.gameId, 'number-builder');
      expect(result.difficulty, GameDifficulty.hard);
    },
  );

  test('routes struggling learners to an uncompleted prerequisite', () {
    final result = engine.evaluate(
      performance: performance(
        gameId: 'fraction-clash',
        course: 2,
        correct: 2,
        mistakes: 3,
      ),
      courseGameIds: const ['fraction-clash', 'fair-share'],
      completedGameIds: const {'number-builder'},
      skillPrerequisites: skillPrerequisites,
    );

    expect(result.band, PerformanceBand.struggling);
    expect(result.gameId, 'math-snap');
    expect(result.needsFollowUp, isTrue);
  });

  test('recommends same-course practice when no prerequisite remains', () {
    final result = engine.evaluate(
      performance: performance(
        gameId: 'fraction-clash',
        course: 2,
        correct: 2,
        mistakes: 3,
      ),
      courseGameIds: const ['fraction-clash', 'fair-share'],
      completedGameIds: const {'number-builder', 'math-snap'},
      skillPrerequisites: skillPrerequisites,
    );

    expect(result.gameId, 'fraction-clash');
    expect(result.difficulty, GameDifficulty.easy);
    expect(result.needsFollowUp, isFalse);
  });

  test('rejects malformed game performance instead of guessing a rating', () {
    expect(() => engine.classify(performance(total: 0)), throwsArgumentError);
    expect(
      () => engine.classify(performance(correct: 6, total: 5)),
      throwsArgumentError,
    );
  });
}
