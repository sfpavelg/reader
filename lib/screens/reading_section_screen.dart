import 'package:flutter/material.dart';

import '../gamification/play_time_guard.dart';
import '../gamification/trainer_daily_unlock.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stars_balance_chip.dart';
import 'trainers/bookmark_window_screen.dart';
import 'trainers/rsvp_screen.dart';
import 'trainers/schulte_screen.dart';
import 'trainers/syllable_builder_screen.dart';
import 'trainers/tachistoscope_screen.dart';
import 'trainers/ugadayka_screen.dart';

class ReadingSectionScreen extends StatefulWidget {
  const ReadingSectionScreen({super.key});

  @override
  State<ReadingSectionScreen> createState() => _ReadingSectionScreenState();
}

class _ReadingSectionScreenState extends State<ReadingSectionScreen>
    with TrainerStarsMixin {
  bool _bookmarkUnlocked = false;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    _bookmarkUnlocked = TrainerDailyUnlock.isBookmarkWindowUnlocked();
  }

  void _refreshUnlock() {
    setState(() {
      _bookmarkUnlocked = TrainerDailyUnlock.isBookmarkWindowUnlocked();
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

  Future<void> _onBookmarkTap() async {
    if (_bookmarkUnlocked) {
      await _open(const BookmarkWindowScreen());
      return;
    }
    await AppFeedback.softHint();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TrainerDailyUnlock.bookmarkWindowLockedMessage()),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      icon: Icons.flash_on,
                      label: 'Вспышка',
                      onTap: () => _open(const TachistoscopeScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.grid_on,
                      label: 'Собирайка',
                      onTap: () => _open(const SchulteScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.layers_outlined,
                      label: 'Угадайка',
                      onTap: () => _open(const UgadaykaScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.pan_tool_alt,
                      label: 'Ловец',
                      onTap: () => _open(const SyllableBuilderScreen()),
                    ),
                    _TrainerCard(
                      icon: Icons.crop_free,
                      label: 'Слогоменяйка',
                      locked: !_bookmarkUnlocked,
                      onTap: _onBookmarkTap,
                    ),
                    _TrainerCard(
                      iconWidget: const _SnakeMenuIcon(),
                      label: 'Змейка',
                      onTap: () => _open(const RsvpScreen()),
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
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.locked = false,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leading = iconWidget ??
        Icon(
          icon,
          size: 40,
          color: locked ? colors.onSurfaceVariant : colors.primary,
        );

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: locked ? 0.2 : 0.35),
                width: 2,
              ),
              color: colors.primaryContainer.withValues(alpha: 0.45),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      leading,
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
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: locked ? colors.onSurfaceVariant : null,
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

class _SnakeMenuIcon extends StatelessWidget {
  const _SnakeMenuIcon();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    const size = 40.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SnakeIconPainter(color: color),
      ),
    );
  }
}

class _SnakeIconPainter extends CustomPainter {
  const _SnakeIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.78, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.04,
        size.width * 0.16,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.06,
        size.height * 0.74,
        size.width * 0.52,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.96,
        size.width * 0.72,
        size.height * 0.58,
      );

    canvas.drawPath(path, body);

    final head = Paint()..color = color;
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.16),
      size.width * 0.07,
      head,
    );
    canvas.drawCircle(
      Offset(size.width * 0.81, size.height * 0.13),
      size.width * 0.018,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _SnakeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
