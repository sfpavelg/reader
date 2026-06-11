import 'package:flutter/material.dart';

import '../gamification/rewards_service.dart';
import '../gamification/trainer_reward_feedback.dart';
import 'app_feedback.dart';

/// Тематизированный диалог после успешного раунда.
Future<void> showTrainerCompletionDialog(
  BuildContext context, {
  required String title,
  required String message,
  RewardGrantResult? reward,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) async {
  if (!context.mounted) return;

  final colors = Theme.of(context).colorScheme;
  final rewardLines = <String>[];
  if (reward != null && reward.starsEarned > 0) {
    rewardLines.add('+${reward.starsEarned} ⭐');
    if (reward.petStageChanged) {
      rewardLines.add('Питомец вырос!');
    }
    if (reward.worldNodeUnlocked) {
      rewardLines.add('Новый шаг на карте миров 🗺️');
    }
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.celebration_outlined, color: colors.primary, size: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (rewardLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rewardLines.join('\n'),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (secondaryLabel != null && onSecondary != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSecondary();
            },
            child: Text(secondaryLabel),
          ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onPrimary();
          },
          child: Text(primaryLabel),
        ),
      ],
    ),
  );
}

/// Награда + диалог завершения (без дублирующего snackbar).
Future<RewardGrantResult?> completeTrainerRound(
  BuildContext context, {
  required String trainerId,
  required String title,
  required String message,
  int stars = 1,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) async {
  await AppFeedback.success();
  if (!context.mounted) return null;

  final result = await grantTrainerReward(
    context,
    trainerId: trainerId,
    stars: stars,
    showSnackBar: false,
  );

  if (!context.mounted) return result;
  if (result?.dailyLimitReached == true) return result;

  await showTrainerCompletionDialog(
    context,
    title: title,
    message: message,
    reward: result,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    secondaryLabel: secondaryLabel,
    onSecondary: onSecondary,
  );

  return result;
}
