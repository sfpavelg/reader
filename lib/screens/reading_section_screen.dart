import 'package:flutter/material.dart';

import '../mixins/trainer_stars_mixin.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stars_balance_chip.dart';
import 'trainers/bookmark_window_screen.dart';
import 'trainers/rsvp_screen.dart';
import 'trainers/schulte_screen.dart';
import 'trainers/syllable_builder_screen.dart';
import 'trainers/tachistoscope_screen.dart';

class ReadingSectionScreen extends StatefulWidget {
  const ReadingSectionScreen({super.key});

  @override
  State<ReadingSectionScreen> createState() => _ReadingSectionScreenState();
}

class _ReadingSectionScreenState extends State<ReadingSectionScreen>
    with TrainerStarsMixin {
  @override
  void initState() {
    super.initState();
    initTrainerStars();
  }

  Future<void> _open(Widget screen) async {
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    reloadTrainerStars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Читайка'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StarsBalanceChip(stars: trainerStars, compact: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Выбери упражнение',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.28,
                  ),
                  children: [
                    _TrainerCard(
                      icon: Icons.grid_on,
                      label: 'Собери слово',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: colors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
