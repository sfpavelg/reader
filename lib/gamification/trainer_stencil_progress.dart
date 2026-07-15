import '../data/hive/local_storage.dart';

/// Прогресс трафарета звёзд и дневных попыток тренажёра.
class TrainerStencilProgress {
  const TrainerStencilProgress({
    required this.dateKey,
    required this.dailyAttemptLimit,
    this.attemptsUsed = 0,
    this.attemptsByLevel = const {},
    this.stencilFilled = 0,
    this.stencilFilledByLevel = const {},
    this.freeHintUsed = false,
  });

  final String dateKey;
  final int dailyAttemptLimit;
  /// Общий счётчик (тренажёры без разбивки по уровням).
  final int attemptsUsed;
  /// Попытки по уровням: «1» — слоги, «2» — слова, «3» — фразы.
  final Map<String, int> attemptsByLevel;
  final int stencilFilled;
  /// Трафарет звёзд по уровням (скорость RSVP, уровень вспышек и т.д.).
  final Map<String, int> stencilFilledByLevel;
  /// Бесплатная подсказка уже использована сегодня (Слогоменяйка).
  final bool freeHintUsed;

  bool get hasAttemptsLeft => attemptsUsed < dailyAttemptLimit;

  int get attemptsRemaining =>
      (dailyAttemptLimit - attemptsUsed).clamp(0, dailyAttemptLimit);

  int attemptsUsedForLevel(int levelId) => attemptsByLevel['$levelId'] ?? 0;

  int attemptsRemainingForLevel(int levelId) =>
      (dailyAttemptLimit - attemptsUsedForLevel(levelId))
          .clamp(0, dailyAttemptLimit);

  bool hasAttemptsLeftForLevel(int levelId) =>
      attemptsUsedForLevel(levelId) < dailyAttemptLimit;

  int stencilFilledForLevel(int levelId) =>
      stencilFilledByLevel['$levelId'] ?? stencilFilled;

  TrainerStencilProgress registerAttempt() {
    return copyWith(attemptsUsed: attemptsUsed + 1);
  }

  TrainerStencilProgress registerAttemptForLevel(int levelId) {
    final key = '$levelId';
    final next = Map<String, int>.from(attemptsByLevel);
    next[key] = attemptsUsedForLevel(levelId) + 1;
    return copyWith(attemptsByLevel: next);
  }

  /// Обнуляет дневные попытки, сохраняя трафарет звёзд.
  TrainerStencilProgress resetAttempts({String? dateKey}) {
    return copyWith(
      dateKey: dateKey ?? this.dateKey,
      attemptsUsed: 0,
      attemptsByLevel: const {},
      freeHintUsed: false,
    );
  }

  TrainerStencilProgress copyWith({
    String? dateKey,
    int? dailyAttemptLimit,
    int? attemptsUsed,
    Map<String, int>? attemptsByLevel,
    int? stencilFilled,
    Map<String, int>? stencilFilledByLevel,
    bool? freeHintUsed,
  }) {
    return TrainerStencilProgress(
      dateKey: dateKey ?? this.dateKey,
      dailyAttemptLimit: dailyAttemptLimit ?? this.dailyAttemptLimit,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      attemptsByLevel: attemptsByLevel ?? this.attemptsByLevel,
      stencilFilled: stencilFilled ?? this.stencilFilled,
      stencilFilledByLevel: stencilFilledByLevel ?? this.stencilFilledByLevel,
      freeHintUsed: freeHintUsed ?? this.freeHintUsed,
    );
  }

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'attemptsUsed': attemptsUsed,
        if (attemptsByLevel.isNotEmpty) 'attemptsByLevel': attemptsByLevel,
        'stencilFilled': stencilFilled,
        if (stencilFilledByLevel.isNotEmpty)
          'stencilFilledByLevel': stencilFilledByLevel,
        'dailyAttemptLimit': dailyAttemptLimit,
        if (freeHintUsed) 'freeHintUsed': freeHintUsed,
      };

  factory TrainerStencilProgress.fromMap(Map<String, dynamic> map) {
    final rawByLevel = map['attemptsByLevel'];
    final attemptsByLevel = <String, int>{};
    if (rawByLevel is Map) {
      for (final entry in rawByLevel.entries) {
        attemptsByLevel['${entry.key}'] = entry.value as int? ?? 0;
      }
    }

    final rawStencilByLevel = map['stencilFilledByLevel'];
    final stencilFilledByLevel = <String, int>{};
    if (rawStencilByLevel is Map) {
      for (final entry in rawStencilByLevel.entries) {
        stencilFilledByLevel['${entry.key}'] = entry.value as int? ?? 0;
      }
    }

    return TrainerStencilProgress(
      dateKey: map['dateKey'] as String? ?? '',
      dailyAttemptLimit: map['dailyAttemptLimit'] as int? ?? 20,
      attemptsUsed: map['attemptsUsed'] as int? ?? 0,
      attemptsByLevel: attemptsByLevel,
      stencilFilled: map['stencilFilled'] as int? ?? 0,
      stencilFilledByLevel: stencilFilledByLevel,
      freeHintUsed: map['freeHintUsed'] as bool? ?? false,
    );
  }
}

/// Сохранение [TrainerStencilProgress] в Hive.
class TrainerStencilProgressStore {
  TrainerStencilProgressStore({
    required this.storageKey,
    required this.dailyAttemptLimit,
  });

  final String storageKey;
  final int dailyAttemptLimit;

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  TrainerStencilProgress load() {
    if (!LocalStorage.isReady) {
      return TrainerStencilProgress(
        dateKey: todayKey(),
        dailyAttemptLimit: dailyAttemptLimit,
      );
    }

    final raw = LocalStorage.readTrainerExtra(storageKey);
    if (raw == null) {
      return TrainerStencilProgress(
        dateKey: todayKey(),
        dailyAttemptLimit: dailyAttemptLimit,
      );
    }

    final state = TrainerStencilProgress.fromMap(raw);
    if (state.dateKey != todayKey()) {
      return TrainerStencilProgress(
        dateKey: todayKey(),
        dailyAttemptLimit: dailyAttemptLimit,
        stencilFilled: state.stencilFilled,
      );
    }
    return state.copyWith(dailyAttemptLimit: dailyAttemptLimit);
  }

  Future<void> persist(TrainerStencilProgress state) async {
    if (!LocalStorage.isReady) return;
    await LocalStorage.writeTrainerExtra(storageKey, state.toMap());
  }
}
