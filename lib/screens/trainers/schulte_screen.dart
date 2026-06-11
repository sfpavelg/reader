import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../widgets/trainer_completion_dialog.dart';
import '../../main.dart';
import '../../trainers/schulte/schulte_generator.dart';
import '../../trainers/schulte/schulte_task.dart';

class SchulteScreen extends ConsumerStatefulWidget {
  const SchulteScreen({super.key});

  @override
  ConsumerState<SchulteScreen> createState() => _SchulteScreenState();
}

class _SchulteScreenState extends ConsumerState<SchulteScreen> {
  SchulteTask? _task;
  int _nextRank = 0;
  final Set<int> _solved = {};
  int? _hintGridIndex;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _newTask();
    }
  }

  void _newTask() {
    final dictionary = ref.read(dictionaryServiceProvider);
    final generator = SchulteGenerator(dictionary: dictionary);
    setState(() {
      _task = generator.generate(levelId: 1, gridSize: 3);
      _nextRank = 0;
      _solved.clear();
      _hintGridIndex = null;
    });
  }

  void _onCellTap(SchulteCell cell) {
    final task = _task;
    if (task == null || _solved.contains(cell.gridIndex)) return;

    if (cell.orderRank == _nextRank) {
      unawaited(AppFeedback.success());
      setState(() {
        _solved.add(cell.gridIndex);
        _nextRank++;
        _hintGridIndex = null;
      });
      if (_nextRank >= task.cellCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showComplete();
        });
      }
      return;
    }

    // Мягкая подсказка — без «красного провала».
    unawaited(AppFeedback.softHint());
    setState(() => _hintGridIndex = cell.gridIndex);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _hintGridIndex = null);
    });
  }

  Future<void> _showComplete() async {
    await completeTrainerRound(
      context,
      trainerId: TrainerIds.schulte,
      title: 'Отлично!',
      message: 'Таблица пройдена. Можно ещё раз или выйти.',
      primaryLabel: 'Готово',
      onPrimary: () {},
      secondaryLabel: 'Ещё раз',
      onSecondary: _newTask,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final completed = _nextRank >= task.cellCount;
    final target =
        completed ? null : task.cellWithOrderRank(_nextRank);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица Шульте'),
        actions: [
          IconButton(
            tooltip: 'Новая таблица',
            onPressed: () {
              unawaited(AppFeedback.tap());
              _newTask();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                completed ? 'Готово!' : 'Найди: ${target!.text}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Смотри в центр таблицы',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.biggest.shortestSide;
                      final gap = 8.0;
                      final cellSide = ((side - gap * (task.gridSize - 1)) /
                              task.gridSize)
                          .clamp(AppTheme.cellMinSize, 140.0);

                      return SizedBox(
                        width:
                            cellSide * task.gridSize + gap * (task.gridSize - 1),
                        height:
                            cellSide * task.gridSize + gap * (task.gridSize - 1),
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
                            final solved = _solved.contains(index);
                            final hinted = _hintGridIndex == index;

                            Color bg = colors.surfaceContainerHighest;
                            if (solved) {
                              bg = colors.primaryContainer;
                            } else if (hinted) {
                              bg = colors.tertiaryContainer;
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _onCellTap(cell),
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
            ],
          ),
        ),
      ),
    );
  }
}
