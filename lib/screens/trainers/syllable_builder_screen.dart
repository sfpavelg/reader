import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../gamification/rewards_service.dart';
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
  int _nextSequence = 0;
  String? _wrongBlockId;
  FallingSyllableBlock? _mistakenBlock;

  Timer? _fallTimer;
  double _playAreaWidth = 320;
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
      _nextSequence = 0;
      _wrongBlockId = null;
      _mistakenBlock = null;
      _evaluating = false;
      _roundActive = true;
    });

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
      block.xPhase += block.driftSpeed * step;
      if (block.y > bottom) {
        block.y = SyllableBuilderLayout.respawnY(block.spawnWave);
      }
      changed = true;
    }

    SyllableBuilderLayout.separateSparseBlocks(
      task.blocks,
      _playAreaWidth,
    );

    if (changed) {
      _fallTick.value++;
    }
  }

  bool get _canPlay =>
      _roundActive &&
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _task != null;

  bool get _canRefreshTask =>
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _task != null;

  void _onBlockTap(FallingSyllableBlock block) {
    if (!_canPlay) return;
    final task = _task;
    if (task == null || block.collected) return;
    if (_mistakenBlock != null) return;

    final expected = task.syllables[_nextSequence];
    if (block.text != expected) {
      unawaited(AppFeedback.softHint());
      setState(() {
        block.collected = true;
        _mistakenBlock = block;
        _wrongBlockId = block.blockId;
      });
      return;
    }

    unawaited(AppFeedback.tap());
    setState(() {
      block.collected = true;
      _pickedSyllables.add(block.text);
      _nextSequence++;
      _wrongBlockId = null;
    });

    if (_nextSequence >= task.syllableCount) {
      _stopFallLoop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_onWordComplete());
      });
    }
  }

  Future<void> _undoMistakenCatch() async {
    final block = _mistakenBlock;
    if (block == null || !_canPlay) return;

    unawaited(AppFeedback.tap());
    await RewardsService.penalizeTrainerFailure(stars: 1);
    if (!mounted) return;

    reloadTrainerStars();
    setState(() {
      block.collected = false;
      block.y = SyllableBuilderLayout.respawnY(block.spawnWave);
      _mistakenBlock = null;
      _wrongBlockId = null;
    });
  }

  Future<void> _onWordComplete() async {
    if (_evaluating) return;
    final task = _task;
    if (task == null) return;

    setState(() => _evaluating = true);
    await consumeStencilAttempt();

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
    _restartRoundAfterComplete();
  }

  void _restartRoundAfterComplete() {
    _stopFallLoop();
    clearStencilFlightState();
    setState(() {
      _task = _generator!.generate();
      _pickedSyllables.clear();
      _nextSequence = 0;
      _wrongBlockId = null;
      _mistakenBlock = null;
      _roundActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startFallLoop();
    });
  }

  Future<void> _changeLevel(int levelId) async {
    if (levelId == _trainerLevelId) return;
    unawaited(AppFeedback.tap());
    _stopFallLoop();
    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(levelId);
    setState(() {
      _trainerLevelId = levelId;
      _roundActive = true;
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
        appBar: AppBar(title: const Text('Ловец')),
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
        title: const Text('Ловец'),
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
            onPressed: _canRefreshTask
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
                        targetSyllables: task.syllables,
                        filledCount: _pickedSyllables.length,
                        activeSlotIndex:
                            _roundActive && !_evaluating ? _nextSequence : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _evaluating
                            ? 'Отлично, слово поймано!'
                            : _mistakenBlock != null
                                ? 'Лишний слог «${_mistakenBlock!.text}» — отмени или продолжай'
                                : 'Поймай слог ${_nextSequence + 1} '
                                      'из ${task.syllableCount}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      if (_mistakenBlock != null && _canPlay) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => unawaited(_undoMistakenCatch()),
                          icon: const Icon(Icons.undo, size: 20),
                          label: const Text('Отменить (−1 ★)'),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _playAreaWidth = constraints.maxWidth;
                      _playAreaHeight = constraints.maxHeight;

                      return ListenableBuilder(
                        listenable: _fallTick,
                        builder: (context, _) {
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 8,
                                child: _CatchZone(
                                  active: _canPlay,
                                  label: _nextSequence < task.syllableCount
                                      ? 'Лови: ${task.syllables[_nextSequence]}'
                                      : null,
                                ),
                              ),
                              for (final block in task.blocks)
                                if (!block.collected)
                                  Positioned(
                                    left: SyllableBuilderLayout.baseLeft(
                                          _playAreaWidth,
                                          block.xFactor,
                                        ) +
                                        SyllableBuilderLayout.driftOffset(
                                          block,
                                        ) -
                                        SyllableTapTarget.hitSlop,
                                    top: block.y - SyllableTapTarget.hitSlop,
                                    child: _FallingChip(
                                      key: ValueKey(block.blockId),
                                      label: block.text,
                                      highlighted:
                                          _wrongBlockId == block.blockId,
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
    required this.targetSyllables,
    required this.filledCount,
    this.activeSlotIndex,
  });

  final GlobalKey lineKey;
  final List<String> targetSyllables;
  final int filledCount;
  final int? activeSlotIndex;

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
            for (var i = 0; i < targetSyllables.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _AssemblySlot(
                label: targetSyllables[i],
                filled: i < filledCount,
                active: i == activeSlotIndex,
                colors: colors,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssemblySlot extends StatelessWidget {
  const _AssemblySlot({
    required this.label,
    required this.filled,
    required this.active,
    required this.colors,
  });

  final String label;
  final bool filled;
  final bool active;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final waiting = !filled && !active;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(
        minWidth: 56,
        minHeight: AppTheme.minTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filled
            ? colors.primaryContainer
            : active
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? colors.primary
              : filled
                  ? colors.outline
                  : colors.outline.withValues(alpha: 0.55),
          width: active ? 3 : 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: filled
                  ? null
                  : active
                      ? colors.primary
                      : colors.onSurfaceVariant.withValues(
                          alpha: waiting ? 0.72 : 1,
                        ),
            ),
      ),
    );
  }
}

class _CatchZone extends StatelessWidget {
  const _CatchZone({
    required this.active,
    this.label,
  });

  final bool active;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? colors.primaryContainer.withValues(alpha: 0.35)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? colors.primary : colors.outline,
            width: active ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label ?? 'Лови падающие слоги',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: active ? colors.onPrimaryContainer : colors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
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
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SyllableTapTarget(
      enabled: enabled,
      onActivated: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: highlighted ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        elevation: highlighted ? 3 : 1,
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
