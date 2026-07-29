import '../data/hive/local_storage.dart';

/// Глобальные игровые подсказки (слова-цели, кнопка «подсказка», визуалы).
abstract final class HintsPolicy {
  static bool get enabled {
    if (!LocalStorage.isReady) return true;
    return LocalStorage.readSettings().hintsEnabled;
  }

  /// За слово-цель: с подсказками — 1★, без подсказок в настройках — 2★.
  static int get targetWordStars => enabled ? 1 : 2;
}
