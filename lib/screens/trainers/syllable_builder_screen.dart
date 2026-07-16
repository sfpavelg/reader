import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../widgets/hint_word_halo.dart';
import '../../widgets/syllable_assembly_line.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../widgets/trainer_menu_label.dart';
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
  static const _assemblyPanelHeight = 64.0;

  final _wordAssemblyKey = GlobalKey();

  int _trainerLevelId = SyllableBuilderLevel.level1;
  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;
  bool _roundActive = false;

  SyllableBuilderGenerator? _generator;
  SyllableBuilderTask? _task;
  final List<FallingSyllableBlock> _pickedBlocks = [];

  Timer? _fallTimer;
  double _playAreaWidth = 320;
  double _playAreaHeight = 400;
  final ValueNotifier<int> _fallTick = ValueNotifier(0);

  List<String> get _pickedSyllables =>
      [for (final block in _pickedBlocks) block.text];

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
      _pickedBlocks.clear();
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
        _evaluating) {
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
      hasStencilAttemptsLeft &&
      _task != null;

  bool get _canRefreshTask =>
      !_evaluating &&
      hasStencilAttemptsLeft &&
      _task != null;

  bool get _canPressDone => !_evaluating && _task != null;

  void _onBlockTap(FallingSyllableBlock block) {
    if (!_canPlay) return;
    if (block.collected) return;

    unawaited(AppFeedback.tap());
    setState(() {
      block.collected = true;
      _pickedBlocks.add(block);
    });
  }

  void _undoLastPick() {
    if (!_canPlay || _pickedBlocks.isEmpty) return;
    unawaited(AppFeedback.tap());
    setState(() {
      final block = _pickedBlocks.removeLast();
      block.collected = false;
    });
  }

  void _removePickedAt(int index) {
    if (!_canPlay || index < 0 || index >= _pickedBlocks.length) return;
    unawaited(AppFeedback.tap());
    setState(() {
      final block = _pickedBlocks.removeAt(index);
      block.collected = false;
    });
  }

  void _swapPicked(int from, int to) {
    if (!_canPlay || from == to) return;
    if (from < 0 ||
        to < 0 ||
        from >= _pickedBlocks.length ||
        to >= _pickedBlocks.length) {
      return;
    }
    unawaited(AppFeedback.tap());
    setState(() {
      final tmp = _pickedBlocks[from];
      _pickedBlocks[from] = _pickedBlocks[to];
      _pickedBlocks[to] = tmp;
    });
  }

  void _returnPickedToFlight() {
    for (final block in _pickedBlocks) {
      block.collected = false;
    }
    _pickedBlocks.clear();
  }

  Future<void> _onSubmit() async {
    if (!_canPressDone || _task == null) return;
    if (_pickedBlocks.isEmpty) return;

    _stopFallLoop();
    final task = _task!;
    final attempt = _pickedSyllables.join();
    final correct = attempt == task.word;

    setState(() => _evaluating = true);

    if (!correct) {
      await consumeStencilAttempt();
      await AppFeedback.softHint();
      await reactStencilToAnswer(
        correct: false,
        flightOriginKey: _wordAssemblyKey,
        rewardTrainerId: TrainerIds.syllableBuilder,
      );
      if (!mounted) return;
      reloadTrainerStars();
      setState(() {
        _returnPickedToFlight();
        _evaluating = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _canPlay) _startFallLoop();
      });
      if (!hasStencilAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

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
      _pickedBlocks.clear();
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
    final picked = _pickedSyllables;

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
              child: TrainerMenuLabel(
                SyllableBuilderLevel.label(_trainerLevelId),
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
        top: false,
        child: Stack(
          key: stackKey,
          fit: StackFit.expand,
          children: [
            // Нижний слой: подсказка, поле сборки, кнопки.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  buildStencilHeader(),
                  const SizedBox(height: 6),
                  HintWordHalo(
                    text: task.word,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Лови слоги и собери слово',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SyllableAssemblyLine(
                    lineKey: _wordAssemblyKey,
                    pickedSyllables: picked,
                    panelHeight: _assemblyPanelHeight,
                    enabled: _canPlay,
                    onReorder: _swapPicked,
                    onRemoveAt: _removePickedAt,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: picked.isNotEmpty && _canPlay
                            ? _undoLastPick
                            : null,
                        icon: const Icon(Icons.backspace_outlined, size: 20),
                        label: const Text('Стереть'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: picked.isNotEmpty && _canPressDone
                            ? () => unawaited(_onSubmit())
                            : null,
                        child: const Text('Готово'),
                      ),
                    ],
                  ),
                  const Expanded(child: SizedBox.expand()),
                  const SizedBox(height: 6),
                  buildAttemptsCounter(),
                ],
              ),
            ),
            // Верхний слой: слоги летят поверх слова и поля ввода.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
            ),
            ...buildStencilStarOverlays(),
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
