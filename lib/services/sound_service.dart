import 'package:audioplayers/audioplayers.dart';

import '../data/hive/local_storage.dart';

/// Короткие SFX (wav, моно). Без фоновой музыки по умолчанию.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _busy = false;

  static bool get enabled => LocalStorage.isReady
      ? LocalStorage.readSettings().soundEffectsEnabled
      : true;

  static Future<void> click() => _play('sounds/click.wav');

  static Future<void> success() => _play('sounds/success.wav');

  static Future<void> hint() => _play('sounds/hint.wav');

  static Future<void> _play(String asset) async {
    if (!enabled || _busy) return;
    _busy = true;
    try {
      await _player.stop();
      await _player
          .play(AssetSource(asset))
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // На эмуляторе без аудио — тихо пропускаем.
    } finally {
      _busy = false;
    }
  }
}
