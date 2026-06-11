import 'package:flutter/services.dart';

import '../services/sound_service.dart';

/// Тактильный и звуковой отклик без «наказания» за ошибку.
abstract final class AppFeedback {
  static Future<void> tap() async {
    HapticFeedback.lightImpact();
    await SoundService.click();
  }

  static Future<void> success() async {
    HapticFeedback.lightImpact();
    await SoundService.success();
  }

  static Future<void> softHint() async {
    HapticFeedback.selectionClick();
    await SoundService.hint();
  }
}
