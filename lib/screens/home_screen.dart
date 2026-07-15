import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/play_time_guard.dart';
import '../gamification/rewards_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/parent_gate.dart';
import '../widgets/pet_avatar.dart';
import 'math_section_screen.dart';
import 'pet_screen.dart';
import 'reading_section_screen.dart';
import 'parent_control_screen.dart';
import 'settings_screen.dart';
import 'sticker_album_screen.dart';

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
    if (!await PlayTimeGuard.ensurePlayAllowed(context)) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    _reload();
  }

  Future<void> _openSettings() async {
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    if (mounted) widget.onThemeChanged?.call();
  }

  Future<void> _openParentControl() async {
    await AppFeedback.tap();
    if (!mounted) return;
    final ok = await ParentGate.show(context);
    if (!mounted || !ok) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ParentControlScreen()),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обучайка'),
        actions: [
          IconButton(
            tooltip: 'Родительский контроль',
            icon: const Icon(Icons.family_restroom),
            onPressed: _openParentControl,
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
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
                onAlbum: () => _open(const StickerAlbumScreen()),
              ),
              const SizedBox(height: 20),
              Text(
                'Выбери раздел',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _SectionCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Читайка',
                        subtitle: 'Тренажёры чтения',
                        onTap: () => _open(const ReadingSectionScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _SectionCard(
                        icon: Icons.calculate_outlined,
                        label: 'Считайка',
                        subtitle: 'Счёт и таблица умножения',
                        onTap: () => _open(const MathSectionScreen()),
                      ),
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
    required this.onAlbum,
  });

  final int stars;
  final PetState pet;
  final int minutesToday;
  final VoidCallback onPet;
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
                  Text(
                    '⭐ $stars',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    RewardsService.dailyMinutesStatus(minutesToday),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Карта (скоро)',
              onPressed: null,
              icon: Icon(
                Icons.map_outlined,
                color: Theme.of(context).disabledColor,
              ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.35),
              width: 2,
            ),
            color: colors.primaryContainer.withValues(alpha: 0.4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 56, color: colors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
