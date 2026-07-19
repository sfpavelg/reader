class AppSettings {
  const AppSettings({
    this.soundEffectsEnabled = true,
    this.backgroundMusicEnabled = false,
    this.lastOpenedTrainerId,
    this.dailyTrainingMinuteLimit = defaultDailyTrainingMinuteLimit,
    this.dailyTrainingLimitEnabled = true,
    this.playTimeRestrictionEnabled = false,
    this.playBlockedFromMinutes = defaultPlayBlockedFromMinutes,
    this.playBlockedToMinutes = defaultPlayBlockedToMinutes,
    this.hardTrainerProgressGateEnabled = true,
    this.parentPasswordPrimary,
    this.parentPasswordBackup,
    this.parentRecoveryQuestion,
    this.parentRecoveryAnswer,
  });

  static const defaultDailyTrainingMinuteLimit = 15;
  static const minDailyTrainingMinuteLimit = 5;
  static const maxDailyTrainingMinuteLimit = 60;
  static const dailyTrainingMinuteLimitStep = 5;

  static const defaultPlayBlockedFromMinutes = 21 * 60;
  static const defaultPlayBlockedToMinutes = 8 * 60;
  static const minutesPerDay = 24 * 60;

  static const defaultParentRecoveryQuestion =
      'Какая река течёт в Москве?';

  final bool soundEffectsEnabled;
  final bool backgroundMusicEnabled;
  final String? lastOpenedTrainerId;
  final int dailyTrainingMinuteLimit;
  final bool dailyTrainingLimitEnabled;
  final bool playTimeRestrictionEnabled;
  final int playBlockedFromMinutes;
  final int playBlockedToMinutes;
  /// Если true — таблица умножения и Слогоменяйка закрыты, пока не
  /// израсходованы попытки в предыдущих упражнениях за день.
  final bool hardTrainerProgressGateEnabled;
  final String? parentPasswordPrimary;
  final String? parentPasswordBackup;
  final String? parentRecoveryQuestion;
  final String? parentRecoveryAnswer;

  bool get hasParentPassword =>
      parentPasswordPrimary != null && parentPasswordPrimary!.isNotEmpty;

  bool get hasParentRecovery =>
      parentRecoveryQuestion != null &&
      parentRecoveryQuestion!.isNotEmpty &&
      parentRecoveryAnswer != null &&
      parentRecoveryAnswer!.isNotEmpty;

  bool verifyParentPassword(String input) =>
      hasParentPassword &&
      AppSettings.secretsMatch(input, parentPasswordPrimary!);

  bool verifyParentBackupPassword(String input) =>
      parentPasswordBackup != null &&
      parentPasswordBackup!.isNotEmpty &&
      AppSettings.secretsMatch(input, parentPasswordBackup!);

  bool verifyParentRecoveryAnswer(String input) =>
      hasParentRecovery &&
      AppSettings.secretsMatch(input, parentRecoveryAnswer!);

  static String normalizeSecret(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool secretsMatch(String input, String stored) =>
      normalizeSecret(input) == normalizeSecret(stored);

  static String? normalizeSecretOrNull(String? value) {
    if (value == null) return null;
    final normalized = normalizeSecret(value);
    return normalized.isEmpty ? null : normalized;
  }

  int get clampedDailyTrainingMinuteLimit => dailyTrainingMinuteLimit.clamp(
        minDailyTrainingMinuteLimit,
        maxDailyTrainingMinuteLimit,
      );

  int get clampedPlayBlockedFromMinutes =>
      _clampMinutesOfDay(playBlockedFromMinutes);

  int get clampedPlayBlockedToMinutes => _clampMinutesOfDay(playBlockedToMinutes);

  String get playBlockedFromLabel =>
      labelForMinutes(clampedPlayBlockedFromMinutes);

  String get playBlockedToLabel => labelForMinutes(clampedPlayBlockedToMinutes);

  String get allowedPlayWindowDescription {
    if (!playTimeRestrictionEnabled) {
      return 'Можно играть в любое время.';
    }
    final from = playBlockedFromLabel;
    final to = playBlockedToLabel;
    if (clampedPlayBlockedFromMinutes < clampedPlayBlockedToMinutes) {
      return 'Игра доступна до $from и после $to.';
    }
    return 'Игра доступна с $to до $from.';
  }

  bool isPlayBlockedAt(DateTime time) {
    if (!playTimeRestrictionEnabled) return false;

    final minutes = time.hour * 60 + time.minute;
    final from = clampedPlayBlockedFromMinutes;
    final to = clampedPlayBlockedToMinutes;
    if (from == to) return false;

    if (from < to) {
      return minutes >= from && minutes < to;
    }
    return minutes >= from || minutes < to;
  }

  static int _clampMinutesOfDay(int value) =>
      value.clamp(0, minutesPerDay - 1);

  static String labelForMinutes(int minutes) {
    final clamped = _clampMinutesOfDay(minutes);
    final hour = clamped ~/ 60;
    final minute = clamped % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  AppSettings copyWith({
    bool? soundEffectsEnabled,
    bool? backgroundMusicEnabled,
    String? lastOpenedTrainerId,
    int? dailyTrainingMinuteLimit,
    bool? dailyTrainingLimitEnabled,
    bool? playTimeRestrictionEnabled,
    int? playBlockedFromMinutes,
    int? playBlockedToMinutes,
    bool? hardTrainerProgressGateEnabled,
    String? parentPasswordPrimary,
    String? parentPasswordBackup,
    String? parentRecoveryQuestion,
    String? parentRecoveryAnswer,
    bool clearParentPasswordPrimary = false,
    bool clearParentPasswordBackup = false,
    bool clearParentRecoveryQuestion = false,
    bool clearParentRecoveryAnswer = false,
  }) {
    return AppSettings(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      lastOpenedTrainerId: lastOpenedTrainerId ?? this.lastOpenedTrainerId,
      dailyTrainingMinuteLimit:
          dailyTrainingMinuteLimit ?? this.dailyTrainingMinuteLimit,
      dailyTrainingLimitEnabled:
          dailyTrainingLimitEnabled ?? this.dailyTrainingLimitEnabled,
      playTimeRestrictionEnabled:
          playTimeRestrictionEnabled ?? this.playTimeRestrictionEnabled,
      playBlockedFromMinutes:
          playBlockedFromMinutes ?? this.playBlockedFromMinutes,
      playBlockedToMinutes: playBlockedToMinutes ?? this.playBlockedToMinutes,
      hardTrainerProgressGateEnabled: hardTrainerProgressGateEnabled ??
          this.hardTrainerProgressGateEnabled,
      parentPasswordPrimary: clearParentPasswordPrimary
          ? null
          : (parentPasswordPrimary ?? this.parentPasswordPrimary),
      parentPasswordBackup: clearParentPasswordBackup
          ? null
          : (parentPasswordBackup ?? this.parentPasswordBackup),
      parentRecoveryQuestion: clearParentRecoveryQuestion
          ? null
          : (parentRecoveryQuestion ?? this.parentRecoveryQuestion),
      parentRecoveryAnswer: clearParentRecoveryAnswer
          ? null
          : (parentRecoveryAnswer ?? this.parentRecoveryAnswer),
    );
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    final rawLimit = map['dailyTrainingMinuteLimit'] as int?;
    return AppSettings(
      soundEffectsEnabled: map['soundEffectsEnabled'] as bool? ?? true,
      backgroundMusicEnabled: map['backgroundMusicEnabled'] as bool? ?? false,
      lastOpenedTrainerId: map['lastOpenedTrainerId'] as String?,
      dailyTrainingMinuteLimit: rawLimit == null
          ? defaultDailyTrainingMinuteLimit
          : rawLimit.clamp(
              minDailyTrainingMinuteLimit,
              maxDailyTrainingMinuteLimit,
            ),
      dailyTrainingLimitEnabled:
          map['dailyTrainingLimitEnabled'] as bool? ?? true,
      playTimeRestrictionEnabled:
          map['playTimeRestrictionEnabled'] as bool? ?? false,
      playBlockedFromMinutes: _clampMinutesOfDay(
        map['playBlockedFromMinutes'] as int? ??
            defaultPlayBlockedFromMinutes,
      ),
      playBlockedToMinutes: _clampMinutesOfDay(
        map['playBlockedToMinutes'] as int? ?? defaultPlayBlockedToMinutes,
      ),
      hardTrainerProgressGateEnabled:
          map['hardTrainerProgressGateEnabled'] as bool? ?? true,
      parentPasswordPrimary:
          normalizeSecretOrNull(map['parentPasswordPrimary'] as String?),
      parentPasswordBackup:
          normalizeSecretOrNull(map['parentPasswordBackup'] as String?),
      parentRecoveryQuestion: _nonEmpty(map['parentRecoveryQuestion'] as String?),
      parentRecoveryAnswer:
          normalizeSecretOrNull(map['parentRecoveryAnswer'] as String?),
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() => {
        'soundEffectsEnabled': soundEffectsEnabled,
        'backgroundMusicEnabled': backgroundMusicEnabled,
        'dailyTrainingMinuteLimit': clampedDailyTrainingMinuteLimit,
        'dailyTrainingLimitEnabled': dailyTrainingLimitEnabled,
        'playTimeRestrictionEnabled': playTimeRestrictionEnabled,
        'playBlockedFromMinutes': clampedPlayBlockedFromMinutes,
        'playBlockedToMinutes': clampedPlayBlockedToMinutes,
        'hardTrainerProgressGateEnabled': hardTrainerProgressGateEnabled,
        if (parentPasswordPrimary != null)
          'parentPasswordPrimary': parentPasswordPrimary,
        if (parentPasswordBackup != null)
          'parentPasswordBackup': parentPasswordBackup,
        if (parentRecoveryQuestion != null)
          'parentRecoveryQuestion': parentRecoveryQuestion,
        if (parentRecoveryAnswer != null)
          'parentRecoveryAnswer': parentRecoveryAnswer,
        if (lastOpenedTrainerId != null)
          'lastOpenedTrainerId': lastOpenedTrainerId,
      };
}
