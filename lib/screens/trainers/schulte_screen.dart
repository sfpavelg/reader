import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../gamification/hints_policy.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/hint_word_halo.dart';
import '../../widgets/syllable_assembly_line.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../app/trainer_ids.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../main.dart';
import '../../trainers/schulte/schulte_difficulty.dart';
import '../../trainers/schulte/schulte_generator.dart';
import '../../trainers/schulte/schulte_session_store.dart';
import '../../trainers/schulte/schulte_task.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/trainer_menu_label.dart';

class SchulteScreen extends ConsumerStatefulWidget {
  const SchulteScreen({super.key});

  @override
  ConsumerState<SchulteScreen> createState() => _SchulteScreenState();
}

class _SchulteScreenState extends ConsumerState<SchulteScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _sharedStorageKey = 'schulte_shared';
  static const _dailyAttemptLimit = 20;
  static const _assemblyPanelHeight = 64.0;

  final _assemblyKey = GlobalKey();

  SchulteGenerator? _generator;
  SchulteTask? _task;
  SchulteDifficulty _difficulty = SchulteDifficulty.easy;
  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;

  /// Уже собранные на этой сетке (до нажатия «обновить»).
  final Set<String> _collectedWords = {};

  /// Индексы ячеек сетки в порядке выбора.
  final List<int> _pickedGridIndices = [];

  String _remainingCountLabel(int count) {
    if (count <= 0) return 'Все слова собраны';
    final form = switch (count % 100) {
      >= 11 && <= 14 => 'слов',
      _ => switch (count % 10) {
          1 => 'слово',
          >= 2 && <= 4 => 'слова',
          _ => 'слов',
        },
    };
    return 'Можно собрать $count $form';
  }

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
      syncStencilAttemptLevel(_difficulty.id);
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

  void _startNewTask() {
    if (!hasStencilAttemptsLeft) return;

    _generator = SchulteGenerator(
      dictionary: ref.read(dictionaryServiceProvider),
      difficulty: _difficulty,
    );

    clearStencilFlightState();
    final task = _generator!.generate();
    final cap = _generator!.wordPicker.recentCap;
    for (final id in task.packedEntryIds) {
      unawaited(SchulteSessionStore.recordPresented(id, recentCap: cap));
    }
    setState(() {
      _task = task;
      _collectedWords.clear();
      _pickedGridIndices.clear();
      _evaluating = false;
    });
  }

  Future<void> _changeDifficulty(SchulteDifficulty difficulty) async {
    if (difficulty == _difficulty) return;
    await AppFeedback.tap();
    if (!mounted) return;

    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(difficulty.id);
    setState(() {
      _difficulty = difficulty;
      _evaluating = false;
      _pickedGridIndices.clear();
      _collectedWords.clear();
    });

    if (!hasStencilAttemptsLeft) {
      setState(() => _task = null);
      await showStencilAttemptsExhaustedDialog();
      return;
    }

    _startNewTask();
  }

  PreferredSizeWidget _buildAppBar() {
    return appBar(
      context,
      title: const Text('Собирайка'),
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Уровень',
          initialValue: _difficulty.id,
          onSelected: (id) =>
              unawaited(_changeDifficulty(SchulteDifficulty.byId(id))),
          itemBuilder: (ctx) => [
            for (final level in SchulteDifficulty.values)
              PopupMenuItem(
                value: level.id,
                child: Text(level.menuLabel),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TrainerMenuLabel(_difficulty.label),
          ),
        ),
        AppRefreshButton(
          tooltip: 'Новая сетка',
          onPressed: _canPressDone
              ? () {
                  unawaited(AppFeedback.tap());
                  _startNewTask();
                }
              : null,
        ),
      ],
    );
  }

  List<String> get _pickedSyllables {
    final task = _task;
    if (task == null) return const [];
    return [
      for (final index in _pickedGridIndices) task.cellAt(index)!.text!,
    ];
  }

  bool get _canPick =>
      !_evaluating && hasStencilAttemptsLeft && _task != null;

  bool get _canPressDone => !_evaluating && _task != null;

  void _onCellTap(int gridIndex) {
    if (!_canPick) return;
    final cell = _task?.cellAt(gridIndex);
    if (cell == null || cell.isEmpty) return;
    if (_pickedGridIndices.contains(gridIndex)) return;

    unawaited(AppFeedback.tap());
    setState(() => _pickedGridIndices.add(gridIndex));
  }

  void _undoLastPick() {
    if (!_canPick || _pickedGridIndices.isEmpty) return;
    unawaited(AppFeedback.tap());
    setState(() => _pickedGridIndices.removeLast());
  }

  void _removePickedAt(int index) {
    if (!_canPick || index < 0 || index >= _pickedGridIndices.length) return;
    unawaited(AppFeedback.tap());
    setState(() => _pickedGridIndices.removeAt(index));
  }

  void _swapPicked(int from, int to) {
    if (!_canPick || from == to) return;
    if (from < 0 ||
        to < 0 ||
        from >= _pickedGridIndices.length ||
        to >= _pickedGridIndices.length) {
      return;
    }
    unawaited(AppFeedback.tap());
    setState(() {
      final tmp = _pickedGridIndices[from];
      _pickedGridIndices[from] = _pickedGridIndices[to];
      _pickedGridIndices[to] = tmp;
    });
  }

  Future<void> _showDuplicateWarning() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ты молодец!', textAlign: TextAlign.center),
        content: const Text(
          'Такое слово уже было.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Хорошо'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_canPressDone || _task == null) return;

    final task = _task!;
    if (_pickedGridIndices.isEmpty) return;

    final attempt = _pickedSyllables.join();

    if (_collectedWords.contains(attempt)) {
      unawaited(AppFeedback.softHint());
      setState(() => _pickedGridIndices.clear());
      await _showDuplicateWarning();
      return;
    }

    final match = task.matchPicked(_pickedSyllables);

    if (match == null) {
      setState(() => _evaluating = true);
      await consumeStencilAttempt();
      await AppFeedback.softHint();
      await reactStencilToAnswer(
        correct: false,
        flightOriginKey: _assemblyKey,
        rewardTrainerId: TrainerIds.schulte,
      );
      if (!mounted) return;
      reloadTrainerStars();
      setState(() {
        _pickedGridIndices.clear();
        _evaluating = false;
      });
      if (!hasStencilAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

    setState(() => _evaluating = true);
    await consumeStencilAttempt();

    await SchulteSessionStore.recordCompleted(
      match.entryId,
      recentCap: _generator?.wordPicker.recentCap ?? 40,
    );
    await AppFeedback.success();

    await reactStencilToAnswer(
      correct: true,
      flightOriginKey: _assemblyKey,
      rewardTrainerId: TrainerIds.schulte,
      starSlots: HintsPolicy.targetWordStars,
    );
    if (!mounted) return;
    reloadTrainerStars();

    final used = _pickedGridIndices.toSet();
    _collectedWords.add(match.text);
    final next = task.withoutUsedCells(
      usedGridIndices: used,
      dictionary: ref.read(dictionaryServiceProvider),
      collectedWords: _collectedWords,
    );

    setState(() {
      _task = next;
      _pickedGridIndices.clear();
      _evaluating = false;
    });

    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildStencilHeader(),
                const Spacer(),
                Text(
                  'Попытки на уровне «${_difficulty.label}» закончились',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                buildAttemptsCounter(),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final picked = _pickedSyllables;
    final remaining = task.remainingSpellableCount(_collectedWords);
    final combo = task.remainingCombinationsLabel(_collectedWords);

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Stack(
          key: stackKey,
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  buildStencilHeader(),
                  const SizedBox(height: 6),
                  HintWordHalo(
                    text: _remainingCountLabel(remaining),
                    active: remaining > 0,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (combo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      combo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Собери слово из слогов',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SyllableAssemblyLine(
                    lineKey: _assemblyKey,
                    pickedSyllables: picked,
                    panelHeight: _assemblyPanelHeight,
                    enabled: _canPick,
                    onReorder: _swapPicked,
                    onRemoveAt: _removePickedAt,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickedGridIndices.isNotEmpty && _canPick
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
                        onPressed: _evaluating
                            ? null
                            : () => unawaited(_onSubmit()),
                        child: const Text('Готово'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 6.0;
                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight;
                          final cellW =
                              ((maxW - gap * (task.cols - 1)) / task.cols)
                                  .clamp(
                                    AppTheme.cellMinSize *
                                        _difficulty.cellMinScale,
                                    _difficulty.cellMaxSize,
                                  );
                          final cellH =
                              ((maxH - gap * (task.rows - 1)) / task.rows)
                                  .clamp(
                                    AppTheme.cellMinSize *
                                        _difficulty.cellMinScale,
                                    _difficulty.cellMaxSize,
                                  );
                          final cellSide = cellW < cellH ? cellW : cellH;
                          final fontScale = _difficulty.syllableFontScale;

                          return SizedBox(
                            width:
                                cellSide * task.cols + gap * (task.cols - 1),
                            height:
                                cellSide * task.rows + gap * (task.rows - 1),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: task.cols,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                  ),
                              itemCount: task.cellCount,
                              itemBuilder: (context, index) {
                                final cell = task.cellAt(index)!;
                                if (cell.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final used =
                                    _pickedGridIndices.contains(index);

                                Color bg = colors.surfaceContainerHighest;
                                if (used) {
                                  bg = colors.primaryContainer;
                                }

                                return RepaintBoundary(
                                  child: Material(
                                    color: bg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: colors.outline,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: SyllableTapTarget(
                                      enabled: !used && _canPick,
                                      onActivated: () => _onCellTap(index),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Text(
                                          cell.text!,
                                          style: TextStyle(
                                            fontSize: cellSide * fontScale,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildAttemptsCounter(),
                ],
              ),
            ),
            ...buildStencilStarOverlays(),
          ],
        ),
      ),
    );
  }
}
