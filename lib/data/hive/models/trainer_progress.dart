/// Долгосрочный прогресс по конкретному тренажёру.
class TrainerProgress {
  const TrainerProgress({
    required this.trainerId,
    this.levelsCompleted = 0,
    this.bestStreak = 0,
    this.totalTasks = 0,
    this.totalCorrect = 0,
    this.lastPlayedAtMs,
  });

  final String trainerId;
  final int levelsCompleted;
  final int bestStreak;
  final int totalTasks;
  final int totalCorrect;
  final int? lastPlayedAtMs;

  double get accuracy =>
      totalTasks == 0 ? 0 : totalCorrect / totalTasks;

  TrainerProgress copyWith({
    int? levelsCompleted,
    int? bestStreak,
    int? totalTasks,
    int? totalCorrect,
    int? lastPlayedAtMs,
  }) {
    return TrainerProgress(
      trainerId: trainerId,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      bestStreak: bestStreak ?? this.bestStreak,
      totalTasks: totalTasks ?? this.totalTasks,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      lastPlayedAtMs: lastPlayedAtMs ?? this.lastPlayedAtMs,
    );
  }

  factory TrainerProgress.fromMap(Map<dynamic, dynamic> map) {
    return TrainerProgress(
      trainerId: map['trainerId'] as String,
      levelsCompleted: map['levelsCompleted'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      totalTasks: map['totalTasks'] as int? ?? 0,
      totalCorrect: map['totalCorrect'] as int? ?? 0,
      lastPlayedAtMs: map['lastPlayedAtMs'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'trainerId': trainerId,
        'levelsCompleted': levelsCompleted,
        'bestStreak': bestStreak,
        'totalTasks': totalTasks,
        'totalCorrect': totalCorrect,
        if (lastPlayedAtMs != null) 'lastPlayedAtMs': lastPlayedAtMs,
      };
}

/// Снимок текущей микро-сессии (можно выйти и вернуться без потери).
class MicroSessionSnapshot {
  const MicroSessionSnapshot({
    required this.trainerId,
    required this.levelId,
    required this.payload,
    required this.updatedAtMs,
  });

  final String trainerId;
  final int levelId;
  final Map<String, dynamic> payload;
  final int updatedAtMs;

  factory MicroSessionSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return MicroSessionSnapshot(
      trainerId: map['trainerId'] as String,
      levelId: map['levelId'] as int,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      updatedAtMs: map['updatedAtMs'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'trainerId': trainerId,
        'levelId': levelId,
        'payload': payload,
        'updatedAtMs': updatedAtMs,
      };
}

/// Специфичный payload тахистоскопа внутри [MicroSessionSnapshot].
class TachistoscopeTrainerProgress {
  const TachistoscopeTrainerProgress({
    this.flashDurationMs = 2000,
    this.correctStreak = 0,
    this.tasksCompleted = 0,
    this.correctAnswers = 0,
    this.recentTargetIds = const [],
  });

  final int flashDurationMs;
  final int correctStreak;
  final int tasksCompleted;
  final int correctAnswers;
  final List<String> recentTargetIds;

  Map<String, dynamic> toMap() => {
        'flashDurationMs': flashDurationMs,
        'correctStreak': correctStreak,
        'tasksCompleted': tasksCompleted,
        'correctAnswers': correctAnswers,
        'recentTargetIds': recentTargetIds,
      };

  factory TachistoscopeTrainerProgress.fromMap(Map<String, dynamic> map) {
    return TachistoscopeTrainerProgress(
      flashDurationMs: map['flashDurationMs'] as int? ?? 2000,
      correctStreak: map['correctStreak'] as int? ?? 0,
      tasksCompleted: map['tasksCompleted'] as int? ?? 0,
      correctAnswers: map['correctAnswers'] as int? ?? 0,
      recentTargetIds: (map['recentTargetIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  TachistoscopeTrainerProgress applySession({
    required int flashDurationMs,
    required int correctStreak,
    required int tasksCompleted,
    required int correctAnswers,
    required List<String> recentTargetIds,
  }) {
    return TachistoscopeTrainerProgress(
      flashDurationMs: flashDurationMs,
      correctStreak: correctStreak,
      tasksCompleted: tasksCompleted,
      correctAnswers: correctAnswers,
      recentTargetIds: recentTargetIds,
    );
  }
}
