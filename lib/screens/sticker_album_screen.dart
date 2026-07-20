import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../widgets/app_feedback.dart';
import '../data/hive/models/sticker_album.dart';
import '../gamification/rewards_service.dart';
import '../gamification/sticker_catalog.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/stars_balance_chip.dart';

class StickerAlbumScreen extends StatefulWidget {
  const StickerAlbumScreen({super.key});

  @override
  State<StickerAlbumScreen> createState() => _StickerAlbumScreenState();
}

class _StickerAlbumScreenState extends State<StickerAlbumScreen>
    with TrainerStarsMixin {
  late StickerAlbumState _album;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    initTrainerStars();
    _album = LocalStorage.readStickerAlbum();
    if (mounted) setState(() {});
  }

  Future<void> _unlock(StickerTheme theme, StickerDef sticker) async {
    if (_album.isUnlocked(theme.id, sticker.id)) return;

    final ok = await RewardsService.unlockSticker(
      themeId: theme.id,
      stickerId: sticker.id,
      starCost: sticker.starCost,
    );

    if (!mounted) return;

    if (!ok) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нужно больше звёзд ⭐', textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await AppFeedback.success();
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Открыта наклейка ${sticker.emoji}',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StickerCatalog.themes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Альбом наклеек'),
          bottom: TabBar(
            tabs: [for (final t in StickerCatalog.themes) Tab(text: t.title)],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TrainerStarsBar(stars: trainerStars),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final theme in StickerCatalog.themes)
                    GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      itemCount: theme.stickers.length,
                      itemBuilder: (context, index) {
                        final sticker = theme.stickers[index];
                        final unlocked = _album.isUnlocked(
                          theme.id,
                          sticker.id,
                        );
                        final canAfford = trainerStars >= sticker.starCost;

                        return Material(
                          color: unlocked
                              ? Theme.of(context).colorScheme.primaryContainer
                              : canAfford
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: unlocked
                                ? null
                                : () => _unlock(theme, sticker),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  unlocked ? sticker.emoji : '🔒',
                                  style: const TextStyle(fontSize: 36),
                                ),
                                const SizedBox(height: 6),
                                if (unlocked)
                                  Text(
                                    sticker.label,
                                    textAlign: TextAlign.center,
                                  )
                                else
                                  StarPriceLabel(
                                    amount: sticker.starCost,
                                    dense: true,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
