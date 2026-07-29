import 'package:flutter/material.dart';

import '../app/section_ids.dart';
import '../data/hive/local_storage.dart';
import '../widgets/app_feedback.dart';

/// Проверка родительской блокировки раздела.
abstract final class SectionAccessGuard {
  static bool isSectionBlocked(String sectionId) {
    if (!LocalStorage.isReady) return false;
    return LocalStorage.readSettings().isSectionBlocked(sectionId);
  }

  static Future<bool> ensureAllowed(
    BuildContext context,
    String sectionId,
  ) async {
    if (!isSectionBlocked(sectionId)) return true;
    if (!context.mounted) return false;

    await AppFeedback.softHint();
    if (!context.mounted) return false;

    final title = SectionIds.title(sectionId);
    final colors = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_outline, color: colors.primary, size: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$title закрыт', textAlign: TextAlign.center),
        content: const Text(
          'Родитель закрыл этот раздел.\n'
          'Попроси открыть его в родительском контроле.',
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
