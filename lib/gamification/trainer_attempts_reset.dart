import '../app/trainer_ids.dart';
import '../data/hive/local_storage.dart';
import 'trainer_stencil_progress.dart';

/// Сброс дневных попыток во всех тренажёрах (родительский контроль).
abstract final class TrainerAttemptsReset {
  TrainerAttemptsReset._();

  static const storageKeys = [
    'rsvp_shared',
    'bookmark_window_shared',
    'syllable_builder_shared',
    'schulte_shared',
    'tachistoscope_shared',
    'ugadayka_shared',
    '${TrainerIds.mathCounting}_shared',
    '${TrainerIds.mathAddition10}_shared',
    '${TrainerIds.mathAddition20}_shared',
    '${TrainerIds.mathSubtraction10}_shared',
    '${TrainerIds.mathMissing}_shared',
    '${TrainerIds.mathDoubles}_shared',
    '${TrainerIds.mathGroups}_shared',
    '${TrainerIds.mathMultiplyRow}_shared',
    '${TrainerIds.mathMultiplyMix}_shared',
  ];

  static Future<void> resetAll() async {
    if (!LocalStorage.isReady) return;

    final today = TrainerStencilProgressStore.todayKey();
    for (final key in storageKeys) {
      final raw = LocalStorage.readTrainerExtra(key);
      if (raw == null) continue;

      final reset = TrainerStencilProgress.fromMap(raw).resetAttempts(
        dateKey: today,
      );
      await LocalStorage.writeTrainerExtra(key, reset.toMap());
    }
  }
}
