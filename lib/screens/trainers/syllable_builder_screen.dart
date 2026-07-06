import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../widgets/trainer_start_prompt.dart';
import '../../main.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../trainers/syllable_builder/syllable_builder_generator.dart';
import '../../trainers/syllable_builder/syllable_builder_layout.dart';
import '../../trainers/syllable_builder/syllable_builder_level.dart';
import '../../trainers/syllable_builder/syllable_builder_session_store.dart';
import '../../trainers/syllable_builder/syllable_builder_word_picker.dart';
import '../../trainers/syllable_builder/syllable_builder_task.dart';

class SyllableBuilderScreen extends ConsumerStatefulWidget {
  const SyllableBuilderScreen({super.key});

  @override
  ConsumerState<SyllableBuilderScreen> createState() =>
      _SyllableBuilderScreenState();
}

class _SyllableBuilderScreenState extends ConsumerState<SyllableBuilderScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _dailyAttemptLimit = 40;
  static const _sharedStorageKey = 'syllable_builder_shared';

  final _wordAssemblyKey = GlobalKey();

  int _trainerLevelId = SyllableBuilderLevel.level1;
  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;
  bool _roundActive = false;

  SyllableBuilderGenerator? _generator;
  SyllableBuilderTask? _task;
  final List<String> _pickedSyllables = [];

  Timer? _fallTimer;
  double _playAreaHeight = 400;
  final ValueNotifier<int> _fallTick = ValueNotifier(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      initTrainerStars();
      initStencilStars(
        storageKey: _sharedStorageKey,
        dailyAttemptLimit: _dailyAttemptLimit,
        perLevelAttempts: true,
      );
      syncStencilAttemptLevel(_trainerLevelId);
      _bootstrap();
    }
  }

  void _bootstrap() {
    if (!hasStencilAttemptsLeft) {
      _loaded = true;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showStencilAttemptsExhaustedDialog());
      });
      return;
    }
    _startNewTask();
    _loaded = true;
  }

  @override
  void dispose() {
    _stopFallLoop();
    _fallTick.dispose();
    super.dispose();
  }

  void _stopFallLoop() {
    _fallTimer?.cancel();
    _fallTimer = null;
  }

  void _startNewTask() {
    if (!hasStencilAttemptsLeft) return;

    _stopFallLoop();
    clearStencilFlightState();

    _generator ??= SyllableBuilderGenerator(
      dictionary: ref.read(dictionaryServiceProvider),
      trainerLevelId: _trainerLevelId,
    );
    _generator!.setTrainerLevel(_trainerLevelId);

    setState(() {
      _task = _generator!.generate();
      _pickedSyllables.clear();
      _evaluating = false;
      _roundActive = false;
    });
  }

  void _onStartRound() {
    if (!_canStartRound) return;
    unawaited(AppFeedback.tap());
    setState(() => _roundActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFallLoop();
    });
  }

  void _startFallLoop() {
    _stopFallLoop();
    _fallTimer = Timer.periodic(
      const Duration(milliseconds: SyllableBuilderLayout.tickMs),
      (_) => _onFallTick(),
    );
  }

  void _onFallTick() {
    final task = _task;
    if (task == null ||
        !mounted ||
        !_roundActive ||
        _evaluating ||
        stencilAnimating) {
      return;
    }

    const step = SyllableBuilderLayout.tickMs / 1000.0;
    final bottom = _playAreaHeight + SyllableBuilderLayout.blockHeight;

    var changed = false;
    for (final block in task.blocks) {
      if (block.collected) continue;
      block.y += SyllableBuilderLayout.fallSpeed * step;
      if (block.y > bottom) {
        block.y = SyllableBuilderLayout.respawnY(block.sequenceIndex);
      }
      changed = true;
    }

    if (changed) {
      _fallTick.value++;
    }
  }

  bool get _canStartRound =>
      !_roundActive &&
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _task != null;

  bool get _canPlay =>
      _roundActive &&
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _task != null;

  void _onBlockTap(FallingSyllableBlock block) {
    if (!_canPlay) return;
    final task = _task;
    if (task == null || block.collected) return;

    unawaited(AppFeedback.tap());
    setState(() {
      block.collected = true;
      _pickedSyllables.add(block.text);
    });

    if (_pickedSyllables.length >= task.syllableCount) {
      _stopFallLoop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_evaluateAnswer());
      });
    }
  }

  bool _isCorrectAnswer(SyllableBuilderTask task) {
    if (_pickedSyllables.length != task.syllables.length) return false;
    for (var i = 0; i < task.syllables.length; i++) {
      if (_pickedSyllables[i] != task.syllables[i]) return false;
    }
    return true;
  }

  Future<void> _evaluateAnswer() async {
    if (_evaluating) return;
    final task = _task;
    if (task == null) return;

    setState(() => _evaluating = true);
    await consumeStencilAttempt();

    final correct = _isCorrectAnswer(task);

    if (correct) {
      await SyllableBuilderSessionStore.recordCompleted(
        task.entryId,
        trainerLevelId: _trainerLevelId,
        recentCap: _generator?.wordPicker.recentCap ??
            SyllableBuilderWordPicker(
              dictionary: ref.read(dictionaryServiceProvider),
              trainerLevelId: _trainerLevelId,
            ).recentCap,
      );
      await AppFeedback.success();
      await reactStencilToAnswer(
        correct: true,
        flightOriginKey: _wordAssemblyKey,
        rewardTrainerId: TrainerIds.syllableBuilder,
      );
    } else {
      await AppFeedback.softHint();
      await reactStencilToAnswer(
        correct: false,
        flightOriginKey: _wordAssemblyKey,
        rewardTrainerId: TrainerIds.syllableBuilder,
      );
    }

    if (!mounted) return;
    reloadTrainerStars();

    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
      setState(() {
        _task = null;
        _evaluating = false;
      });
      return;
    }

    setState(() => _evaluating = false);
    _startNewTask();
  }

  Future<void> _changeLevel(int levelId) async {
    if (levelId == _trainerLevelId) return;
    unawaited(AppFeedback.tap());
    _stopFallLoop();
    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(levelId);
    setState(() {
      _trainerLevelId = levelId;
      _roundActive = false;
    });
    _generator?.setTrainerLevel(levelId);

    if (!hasStencilAttemptsLeft) {
      setState(() => _task = null);
      await showStencilAttemptsExhaustedDialog();
      return;
    }

    _startNewTask();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task;
    final colors = Theme.of(context).colorScheme;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Собери слово')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildStencilHeader(),
                const Spacer(),
                buildAttemptsCounter(),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Собери слово'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Уровень',
            initialValue: _trainerLevelId,
            onSelected: _changeLevel,
            itemBuilder: (ctx) => [
              for (final level in SyllableBuilderLevel.all)
                PopupMenuItem(
                  value: level,
                  child: Text(SyllableBuilderLevel.label(level)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(SyllableBuilderLevel.label(_trainerLevelId)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Новое слово',
            onPressed: _canStartRound || (_roundActive && !_evaluating)
                ? () {
                    unawaited(AppFeedback.tap());
                    _startNewTask();
                  }
                : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          key: stackKey,
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: buildStencilHeader(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WordAssemblyLine(
                        lineKey: _wordAssemblyKey,
                        syllableCount: task.syllableCount,
                        pickedSyllables: _pickedSyllables,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        !_roundActive
                            ? 'Нажми «Начать», чтобы слоги поплыли'
                            : _evaluating
                                ? 'Проверяем слово...'
                                : _pickedSyllables.length >= task.syllableCount
                                    ? 'Проверяем слово...'
                                    : 'Выбери слог ${_pickedSyllables.length + 1} '
                                          'из ${task.syllableCount}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _playAreaHeight = constraints.maxHeight;

                      return ListenableBuilder(
                        listenable: _fallTick,
                        builder: (context, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (!_roundActive)
                                Center(
                                  child: TrainerStartPrompt(
                                    onTap: _onStartRound,
                                  ),
                                )
                              else
                                for (final block in task.blocks)
                                  if (!block.collected)
                                    Positioned(
                                      left:
                                          (constraints.maxWidth -
                                              SyllableBuilderLayout
                                                  .blockWidth) *
                                              block.xFactor -
                                          SyllableTapTarget.hitSlop,
                                      top: block.y - SyllableTapTarget.hitSlop,
                                      child: _FallingChip(
                                        key: ValueKey(block.blockId),
                                        label: block.text,
                                        onTap: () => _onBlockTap(block),
                                        enabled: _canPlay,
                                      ),
                                    ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: buildAttemptsCounter(),
                ),
              ],
            ),
            ...buildStencilStarOverlays(),
          ],
        ),
      ),
    );
  }
}

class _WordAssemblyLine extends StatelessWidget {
  const _WordAssemblyLine({
    required this.lineKey,
    required this.syllableCount,
    required this.pickedSyllables,
  });

  final GlobalKey lineKey;
  final int syllableCount;
  final List<String> pickedSyllables;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return KeyedSubtree(
      key: lineKey,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < syllableCount; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: AppTheme.minTouchTarget,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: i < pickedSyllables.length
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  i < pickedSyllables.length ? pickedSyllables[i] : '?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FallingChip extends StatelessWidget {
  const _FallingChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SyllableTapTarget(
      enabled: enabled,
      onActivated: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: SyllableBuilderLayout.blockWidth,
          height: SyllableBuilderLayout.blockHeight,
          child: Center(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
