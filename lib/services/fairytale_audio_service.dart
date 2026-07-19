import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Воспроизведение длинных озвучек сказок (отдельно от коротких SFX).
class FairytaleAudioService {
  FairytaleAudioService._();

  static final AudioPlayer player = AudioPlayer();

  /// Готовит источник без автозапуска (ребёнок жмёт «Слушать» сам).
  /// Возвращает длительность, если удалось её получить (для ползунка).
  static Future<Duration?> prepareAsset(String assetPath) async {
    final assetKey = 'assets/$assetPath';
    final data = await rootBundle.load(assetKey);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await player.stop();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(1);

    try {
      await player.setSource(AssetSource(assetPath));
    } catch (_) {
      try {
        await player.setSource(BytesSource(bytes));
      } catch (_) {
        final file = File(
          '${Directory.systemTemp.path}/${assetPath.replaceAll('/', '_')}',
        );
        await file.writeAsBytes(bytes, flush: true);
        await player.setSource(DeviceFileSource(file.path));
      }
    }

    // На Android длительность часто появляется только после короткого prepare.
    return _warmDuration();
  }

  static Future<Duration?> _warmDuration() async {
    var duration = await player.getDuration();
    if (duration != null && duration > Duration.zero) return duration;

    try {
      await player.setVolume(0);
      await player.resume();
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        duration = await player.getDuration();
        if (duration != null && duration > Duration.zero) break;
      }
      await player.pause();
      await player.seek(Duration.zero);
    } catch (_) {
      // ignore — UI возьмёт duration из каталога
    } finally {
      try {
        await player.setVolume(1);
      } catch (_) {}
    }
    return duration;
  }

  static Future<void> playPrepared() async {
    await player.setVolume(1);
    await player.resume();
  }

  static Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  static Future<void> stop() async {
    try {
      await player.stop();
    } catch (_) {}
  }
}
