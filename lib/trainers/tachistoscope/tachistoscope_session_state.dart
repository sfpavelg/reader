/// Адаптивная длительность вспышки для микро-сессии тахистоскопа.
///
/// Старт: 2.0 с. После 3 верных подряд −0.2 с. При ошибке +0.2 с.
/// Диапазон: 0.5–2.0 с. Прогресс микро-сессии не сбрасывается при выходе
/// с экрана — сохраняется отдельно через [TachistoscopeTrainerProgress].
class TachistoscopeSessionState {
  const TachistoscopeSessionState({
    this.flashDurationMs = 2000,
    this.correctStreak = 0,
    this.tasksCompleted = 0,
    this.correctAnswers = 0,
  });

  static const int minFlashMs = 500;
  static const int maxFlashMs = 2000;
  static const int streakStepMs = 200;
  static const int streakThreshold = 3;

  final int flashDurationMs;
  final int correctStreak;
  final int tasksCompleted;
  final int correctAnswers;

  Duration get flashDuration => Duration(milliseconds: flashDurationMs);

  TachistoscopeSessionState registerAnswer({required bool isCorrect}) {
    if (isCorrect) {
      final nextStreak = correctStreak + 1;
      final faster = nextStreak >= streakThreshold;
      return TachistoscopeSessionState(
        flashDurationMs: faster
            ? (flashDurationMs - streakStepMs).clamp(minFlashMs, maxFlashMs)
            : flashDurationMs,
        correctStreak: faster ? 0 : nextStreak,
        tasksCompleted: tasksCompleted + 1,
        correctAnswers: correctAnswers + 1,
      );
    }

    return TachistoscopeSessionState(
      flashDurationMs:
          (flashDurationMs + streakStepMs).clamp(minFlashMs, maxFlashMs),
      correctStreak: 0,
      tasksCompleted: tasksCompleted + 1,
      correctAnswers: correctAnswers,
    );
  }

  TachistoscopeSessionState copyWithFlash(Duration duration) {
    return TachistoscopeSessionState(
      flashDurationMs: duration.inMilliseconds.clamp(minFlashMs, maxFlashMs),
      correctStreak: correctStreak,
      tasksCompleted: tasksCompleted,
      correctAnswers: correctAnswers,
    );
  }
}
