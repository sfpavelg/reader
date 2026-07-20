import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/play_time_guard.dart';
import '../theme/star_colors.dart';
import '../widgets/app_feedback.dart';
import '../widgets/parent_gate.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/stars_balance_chip.dart';
import 'coloring/coloring_album_screen.dart';
import 'fairytales/section_screen.dart';
import 'math_section_screen.dart';
import 'pet_screen.dart';
import 'reading_section_screen.dart';
import 'parent_control_screen.dart';
import 'settings_screen.dart';
import 'spend/spend_stub_screen.dart';
import 'sticker_album_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _stars = 0;
  PetState _pet = const PetState();

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
      });
      return;
    }
    setState(() {
      _stars = LocalStorage.readProfile().totalStars;
      _pet = LocalStorage.readPet();
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
              _InterestHeader(
                pet: _pet,
                onPet: () => _open(const PetScreen()),
                onFairytales: () => _open(const FairytalesSectionScreen()),
                onStickers: () => _open(const StickerAlbumScreen()),
                onColoring: () => _open(const ColoringAlbumScreen()),
                onMusic: () => _open(
                  const SpendStubScreen(
                    title: 'Музыкальная шкатулка',
                    emoji: '🎵',
                    description:
                        'Короткие мелодии и звуки природы. '
                        'Каждая мелодия — награда за звёзды.',
                  ),
                ),
                onToys: () => _open(
                  const SpendStubScreen(
                    title: 'Игрушки для питомца',
                    emoji: '🧸',
                    description:
                        'Мячики, бантики и домики для Колобка. '
                        'Покупай за звёзды и украшай питомца.',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Выбери раздел',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 10),
                  StarsBalanceChip(stars: _stars),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _SectionCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Читайка',
                      subtitle: 'Тренажёры чтения',
                      onTap: () => _open(const ReadingSectionScreen()),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      icon: Icons.calculate_outlined,
                      label: 'Считайка',
                      subtitle: 'Счёт и таблица умножения',
                      onTap: () => _open(const MathSectionScreen()),
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

class _InterestHeader extends StatelessWidget {
  const _InterestHeader({
    required this.pet,
    required this.onPet,
    required this.onFairytales,
    required this.onStickers,
    required this.onColoring,
    required this.onMusic,
    required this.onToys,
  });

  final PetState pet;
  final VoidCallback onPet;
  final VoidCallback onFairytales;
  final VoidCallback onStickers;
  final VoidCallback onColoring;
  final VoidCallback onMusic;
  final VoidCallback onToys;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              InkWell(
                onTap: onPet,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PetAvatar(pet: pet, size: 48, showLabel: false),
                      const SizedBox(height: 4),
                      Text(
                        'Питомец',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              _InterestChip(
                emoji: '📖',
                label: 'Сказки',
                onTap: onFairytales,
              ),
              _InterestChip(
                emoji: '🌟',
                label: 'Наклейки',
                onTap: onStickers,
                softBubble: true,
              ),
              _InterestChip(
                emoji: '🎨',
                label: 'Краски',
                onTap: onColoring,
              ),
              _InterestChip(
                emoji: '🎵',
                label: 'Музыка',
                onTap: onMusic,
              ),
              _InterestChip(
                emoji: '🧸',
                label: 'Игрушки',
                onTap: onToys,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.softBubble = false,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool softBubble;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: softBubble
                  ? Color.lerp(
                      colors.primaryContainer,
                      StarColors.currencySoft,
                      0.35,
                    )
                  : colors.primaryContainer,
              shape: const CircleBorder(),
              elevation: softBubble ? 1 : 0,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                Icon(icon, size: 44, color: colors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
