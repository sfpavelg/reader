/// Три скорости бегущей строки — у каждой свой счётчик попыток и трафарет.
abstract final class RsvpSpeed {
  static const slow = 1;
  static const medium = 2;
  static const fast = 3;

  static const all = [slow, medium, fast];

  static String label(int speedId) {
    switch (speedId) {
      case fast:
        return 'Быстро';
      case medium:
        return 'Средне';
      default:
        return 'Медленно';
    }
  }

  /// Слогов в минуту для отображения.
  static int syllablesPerMinute(int speedId) {
    switch (speedId) {
      case fast:
        return 75;
      case medium:
        return 50;
      default:
        return 32;
    }
  }

  static Duration intervalForSpeed(int speedId) {
    final spm = syllablesPerMinute(speedId).clamp(20, 120);
    return Duration(milliseconds: (60000 / spm).round());
  }
}
