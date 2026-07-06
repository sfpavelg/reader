import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';

/// Недавно показанные слова — чтобы подряд не повторялись.
class RecentEntryHistory {
  RecentEntryHistory._();

  static List<String> loadRecentEntryIds(String trainerId) {
    if (!LocalStorage.isReady) return const [];
    final snap = LocalStorage.readMicroSession(trainerId);
    if (snap == null) return const [];
    final raw = snap.payload['recentEntryIds'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static String? loadLastEntryId(String trainerId) {
    final recent = loadRecentEntryIds(trainerId);
    return recent.isEmpty ? null : recent.last;
  }

  static List<String> bumpRecentIds(
    List<String> recent,
    String entryId, {
    required int cap,
  }) {
    final next = [...recent.where((id) => id != entryId), entryId];
    return next.length > cap ? next.sublist(next.length - cap) : next;
  }

  static Future<void> recordPresented(
    String trainerId,
    String entryId, {
    int levelId = 2,
    int recentCap = 40,
  }) async {
    if (!LocalStorage.isReady) return;
    final cap = recentCap.clamp(1, 999);
    final trimmed = bumpRecentIds(
      loadRecentEntryIds(trainerId),
      entryId,
      cap: cap,
    );

    await LocalStorage.writeMicroSession(
      MicroSessionSnapshot(
        trainerId: trainerId,
        levelId: levelId,
        payload: {
          'recentEntryIds': trimmed,
          'lastEntryId': entryId,
        },
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
