/// Имена Hive-боксов. Один бокс — одна предметная область.
abstract final class HiveBoxes {
  static const settings = 'settings';
  static const profile = 'profile';
  static const trainers = 'trainers';
  static const pet = 'pet';
  static const stickers = 'stickers';
  static const worldMap = 'world_map';
  static const sessions = 'sessions';
}

/// Ключи записей внутри боксов (key-value).
abstract final class HiveKeys {
  static const appSettings = 'app_settings';
  static const userProfile = 'user_profile';
  static const petState = 'pet_state';
  static const stickerAlbum = 'sticker_album';
  static const fairytaleProgress = 'fairytale_progress';
  static const worldMapProgress = 'world_map_progress';
  static const dailySession = 'daily_session';

  static String trainerProgress(String trainerId) => 'trainer_$trainerId';
  static String microSession(String trainerId) => 'micro_session_$trainerId';
  static String trainerExtra(String key) => 'trainer_extra_$key';
}
