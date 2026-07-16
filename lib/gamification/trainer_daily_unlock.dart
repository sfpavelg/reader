import '../app/trainer_ids.dart';
import '../data/hive/local_storage.dart';
import '../trainers/rsvp/rsvp_speed.dart';
import '../trainers/syllable_builder/syllable_builder_level.dart';
import 'trainer_stencil_progress.dart';

/// Дневная разблокировка сложных тренажёров после исчерпания попыток
/// на всех предыдущих упражнениях раздела.
abstract final class TrainerDailyUnlock {
  TrainerDailyUnlock._();

  static const schulteLimit = 20;
  static const tachistoscopeLimit = 20;
  static const rsvpLimit = 20;
  static const syllableBuilderLimit = 40;
  static const mathTrainerLimit = 20;

  static const tachistoscopeLevels = [1, 2, 3];

  static bool get _gateEnabled {
    if (!LocalStorage.isReady) return true;
    return LocalStorage.readSettings().hardTrainerProgressGateEnabled;
  }

  /// Слогоменяйка: после Собирайки, Вспышки, Змейки и Ловца.
  static bool isBookmarkWindowUnlocked() {
    if (!_gateEnabled) return true;
    return _isExhausted('schulte_shared', schulteLimit) &&
        _isExhausted(
          'tachistoscope_shared',
          tachistoscopeLimit,
          levelIds: tachistoscopeLevels,
        ) &&
        _isExhausted(
          'rsvp_shared',
          rsvpLimit,
          levelIds: RsvpSpeed.all,
        ) &&
        _isExhausted(
          'syllable_builder_shared',
          syllableBuilderLimit,
          levelIds: SyllableBuilderLevel.all,
        );
  }

  /// Таблица умножения: после всех упражнений до неё.
  static bool isMultiplicationTableUnlocked() {
    if (!_gateEnabled) return true;
    const keys = [
      TrainerIds.mathCounting,
      TrainerIds.mathAddition10,
      TrainerIds.mathAddition20,
      TrainerIds.mathSubtraction10,
      TrainerIds.mathMissing,
      TrainerIds.mathDoubles,
      TrainerIds.mathGroups,
    ];
    return keys.every(
      (id) => _isExhausted('${id}_shared', mathTrainerLimit),
    );
  }

  static String bookmarkWindowLockedMessage() =>
      'Сначала закончи попытки в Собирайке, Вспышке, Змейке и Ловце — '
      'тогда откроется Слогоменяйка.';

  static String multiplicationTableLockedMessage() =>
      'Сначала закончи попытки во всех упражнениях до таблицы — '
      'тогда откроется таблица умножения.';

  /// Для тренажёров без уровней — исчерпан общий лимит.
  /// Для тренажёров с уровнями — суммарно потрачен один дневной лимит
  /// (как у упражнения без вкладок).
  static bool _isExhausted(
    String storageKey,
    int dailyAttemptLimit, {
    List<int>? levelIds,
  }) {
    final progress = TrainerStencilProgressStore(
      storageKey: storageKey,
      dailyAttemptLimit: dailyAttemptLimit,
    ).load();

    if (levelIds == null || levelIds.isEmpty) {
      return !progress.hasAttemptsLeft;
    }

    final used = levelIds.fold<int>(
      0,
      (sum, id) => sum + progress.attemptsUsedForLevel(id),
    );
    return used >= dailyAttemptLimit;
  }
}
