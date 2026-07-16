import 'package:flutter/material.dart';

import '../../content/fairytale_catalog.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/fairytale_progress.dart';
import '../../gamification/rewards_service.dart';
import '../../widgets/app_feedback.dart';
import 'fairytale_detail_screen.dart';

/// Список сказок — главы открываются за звёзды.
class FairytalesSectionScreen extends StatefulWidget {
  const FairytalesSectionScreen({super.key});

  @override
  State<FairytalesSectionScreen> createState() =>
      _FairytalesSectionScreenState();
}

class _FairytalesSectionScreenState extends State<FairytalesSectionScreen> {
  FairytaleProgress _progress = const FairytaleProgress();
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _progress = LocalStorage.isReady
          ? LocalStorage.readFairytaleProgress()
          : const FairytaleProgress();
      _stars = LocalStorage.isReady ? RewardsService.availableStars() : 0;
    });
  }

  int _unlockedCount(Fairytale tale) {
    var n = 0;
    for (final chapter in tale.chapters) {
      if (_progress.isChapterUnlocked(chapter.id)) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сказки'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '⭐ $_stars',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: FairytaleCatalog.tales.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tale = FairytaleCatalog.tales[index];
          final unlocked = _unlockedCount(tale);
          return Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await AppFeedback.tap();
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => FairytaleDetailScreen(taleId: tale.id),
                  ),
                );
                _reload();
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: colors.primaryContainer.withValues(alpha: 0.35),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _TaleBadge(emoji: tale.emoji),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tale.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tale.blurb,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Глав: $unlocked из ${tale.chapters.length} · '
                              '${Fairytale.chapterStarCost} ⭐ / глава',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaleBadge extends StatelessWidget {
  const _TaleBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
