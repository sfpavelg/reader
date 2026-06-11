import '../../app/trainer_ids.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';
import 'tachistoscope_session_state.dart';

/// Сохранение микро-сессии тахистоскопа в Hive (выход без потери прогресса).
class TachistoscopeSessionStore {
  TachistoscopeSessionStore._();

  static const _trainerId = TrainerIds.tachistoscope;
  static const _recentCap = 6;

  static TachistoscopeSessionState loadSession(int levelId) {
    final snap = LocalStorage.readMicroSession(_trainerId);
    if (snap == null || snap.levelId != levelId) {
      return const TachistoscopeSessionState();
    }
    final p = TachistoscopeTrainerProgress.fromMap(snap.payload);
    return TachistoscopeSessionState(
      flashDurationMs: p.flashDurationMs,
      correctStreak: p.correctStreak,
      tasksCompleted: p.tasksCompleted,
      correctAnswers: p.correctAnswers,
    );
  }

  static List<String> loadRecentTargetIds(int levelId) {
    final snap = LocalStorage.readMicroSession(_trainerId);
    if (snap == null || snap.levelId != levelId) return const [];
    return TachistoscopeTrainerProgress.fromMap(snap.payload).recentTargetIds;
  }

  static Future<void> persist({
    required int levelId,
    required TachistoscopeSessionState session,
    required List<String> recentTargetIds,
  }) async {
    final payload = TachistoscopeTrainerProgress(
      flashDurationMs: session.flashDurationMs,
      correctStreak: session.correctStreak,
      tasksCompleted: session.tasksCompleted,
      correctAnswers: session.correctAnswers,
      recentTargetIds: recentTargetIds,
    );

    await LocalStorage.writeMicroSession(
      MicroSessionSnapshot(
        trainerId: _trainerId,
        levelId: levelId,
        payload: payload.toMap(),
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final existing = LocalStorage.readTrainerProgress(_trainerId);
    final progress = (existing ??
            const TrainerProgress(trainerId: _trainerId))
        .copyWith(
      totalTasks: session.tasksCompleted,
      totalCorrect: session.correctAnswers,
      lastPlayedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalStorage.writeTrainerProgress(progress);
  }

  static List<String> bumpRecent(List<String> current, String targetId) {
    final next = [targetId, ...current.where((id) => id != targetId)];
    if (next.length > _recentCap) {
      return next.sublist(0, _recentCap);
    }
    return next;
  }
}
