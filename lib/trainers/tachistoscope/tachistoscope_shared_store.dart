import '../../data/hive/local_storage.dart';

/// Общий прогресс «Вспышек» на все вкладки (слоги / слова / фразы).
class TachistoscopeSharedState {
  const TachistoscopeSharedState({
    required this.dateKey,
    this.attemptsUsed = 0,
    this.stencilFilled = 0,
  });

  static const dailyAttemptLimit = 20;

  final String dateKey;
  final int attemptsUsed;
  final int stencilFilled;

  bool get hasAttemptsLeft => attemptsUsed < dailyAttemptLimit;

  int get attemptsRemaining =>
      (dailyAttemptLimit - attemptsUsed).clamp(0, dailyAttemptLimit);

  TachistoscopeSharedState registerAttempt() {
    return copyWith(attemptsUsed: attemptsUsed + 1);
  }

  TachistoscopeSharedState copyWith({
    String? dateKey,
    int? attemptsUsed,
    int? stencilFilled,
  }) {
    return TachistoscopeSharedState(
      dateKey: dateKey ?? this.dateKey,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      stencilFilled: stencilFilled ?? this.stencilFilled,
    );
  }

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'attemptsUsed': attemptsUsed,
        'stencilFilled': stencilFilled,
      };

  factory TachistoscopeSharedState.fromMap(Map<String, dynamic> map) {
    return TachistoscopeSharedState(
      dateKey: map['dateKey'] as String? ?? '',
      attemptsUsed: map['attemptsUsed'] as int? ?? 0,
      stencilFilled: map['stencilFilled'] as int? ?? 0,
    );
  }
}

/// Сохранение общего состояния тахистоскопа (попытки, трафарет звёзд).
class TachistoscopeSharedStore {
  TachistoscopeSharedStore._();

  static const _storageKey = 'tachistoscope_shared';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static TachistoscopeSharedState load() {
    if (!LocalStorage.isReady) {
      return TachistoscopeSharedState(dateKey: _todayKey());
    }

    final raw = LocalStorage.readTrainerExtra(_storageKey);
    if (raw == null) {
      return TachistoscopeSharedState(dateKey: _todayKey());
    }

    final state = TachistoscopeSharedState.fromMap(raw);
    if (state.dateKey != _todayKey()) {
      return TachistoscopeSharedState(
        dateKey: _todayKey(),
        stencilFilled: state.stencilFilled,
      );
    }
    return state;
  }

  static Future<void> persist(TachistoscopeSharedState state) async {
    if (!LocalStorage.isReady) return;
    await LocalStorage.writeTrainerExtra(_storageKey, state.toMap());
  }
}
