/// Режим движения слогов на поле.
abstract final class RsvpMovementMode {
  static const snake = 1;
  static const chaos = 2;

  static const all = [snake, chaos];

  static String label(int modeId) {
    switch (modeId) {
      case chaos:
        return 'Суматоха';
      default:
        return 'Змейка';
    }
  }
}
