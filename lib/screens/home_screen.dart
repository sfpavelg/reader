import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/rewards_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/parent_gate.dart';
import '../widgets/pet_avatar.dart';
import 'pet_screen.dart';
import 'settings_screen.dart';
import 'sticker_album_screen.dart';
import 'trainers/bookmark_window_screen.dart';
import 'trainers/rsvp_screen.dart';
import 'trainers/schulte_screen.dart';
import 'trainers/syllable_builder_screen.dart';
import 'trainers/tachistoscope_screen.dart';
import 'world_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onThemeChanged});

  final VoidCallback? onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stars = 0;
  PetState _pet = const PetState();
  int _minutesToday = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    if (!LocalStorage.isReady) {
      setState(() {
        _stars = 0;
        _pet = const PetState();
        _minutesToday = 0;
      });
      return;
    }
    setState(() {
      _stars = LocalStorage.readProfile().totalStars;
      _pet = LocalStorage.readPet();
      _minutesToday = RewardsService.minutesPlayedToday();
    });
  }

  Future<void> _open(Widget screen) async {
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          IconButton(
            tooltip: 'Для взрослых',
            icon: const Icon(Icons.family_restroom),
            onPressed: () async {
              await AppFeedback.tap();
              if (!context.mounted) return;
              final ok = await ParentGate.show(context);
              if (!context.mounted) return;
              if (!ok) return;
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              if (mounted) {
                _reload();
                widget.onThemeChanged?.call();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GamificationHeader(
                stars: _stars,
                pet: _pet,
                minutesToday: _minutesToday,
                onPet: () => _open(const PetScreen()),
                onMap: () => _open(const WorldMapScreen()),
                onAlbum: () => _open(const StickerAlbumScreen()),
              ),
              const SizedBox(height: 16),
              Text(
                'Выбери упражнение',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  children: [
                    _TrainerCard(
                      icon: Icons.grid_on,
                      label: 'Шульте',
                      onTap: () => _open(const SchulteScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.flash_on,
                      label: 'Вспышки',
                      onTap: () => _open(const TachistoscopeScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.play_circle_outline,
                      label: 'Бегущая строка',
                      onTap: () => _open(const RsvpScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.extension,
                      label: 'Слоги',
                      onTap: () => _open(const SyllableBuilderScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.crop_free,
                      label: 'Окошко',
                      onTap: () => _open(const BookmarkWindowScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GamificationHeader extends StatelessWidget {
  const _GamificationHeader({
    required this.stars,
    required this.pet,
    required this.minutesToday,
    required this.onPet,
    required this.onMap,
    required this.onAlbum,
  });

  final int stars;
  final PetState pet;
  final int minutesToday;
  final VoidCallback onPet;
  final VoidCallback onMap;
  final VoidCallback onAlbum;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            InkWell(
              onTap: onPet,
              borderRadius: BorderRadius.circular(12),
              child: PetAvatar(pet: pet, size: 56, showLabel: false),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⭐ $stars', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    'Сегодня: $minutesToday / ${RewardsService.dailyMinuteLimit} мин',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Карта',
              onPressed: onMap,
              icon: const Icon(Icons.map_outlined),
            ),
            IconButton(
              tooltip: 'Наклейки',
              onPressed: onAlbum,
              icon: const Icon(Icons.collections_bookmark_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.35),
              width: 2,
            ),
            color: colors.primaryContainer.withValues(alpha: 0.45),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
