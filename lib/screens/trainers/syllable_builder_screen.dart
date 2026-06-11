import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../widgets/trainer_completion_dialog.dart';
import '../../main.dart';
import '../../trainers/syllable_builder/syllable_builder_generator.dart';
import '../../trainers/syllable_builder/syllable_builder_layout.dart';
import '../../trainers/syllable_builder/syllable_builder_session_store.dart';
import '../../trainers/syllable_builder/syllable_builder_word_picker.dart';
import '../../trainers/syllable_builder/syllable_builder_task.dart';

class SyllableBuilderScreen extends ConsumerStatefulWidget {
  const SyllableBuilderScreen({super.key});

  @override
  ConsumerState<SyllableBuilderScreen> createState() =>
      _SyllableBuilderScreenState();
}

class _SyllableBuilderScreenState extends ConsumerState<SyllableBuilderScreen> {
  bool _ready = false;
  SyllableBuilderGenerator? _generator;
  SyllableBuilderTask? _task;
  int _nextSequence = 0;
  String? _wrongBlockId;

  Timer? _fallTimer;
  double _playAreaHeight = 400;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _startNewTask();
    }
  }

  @override
  void dispose() {
    _stopFallLoop();
    super.dispose();
  }

  void _stopFallLoop() {
    _fallTimer?.cancel();
    _fallTimer = null;
  }

  void _startNewTask() {
    _stopFallLoop();

    _generator ??= SyllableBuilderGenerator(
      dictionary: ref.read(dictionaryServiceProvider),
    );

    setState(() {
      _task = _generator!.generate();
      _nextSequence = 0;
      _wrongBlockId = null;
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
    if (task == null || !mounted) return;

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
      setState(() {});
    }
  }

  void _onBlockTap(FallingSyllableBlock block) {
    final task = _task;
    if (task == null || block.collected) return;

    if (block.sequenceIndex == _nextSequence) {
      unawaited(AppFeedback.success());
      setState(() {
        block.collected = true;
        _nextSequence++;
        _wrongBlockId = null;
      });

      if (_nextSequence >= task.syllableCount) {
        _stopFallLoop();
        unawaited(
          SyllableBuilderSessionStore.recordCompleted(
            task.entryId,
            recentCap: _generator?.wordPicker.recentCap ??
                SyllableBuilderWordPicker(
                  dictionary: ref.read(dictionaryServiceProvider),
                ).recentCap,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showComplete();
        });
      }
      return;
    }

    unawaited(AppFeedback.softHint());
    setState(() => _wrongBlockId = block.blockId);
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _wrongBlockId = null);
    });
  }

  Future<void> _showComplete() async {
    final word = _task?.word ?? '';
    await completeTrainerRound(
      context,
      trainerId: TrainerIds.syllableBuilder,
      title: 'Слово собрано!',
      message: word.isEmpty ? 'Отлично!' : '«$word» — молодец!',
      primaryLabel: 'Ещё слово',
      onPrimary: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startNewTask();
        });
      },
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Слоги'),
        actions: [
          IconButton(
            tooltip: 'Новое слово',
            onPressed: () {
              unawaited(AppFeedback.tap());
              _startNewTask();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Собери слово',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _WordSlots(
                    syllables: task.syllables,
                    filledCount: _nextSequence,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Жди слог ${_nextSequence + 1} из ${task.syllableCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _playAreaHeight = constraints.maxHeight;
                  return RepaintBoundary(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final block in task.blocks)
                          if (!block.collected)
                            Positioned(
                              left: (constraints.maxWidth -
                                          SyllableBuilderLayout.blockWidth) *
                                      block.xFactor,
                              top: block.y,
                              child: _FallingChip(
                                label: block.text,
                                highlighted: _wrongBlockId == block.blockId,
                                onTap: () => _onBlockTap(block),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordSlots extends StatelessWidget {
  const _WordSlots({
    required this.syllables,
    required this.filledCount,
  });

  final List<String> syllables;
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < syllables.length; i++)
          Container(
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: AppTheme.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i < filledCount
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              i < filledCount ? syllables[i] : '?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
      ],
    );
  }
}

class _FallingChip extends StatelessWidget {
  const _FallingChip({
    required this.label,
    required this.onTap,
    required this.highlighted,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: highlighted ? colors.tertiaryContainer : colors.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: SyllableBuilderLayout.blockWidth,
          height: SyllableBuilderLayout.blockHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline, width: 2),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
