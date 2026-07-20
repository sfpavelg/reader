import 'package:flutter/material.dart';

import '../../content/coloring_catalog.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/coloring_progress.dart';
import '../../gamification/rewards_service.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/stars_balance_chip.dart';
import 'coloring_paint_screen.dart';

class ColoringAlbumScreen extends StatefulWidget {
  const ColoringAlbumScreen({super.key});

  @override
  State<ColoringAlbumScreen> createState() => _ColoringAlbumScreenState();
}

class _ColoringAlbumScreenState extends State<ColoringAlbumScreen>
    with TrainerStarsMixin {
  late ColoringProgress _progress;
  String _themeId = ColoringCatalog.themes.first.id;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    _reload();
  }

  void _reload() {
    _progress = LocalStorage.isReady
        ? LocalStorage.readColoringProgress()
        : const ColoringProgress();
  }

  ColoringTheme get _theme => ColoringCatalog.themeById(_themeId);

  Future<void> _openPage(ColoringPage page) async {
    final unlocked = _progress.isUnlocked(page.id);
    if (!unlocked) {
      await _tryUnlock(page);
      return;
    }
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ColoringPaintScreen(pageId: page.id),
      ),
    );
    if (!mounted) return;
    setState(() {
      _reload();
      reloadTrainerStars();
    });
  }

  Future<void> _tryUnlock(ColoringPage page) async {
    final cost = ColoringCatalog.starCost;
    if (trainerStars < cost) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нужно $cost ★. Сейчас у тебя $trainerStars.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Открыть раскраску?'),
        content: Text(
          '«${_theme.title}: ${page.title}» за $cost ★.\n'
          'У тебя сейчас: $trainerStars ★.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await RewardsService.unlockColoringPage(
      pageId: page.id,
      starCost: cost,
    );
    if (!mounted) return;
    if (!ok) {
      await AppFeedback.softHint();
      return;
    }

    await AppFeedback.success();
    reloadTrainerStars();
    setState(_reload);
    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ColoringPaintScreen(pageId: page.id),
      ),
    );
    if (!mounted) return;
    setState(() {
      _reload();
      reloadTrainerStars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pages = ColoringCatalog.pagesForTheme(_themeId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                _theme.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Тематика',
              initialValue: _themeId,
              onSelected: (id) {
                setState(() => _themeId = id);
              },
              itemBuilder: (ctx) => [
                for (final theme in ColoringCatalog.themes)
                  PopupMenuItem(
                    value: theme.id,
                    child: Row(
                      children: [
                        Text(theme.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(theme.title),
                        if (theme.id == _themeId) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 18, color: colors.primary),
                        ],
                      ],
                    ),
                  ),
              ],
              child: Icon(
                Icons.arrow_drop_down_rounded,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StarsBalanceChip(stars: trainerStars, compact: true),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          final unlocked = _progress.isUnlocked(page.id);
          return _PageTile(
            page: page,
            themeEmoji: _theme.emoji,
            unlocked: unlocked,
            onTap: () => _openPage(page),
          );
        },
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.themeEmoji,
    required this.unlocked,
    required this.onTap,
  });

  final ColoringPage page;
  final String themeEmoji;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: unlocked
          ? colors.primaryContainer.withValues(alpha: 0.55)
          : colors.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (page.isImagePage)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: unlocked
                            ? Image.asset(
                                page.imageAsset!,
                                fit: BoxFit.contain,
                              )
                            : ColorFiltered(
                                colorFilter: const ColorFilter.matrix(<double>[
                                  0.3, 0.59, 0.11, 0, 0,
                                  0.3, 0.59, 0.11, 0, 0,
                                  0.3, 0.59, 0.11, 0, 0,
                                  0, 0, 0, 0.55, 0,
                                ]),
                                child: Image.asset(
                                  page.imageAsset!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      if (!unlocked)
                        const Align(
                          alignment: Alignment.center,
                          child: Text('🔒', style: TextStyle(fontSize: 28)),
                        ),
                    ],
                  ),
                )
              else
                Text(
                  unlocked ? themeEmoji : '🔒',
                  style: const TextStyle(fontSize: 40),
                ),
              const SizedBox(height: 8),
              Text(
                page.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (!unlocked)
                StarPriceLabel(
                  amount: ColoringCatalog.starCost,
                  dense: true,
                )
              else
                Text(
                  'Открыто',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
