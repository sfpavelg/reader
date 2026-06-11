import 'package:flutter/material.dart';

import '../widgets/app_feedback.dart';
import 'rewards_service.dart';

Future<RewardGrantResult?> grantTrainerReward(
  BuildContext context, {
  required String trainerId,
  int stars = 1,
  bool showSnackBar = true,
}) async {
  final result = await RewardsService.grantTrainerSuccess(
    trainerId: trainerId,
    stars: stars,
  );

  if (!context.mounted) return result;

  if (result.dailyLimitReached) {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.nightlight_round, color: colors.primary, size: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Тренировка окончена', textAlign: TextAlign.center),
          content: const Text(
            'Сегодня уже 15 минут — отличная работа! '
            'Приходи завтра, глазам нужен отдых.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Хорошо'),
            ),
          ],
        );
      },
    );
    return result;
  }

  if (result.starsEarned > 0 && showSnackBar) {
    await AppFeedback.success();
    if (!context.mounted) return result;
    final parts = <String>['+${result.starsEarned} ⭐'];
    if (result.petStageChanged) {
      parts.add('Питомец вырос!');
    }
    if (result.worldNodeUnlocked) {
      parts.add('Шаг на карте 🗺️');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.join('  '), textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  return result;
}
