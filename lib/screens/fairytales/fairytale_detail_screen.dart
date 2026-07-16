import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/fairytale_catalog.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/fairytale_progress.dart';
import '../../gamification/rewards_service.dart';
import '../../widgets/app_feedback.dart';

class FairytaleDetailScreen extends StatefulWidget {
  const FairytaleDetailScreen({super.key, required this.taleId});

  final String taleId;

  @override
  State<FairytaleDetailScreen> createState() => _FairytaleDetailScreenState();
}

class _FairytaleDetailScreenState extends State<FairytaleDetailScreen> {
  FairytaleProgress _progress = const FairytaleProgress();
  int _stars = 0;

  Fairytale? get _tale => FairytaleCatalog.byId(widget.taleId);

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

  Future<void> _openOrUnlock(FairytaleChapter chapter) async {
    final unlocked = _progress.isChapterUnlocked(chapter.id);
    if (unlocked) {
      await AppFeedback.success();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(chapter.title),
          content: Text(
            '${chapter.synopsis}\n\n'
            'Аудиодорожка появится здесь позже. '
            'Пока можно читать краткое содержание главы.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Хорошо'),
            ),
          ],
        ),
      );
      return;
    }

    final cost = Fairytale.chapterStarCost;
    if (_stars < cost) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нужно $cost ⭐. Сейчас у тебя $_stars.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Открыть главу?'),
        content: Text(
          '«${chapter.title}» откроется за $cost ⭐.\n'
          'У тебя сейчас: $_stars ⭐.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Открыть · $cost ⭐'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await RewardsService.unlockFairytaleChapter(
      chapterId: chapter.id,
      starCost: cost,
    );
    if (!mounted) return;
    if (!ok) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть главу')),
      );
      return;
    }
    await AppFeedback.success();
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Глава «${chapter.title}» открыта!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tale = _tale;
    if (tale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сказка')),
        body: const Center(child: Text('Сказка не найдена')),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tale.title),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(tale.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tale.author,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(tale.blurb),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Каждая глава — ${Fairytale.chapterStarCost} ⭐. '
            'Аудио добавим позже.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < tale.chapters.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ChapterTile(
              index: i + 1,
              chapter: tale.chapters[i],
              unlocked: _progress.isChapterUnlocked(tale.chapters[i].id),
              onTap: () => unawaited(_openOrUnlock(tale.chapters[i])),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.unlocked,
    required this.onTap,
  });

  final int index;
  final FairytaleChapter chapter;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: unlocked
          ? colors.primaryContainer.withValues(alpha: 0.55)
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                child: Text(
                  unlocked ? '▶' : '$index',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      unlocked
                          ? chapter.synopsis
                          : 'Закрыто · ${Fairytale.chapterStarCost} ⭐',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.headphones_rounded : Icons.lock_outline,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
