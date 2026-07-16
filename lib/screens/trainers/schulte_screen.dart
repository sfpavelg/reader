import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/hint_word_halo.dart';
import '../../widgets/syllable_assembly_line.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../app/trainer_ids.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../main.dart';
import '../../trainers/schulte/schulte_generator.dart';
import '../../trainers/schulte/schulte_session_store.dart';
import '../../trainers/schulte/schulte_task.dart';

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
  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;

  /// Слово в заголовке — подсказка до первого успеха, потом счётчик вариантов.
  String _headerText(SchulteTask task) {
    if (_collectedWords.isEmpty) return task.word;
    final remaining = task.remainingSpellableCount(_collectedWords);
    return _remainingWordsLabel(remaining);
  }

  static String _remainingWordsLabel(int count) {
    if (count <= 0) return 'Все слова собраны';
    final form = switch (count % 100) {
      >= 11 && <= 14 => 'слов',
      _ => switch (count % 10) {
          1 => 'слово',
          >= 2 && <= 4 => 'слова',
          _ => 'слов',
        },
    };
    return 'Можно собрать ещё $count $form';
  }

  /// Уже собранные на этой сетке (до нажатия «обновить»).
  final Set<String> _collectedWords = {};

  /// Индексы ячеек сетки в порядке выбора.
  final List<int> _pickedGridIndices = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      initTrainerStars();
      initStencilStars(
        storageKey: _sharedStorageKey,
        dailyAttemptLimit: _dailyAttemptLimit,
      );
      _bootstrap();
    }
  }

  void _bootstrap() {
    if (!stencilProgress.hasAttemptsLeft) {
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
    if (!stencilProgress.hasAttemptsLeft) return;

    _generator ??= SchulteGenerator(
      dictionary: ref.read(dictionaryServiceProvider),
    );

    clearStencilFlightState();
    final task = _generator!.generate();
    unawaited(
      SchulteSessionStore.recordPresented(
        task.entryId,
        recentCap: _generator!.wordPicker.recentCap,
      ),
    );
    setState(() {
      _task = task;
      _collectedWords.clear();
      _pickedGridIndices.clear();
      _evaluating = false;
    });
  }

  List<String> get _pickedSyllables {
    final task = _task;
    if (task == null) return const [];
    return [
      for (final index in _pickedGridIndices)
        task.cellAt(index)!.text,
    ];
  }

  bool get _canPick =>
      !_evaluating &&
      stencilProgress.hasAttemptsLeft &&
      _task != null;

  bool get _canPressDone => !_evaluating && _task != null;

  void _onCellTap(int gridIndex) {
    if (!_canPick) return;
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
      if (!stencilProgress.hasAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

    setState(() => _evaluating = true);

    final guessedWithoutHint = match.text != task.word;
    if (!guessedWithoutHint) {
      await consumeStencilAttempt();
    }

    await SchulteSessionStore.recordCompleted(
      match.entryId,
      recentCap: _generator?.wordPicker.recentCap ?? 40,
    );
    await AppFeedback.success();

    await reactStencilToAnswer(
      correct: true,
      flightOriginKey: _assemblyKey,
      rewardTrainerId: TrainerIds.schulte,
      starSlots: guessedWithoutHint ? match.syllables.length : 1,
    );
    if (!mounted) return;
    reloadTrainerStars();

    setState(() {
      _collectedWords.add(match.text);
      _pickedGridIndices.clear();
      _evaluating = false;
    });

    if (!stencilProgress.hasAttemptsLeft) {
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
        appBar: AppBar(title: const Text('Собирайка')),
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

    final colors = Theme.of(context).colorScheme;
    final picked = _pickedSyllables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Собирайка'),
        actions: [
          IconButton(
            tooltip: 'Новая сетка',
            onPressed: _canPressDone
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  buildStencilHeader(),
                  const SizedBox(height: 6),
                  HintWordHalo(
                    text: _headerText(task),
                    active: _collectedWords.isEmpty,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Нажимай слоги по порядку',
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
                          final side = constraints.biggest.shortestSide;
                          const gap = 8.0;
                          final cellSide =
                              ((side - gap * (task.gridSize - 1)) / task.gridSize)
                                  .clamp(AppTheme.cellMinSize, 140.0);

                          return SizedBox(
                            width:
                                cellSide * task.gridSize +
                                gap * (task.gridSize - 1),
                            height:
                                cellSide * task.gridSize +
                                gap * (task.gridSize - 1),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: task.gridSize,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                  ),
                              itemCount: task.cellCount,
                              itemBuilder: (context, index) {
                                final cell = task.cellAt(index)!;
                                final used = _pickedGridIndices.contains(index);

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
                                          cell.text,
                                          style: TextStyle(
                                            fontSize: cellSide * 0.28,
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
