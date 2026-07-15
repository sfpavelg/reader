import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/app_settings.dart';
import '../widgets/app_feedback.dart';

/// Проверка родительского ограничения «когда нельзя играть».
abstract final class PlayTimeGuard {
  static bool isPlayAllowed([DateTime? now]) {
    if (!LocalStorage.isReady) return true;
    return !LocalStorage.readSettings().isPlayBlockedAt(now ?? DateTime.now());
  }

  static Future<bool> ensurePlayAllowed(BuildContext context) async {
    if (isPlayAllowed()) return true;
    if (!context.mounted) return false;

    final settings = LocalStorage.readSettings();
    await AppFeedback.softHint();
    if (!context.mounted) return false;

    final colors = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.bedtime_outlined, color: colors.primary, size: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Время отдыха', textAlign: TextAlign.center),
        content: Text(
          'Сейчас играть нельзя (${settings.playBlockedFromLabel} — '
          '${settings.playBlockedToLabel}).\n\n'
          '${settings.allowedPlayWindowDescription}',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Хорошо'),
          ),
        ],
      ),
    );
    return false;
  }
}
