import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import '../models/game.dart';
import '../models/recommendation_engine.dart';

class ProgressState {
  const ProgressState({
    this.profiles = const [],
    this.currentProfile,
    this.coins = 0,
    this.streak = 0,
    this.lastPlayedDay,
    this.completedGameIds = const {},
    this.masteredCourses = const {},
    this.gameStars = const {},
    this.xp = 0,
    this.recommendedGameId,
    this.recommendedDifficulty,
    this.pendingReviewGameId,
    this.pendingFoundationGameIds = const [],
    this.profileProgress = const {},
  });

  final List<ChildProfile> profiles;
  final int? currentProfile;
  final int coins;
  final int streak;
  final String? lastPlayedDay;
  final Set<String> completedGameIds;
  final Set<int> masteredCourses;
  final Map<String, int> gameStars;
  final int xp;
  final String? recommendedGameId;
  final GameDifficulty? recommendedDifficulty;
  final String? pendingReviewGameId;
  final List<String> pendingFoundationGameIds;
  final Map<int, ProfileProgress> profileProgress;

  ProgressState copyWith({
    List<ChildProfile>? profiles,
    int? currentProfile,
    int? coins,
    int? streak,
    String? lastPlayedDay,
    Set<String>? completedGameIds,
    Set<int>? masteredCourses,
    Map<String, int>? gameStars,
    int? xp,
    String? recommendedGameId,
    GameDifficulty? recommendedDifficulty,
    String? pendingReviewGameId,
    List<String>? pendingFoundationGameIds,
    bool clearPendingReview = false,
    Map<int, ProfileProgress>? profileProgress,
  }) => ProgressState(
    profiles: profiles ?? this.profiles,
    currentProfile: currentProfile ?? this.currentProfile,
    coins: coins ?? this.coins,
    streak: streak ?? this.streak,
    lastPlayedDay: lastPlayedDay ?? this.lastPlayedDay,
    completedGameIds: completedGameIds ?? this.completedGameIds,
    masteredCourses: masteredCourses ?? this.masteredCourses,
    gameStars: gameStars ?? this.gameStars,
    xp: xp ?? this.xp,
    recommendedGameId: recommendedGameId ?? this.recommendedGameId,
    recommendedDifficulty: recommendedDifficulty ?? this.recommendedDifficulty,
    pendingReviewGameId: clearPendingReview
        ? null
        : pendingReviewGameId ?? this.pendingReviewGameId,
    pendingFoundationGameIds:
        pendingFoundationGameIds ?? this.pendingFoundationGameIds,
    profileProgress: profileProgress ?? this.profileProgress,
  );
}

class ProfileProgress {
  const ProfileProgress({
    this.coins = 20,
    this.streak = 0,
    this.lastPlayedDay,
    this.completedGameIds = const {},
    this.masteredCourses = const {},
    this.gameStars = const {},
    this.xp = 0,
    this.recommendedGameId,
    this.recommendedDifficulty,
    this.pendingReviewGameId,
    this.pendingFoundationGameIds = const [],
  });

  final int coins;
  final int streak;
  final String? lastPlayedDay;
  final Set<String> completedGameIds;
  final Set<int> masteredCourses;
  final Map<String, int> gameStars;
  final int xp;
  final String? recommendedGameId;
  final GameDifficulty? recommendedDifficulty;
  final String? pendingReviewGameId;
  final List<String> pendingFoundationGameIds;

  Map<String, Object?> toJson() => {
    'coins': coins,
    'streak': streak,
    'lastPlayedDay': lastPlayedDay,
    'completedGameIds': completedGameIds.toList(),
    'masteredCourses': masteredCourses.toList(),
    'gameStars': gameStars,
    'xp': xp,
    'recommendedGameId': recommendedGameId,
    'recommendedDifficulty': recommendedDifficulty?.name,
    'pendingReviewGameId': pendingReviewGameId,
    'pendingFoundationGameIds': pendingFoundationGameIds,
  };

  factory ProfileProgress.fromState(ProgressState state) => ProfileProgress(
    coins: state.coins,
    streak: state.streak,
    lastPlayedDay: state.lastPlayedDay,
    completedGameIds: state.completedGameIds,
    masteredCourses: state.masteredCourses,
    gameStars: state.gameStars,
    xp: state.xp,
    recommendedGameId: state.recommendedGameId,
    recommendedDifficulty: state.recommendedDifficulty,
    pendingReviewGameId: state.pendingReviewGameId,
    pendingFoundationGameIds: state.pendingFoundationGameIds,
  );

  factory ProfileProgress.fromJson(
    Map<String, dynamic> json,
  ) => ProfileProgress(
    coins: json['coins'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    lastPlayedDay: json['lastPlayedDay'] as String?,
    completedGameIds: (json['completedGameIds'] as List<dynamic>? ?? const [])
        .cast<String>()
        .toSet(),
    masteredCourses: (json['masteredCourses'] as List<dynamic>? ?? const [])
        .map((course) => course as int)
        .toSet(),
    gameStars: (json['gameStars'] as Map<String, dynamic>? ?? const {}).map(
      (key, value) => MapEntry(key, value as int),
    ),
    xp: json['xp'] as int? ?? 0,
    recommendedGameId: json['recommendedGameId'] as String?,
    recommendedDifficulty: json['recommendedDifficulty'] == null
        ? null
        : GameDifficulty.values.byName(json['recommendedDifficulty'] as String),
    pendingReviewGameId: json['pendingReviewGameId'] as String?,
    pendingFoundationGameIds:
        (json['pendingFoundationGameIds'] as List<dynamic>? ?? const [])
            .cast<String>(),
  );
}

class ProgressController extends StateNotifier<ProgressState> {
  ProgressController(this._preferences) : super(const ProgressState()) {
    _restore();
  }

  static const _storageKey = 'mathquest.progress.v1';
  final SharedPreferences _preferences;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }

  static SharedPreferences? _instance;
  static SharedPreferences get preferences {
    final value = _instance;
    if (value == null) {
      throw StateError(
        'ProgressController.initialize must run before app startup.',
      );
    }
    return value;
  }

  Future<void> _restore() async {
    final serialized = _preferences.getString(_storageKey);
    if (serialized == null) return;
    final data = jsonDecode(serialized) as Map<String, dynamic>;
    final profiles = (data['profiles'] as List<dynamic>)
        .map((item) => ChildProfile.fromJson(item as Map<String, dynamic>))
        .toList();
    final currentProfile = data['currentProfile'] as int?;
    final profileProgress =
        (data['profileProgress'] as Map<String, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(
            int.parse(key),
            ProfileProgress.fromJson(value as Map<String, dynamic>),
          ),
        );
    final activeProgress = currentProfile == null
        ? null
        : profileProgress[currentProfile];
    state = ProgressState(
      profiles: profiles,
      currentProfile: currentProfile,
      coins: activeProgress?.coins ?? data['coins'] as int? ?? 0,
      streak: activeProgress?.streak ?? data['streak'] as int? ?? 0,
      lastPlayedDay:
          activeProgress?.lastPlayedDay ?? data['lastPlayedDay'] as String?,
      completedGameIds:
          activeProgress?.completedGameIds ??
          (data['completedGameIds'] as List<dynamic>? ?? const [])
              .cast<String>()
              .toSet(),
      masteredCourses:
          activeProgress?.masteredCourses ??
          (data['masteredCourses'] as List<dynamic>? ?? const [])
              .map((course) => course as int)
              .toSet(),
      gameStars:
          activeProgress?.gameStars ??
          (data['gameStars'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key, value as int),
          ),
      xp: activeProgress?.xp ?? data['xp'] as int? ?? 0,
      recommendedGameId:
          activeProgress?.recommendedGameId ??
          data['recommendedGameId'] as String?,
      recommendedDifficulty:
          activeProgress?.recommendedDifficulty ??
          (data['recommendedDifficulty'] == null
              ? null
              : GameDifficulty.values.byName(
                  data['recommendedDifficulty'] as String,
                )),
      pendingReviewGameId:
          activeProgress?.pendingReviewGameId ??
          data['pendingReviewGameId'] as String?,
      pendingFoundationGameIds:
          activeProgress?.pendingFoundationGameIds ??
          (data['pendingFoundationGameIds'] as List<dynamic>? ?? const [])
              .cast<String>(),
      profileProgress: profileProgress,
    );
  }

  Future<void> addProfile(ChildProfile profile) async {
    final profiles = [...state.profiles, profile];
    final profileProgress = {...state.profileProgress};
    final previousProfile = state.currentProfile;
    if (previousProfile != null) {
      profileProgress[previousProfile] = ProfileProgress.fromState(state);
    }
    state = ProgressState(
      profiles: profiles,
      currentProfile: profiles.length - 1,
      coins: 20,
      profileProgress: profileProgress,
    );
    await _save();
  }

  Future<void> selectProfile(int index) async {
    if (index < 0 || index >= state.profiles.length) {
      throw RangeError.index(index, state.profiles, 'index');
    }
    final profileProgress = {...state.profileProgress};
    final previousProfile = state.currentProfile;
    if (previousProfile != null) {
      profileProgress[previousProfile] = ProfileProgress.fromState(state);
    }
    final selected = profileProgress[index] ?? const ProfileProgress();
    profileProgress[index] = selected;
    state = ProgressState(
      profiles: state.profiles,
      currentProfile: index,
      coins: selected.coins,
      streak: selected.streak,
      lastPlayedDay: selected.lastPlayedDay,
      completedGameIds: selected.completedGameIds,
      masteredCourses: selected.masteredCourses,
      gameStars: selected.gameStars,
      xp: selected.xp,
      recommendedGameId: selected.recommendedGameId,
      recommendedDifficulty: selected.recommendedDifficulty,
      pendingReviewGameId: selected.pendingReviewGameId,
      pendingFoundationGameIds: selected.pendingFoundationGameIds,
      profileProgress: profileProgress,
    );
    await _save();
  }

  Future<void> awardCoins(int amount) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Must not be negative.');
    }
    state = state.copyWith(coins: state.coins + amount);
    await _save();
  }

  Future<void> spendCoins(int amount) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Must not be negative.');
    }
    if (amount > state.coins) throw StateError('Not enough coins.');
    state = state.copyWith(coins: state.coins - amount);
    await _save();
  }

  Future<void> awardRoundReward({required int xp, required int coins}) async {
    if (xp < 0 || coins < 0) {
      throw ArgumentError('XP and coins must not be negative.');
    }
    state = state.copyWith(xp: state.xp + xp, coins: state.coins + coins);
    await _save();
  }

  Future<void> markGameCompleted(String gameId) async {
    state = state.copyWith(
      completedGameIds: {...state.completedGameIds, gameId},
    );
    await _save();
  }

  Future<void> recordGameReward({
    required String gameId,
    required int xp,
    required int coins,
    required int stars,
  }) async {
    if (gameId.isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'Must not be empty.');
    }
    if (xp < 0 || coins < 0) {
      throw ArgumentError('XP and coins must not be negative.');
    }
    if (stars < 0 || stars > 3) {
      throw RangeError.range(stars, 0, 3, 'stars');
    }
    final previousStars = state.gameStars[gameId] ?? 0;
    state = state.copyWith(
      xp: state.xp + xp,
      coins: state.coins + coins,
      gameStars: {
        ...state.gameStars,
        gameId: previousStars > stars ? previousStars : stars,
      },
      completedGameIds: {...state.completedGameIds, gameId},
    );
    await _save();
  }

  Future<GameRecommendation> recordGameResult({
    required String gameId,
    required int course,
    required int correctAnswers,
    required int totalQuestions,
    required double averageSeconds,
    required int mistakes,
    required GameDifficulty difficulty,
  }) async {
    final performance = GamePerformance(
      gameId: gameId,
      course: course,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      averageSeconds: averageSeconds,
      mistakes: mistakes,
      difficulty: difficulty,
    );
    const engine = RecommendationEngine();
    final gamesInCourse = allGames
        .where((game) => game.course == course)
        .map((game) => game.id)
        .toList(growable: false);
    final isFoundationalReview =
        state.pendingReviewGameId != null &&
        state.recommendedGameId == gameId &&
        state.pendingFoundationGameIds.contains(gameId);
    final recommendation = isFoundationalReview
        ? GameRecommendation(
            band: engine.classify(performance),
            gameId: gameId,
            difficulty: difficulty,
            needsFollowUp: true,
            skillGapGameIds: state.pendingFoundationGameIds,
          )
        : engine.evaluate(
            performance: performance,
            courseGameIds: gamesInCourse,
            completedGameIds: state.completedGameIds,
            skillPrerequisites: skillPrerequisites,
          );

    final stars = performance.accuracy >= 0.9
        ? 3
        : performance.accuracy >= 0.7
        ? 2
        : performance.accuracy >= 0.5
        ? 1
        : 0;
    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final yesterdayKey = _dayKey(today.subtract(const Duration(days: 1)));
    final streak = state.lastPlayedDay == todayKey
        ? state.streak
        : state.lastPlayedDay == yesterdayKey
        ? state.streak + 1
        : 1;
    final gameStars = {...state.gameStars, gameId: stars};
    final completed = {...state.completedGameIds, gameId};
    final courseGameIds = allGames
        .where((game) => game.course == course)
        .map((game) => game.id);
    final masteredCourses = {...state.masteredCourses};
    if (courseGameIds.isNotEmpty &&
        courseGameIds.every((id) => (gameStars[id] ?? 0) >= 2)) {
      masteredCourses.add(course);
    }
    state = state.copyWith(
      completedGameIds: completed,
      streak: streak,
      lastPlayedDay: todayKey,
      gameStars: gameStars,
      masteredCourses: masteredCourses,
      xp: state.xp + correctAnswers * 10,
      recommendedGameId: recommendation.gameId,
      recommendedDifficulty: recommendation.difficulty,
      pendingReviewGameId: recommendation.needsFollowUp
          ? state.pendingReviewGameId ?? gameId
          : state.pendingReviewGameId,
      pendingFoundationGameIds: recommendation.needsFollowUp
          ? (isFoundationalReview
                ? state.pendingFoundationGameIds
                : recommendation.skillGapGameIds)
          : state.pendingFoundationGameIds,
    );
    await _save();
    return recommendation;
  }

  Future<void> resolvePerformanceFollowUp({
    required bool improved,
    required String currentFoundationGameId,
  }) async {
    final originalGameId = state.pendingReviewGameId;
    if (originalGameId == null) {
      throw StateError('There is no pending performance check.');
    }
    final remaining = state.pendingFoundationGameIds
        .where((gameId) => gameId != currentFoundationGameId)
        .toList(growable: false);
    final nextRecommendation = improved
        ? originalGameId
        : remaining.isNotEmpty
        ? remaining.first
        : currentFoundationGameId;
    final keepChecking = !improved && remaining.isNotEmpty;
    state = state.copyWith(
      recommendedGameId: nextRecommendation,
      pendingReviewGameId: keepChecking ? originalGameId : null,
      pendingFoundationGameIds: keepChecking ? remaining : const [],
      clearPendingReview: !keepChecking,
    );
    await _save();
  }

  // TODO(backend/progress): Sync locally cached progress after backend accounts are added.
  Future<void> _save() {
    final currentProfile = state.currentProfile;
    if (currentProfile != null) {
      state = state.copyWith(
        profileProgress: {
          ...state.profileProgress,
          currentProfile: ProfileProgress.fromState(state),
        },
      );
    }
    return _preferences.setString(
      _storageKey,
      jsonEncode({
        'profiles': state.profiles.map((profile) => profile.toJson()).toList(),
        'currentProfile': state.currentProfile,
        'coins': state.coins,
        'streak': state.streak,
        'lastPlayedDay': state.lastPlayedDay,
        'completedGameIds': state.completedGameIds.toList(),
        'masteredCourses': state.masteredCourses.toList(),
        'gameStars': state.gameStars,
        'xp': state.xp,
        'recommendedGameId': state.recommendedGameId,
        'recommendedDifficulty': state.recommendedDifficulty?.name,
        'pendingReviewGameId': state.pendingReviewGameId,
        'pendingFoundationGameIds': state.pendingFoundationGameIds,
        'profileProgress': state.profileProgress.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      }),
    );
  }

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final progressProvider =
    StateNotifierProvider<ProgressController, ProgressState>(
      (ref) => ProgressController(ProgressController.preferences),
    );
