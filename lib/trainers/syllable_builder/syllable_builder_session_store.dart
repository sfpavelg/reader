import '../../app/trainer_ids.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';

class SyllableBuilderSessionStore {
  SyllableBuilderSessionStore._();

  static const _trainerId = TrainerIds.syllableBuilder;
  static const _defaultRecentCap = 40;

  static List<String> loadRecentEntryIds(int trainerLevelId) {
    if (!LocalStorage.isReady) return const [];
    final snap = LocalStorage.readMicroSession(_trainerId);
    if (snap == null || snap.levelId != trainerLevelId) return const [];
    final raw = snap.payload['recentEntryIds'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static String? loadLastEntryId(int trainerLevelId) {
    final recent = loadRecentEntryIds(trainerLevelId);
    return recent.isEmpty ? null : recent.last;
  }

  static Future<void> recordCompleted(
    String entryId, {
    required int trainerLevelId,
    int recentCap = _defaultRecentCap,
  }) async {
    if (!LocalStorage.isReady) return;
    final cap = recentCap.clamp(1, 999);
    final recent = [
      ...loadRecentEntryIds(trainerLevelId).where((id) => id != entryId),
      entryId,
    ];
    final trimmed =
        recent.length > cap ? recent.sublist(recent.length - cap) : recent;

    await LocalStorage.writeMicroSession(
      MicroSessionSnapshot(
        trainerId: _trainerId,
        levelId: trainerLevelId,
        payload: {
          'recentEntryIds': trimmed,
          'lastEntryId': entryId,
        },
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

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
