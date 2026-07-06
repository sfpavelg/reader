import '../../app/trainer_ids.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';
import '../common/recent_entry_history.dart';

class RsvpSessionStore {
  RsvpSessionStore._();

  static const _trainerId = TrainerIds.rsvp;
  static const _defaultRecentCap = 40;

  static List<String> loadRecentEntryIds() =>
      RecentEntryHistory.loadRecentEntryIds(_trainerId);

  static String? loadLastEntryId() =>
      RecentEntryHistory.loadLastEntryId(_trainerId);

  static Future<void> recordPresented(
    String entryId, {
    int recentCap = _defaultRecentCap,
  }) =>
      RecentEntryHistory.recordPresented(
        _trainerId,
        entryId,
        recentCap: recentCap,
      );

  static Future<void> recordCompleted(
    String entryId, {
    int recentCap = _defaultRecentCap,
  }) async {
    await recordPresented(entryId, recentCap: recentCap);

    if (!LocalStorage.isReady) return;
    final existing = LocalStorage.readTrainerProgress(_trainerId);
    await LocalStorage.writeTrainerProgress(
      (existing ?? const TrainerProgress(trainerId: _trainerId)).copyWith(
        totalTasks: (existing?.totalTasks ?? 0) + 1,
        totalCorrect: (existing?.totalCorrect ?? 0) + 1,
        lastPlayedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
