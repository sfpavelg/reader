import 'package:flutter/material.dart';

import '../gamification/play_time_guard.dart';
import '../gamification/trainer_daily_unlock.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stars_balance_chip.dart';
import '../content/math_trainers_catalog.dart';

/// Раздел «Считайка»: путь от счёта к таблице умножения.
class MathSectionScreen extends StatefulWidget {
  const MathSectionScreen({super.key});

  @override
  State<MathSectionScreen> createState() => _MathSectionScreenState();
}

class _MathSectionScreenState extends State<MathSectionScreen>
    with TrainerStarsMixin {
  bool _tableUnlocked = false;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    _tableUnlocked = TrainerDailyUnlock.isMultiplicationTableUnlocked();
  }

  void _refreshUnlock() {
    setState(() {
      _tableUnlocked = TrainerDailyUnlock.isMultiplicationTableUnlocked();
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
    reloadTrainerStars();
    _refreshUnlock();
  }

  Future<void> _onTableTap(Widget Function() builder) async {
    if (_tableUnlocked) {
      await _open(builder());
      return;
    }
    await AppFeedback.softHint();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TrainerDailyUnlock.multiplicationTableLockedMessage()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Считайка'),
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
                'От простого счёта к таблице умножения',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: MathTrainersCatalog.entries.length,
                  itemBuilder: (context, index) {
                    final entry = MathTrainersCatalog.entries[index];
                    final locked = entry.isTable && !_tableUnlocked;
                    return _MathTrainerCard(
                      icon: entry.icon,
                      label: entry.label,
                      subtitle: locked
                          ? 'Сначала все упражнения выше'
                          : entry.subtitle,
                      highlighted: entry.isTable,
                      locked: locked,
                      onTap: () => entry.isTable
                          ? _onTableTap(entry.builder)
                          : _open(entry.builder()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MathTrainerCard extends StatelessWidget {
  const _MathTrainerCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = locked
        ? colors.outline.withValues(alpha: 0.35)
        : highlighted
            ? colors.primary
            : colors.primary.withValues(alpha: 0.35);
    final bg = locked
        ? colors.surfaceContainerHighest.withValues(alpha: 0.55)
        : highlighted
            ? colors.primaryContainer.withValues(alpha: 0.65)
            : colors.primaryContainer.withValues(alpha: 0.45);

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: highlighted && !locked ? 2.5 : 2,
              ),
              color: bg,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 36,
                        color: locked
                            ? colors.onSurfaceVariant
                            : colors.primary,
                      ),
                      if (locked)
                        Positioned(
                          right: -10,
                          top: -6,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: locked ? colors.onSurfaceVariant : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
