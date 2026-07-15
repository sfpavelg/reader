import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/trainer_ids.dart';
import '../../main.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../trainers/ugadayka/ugadayka_board.dart';
import '../../trainers/ugadayka/ugadayka_difficulty.dart';
import '../../trainers/ugadayka/ugadayka_grid.dart';
import '../../widgets/app_feedback.dart';

class UgadaykaScreen extends ConsumerStatefulWidget {
  const UgadaykaScreen({super.key});

  @override
  ConsumerState<UgadaykaScreen> createState() => _UgadaykaScreenState();
}

class _UgadaykaScreenState extends ConsumerState<UgadaykaScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _sharedStorageKey = 'ugadayka_shared';
  static const _dailyAttemptLimit = 40;
  static const _gridGap = 4.0;
  static const _headerPadding = EdgeInsets.fromLTRB(10, 8, 10, 0);
  static const _revealPause = Duration(milliseconds: 450);
  static const _mismatchPause = Duration(milliseconds: 650);

  final _gridKey = GlobalKey();

  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;

  UgadaykaDifficulty _difficulty = UgadaykaDifficulty.easy;
  UgadaykaBoard? _board;
  int? _firstPick;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    initTrainerStars();
    initStencilStars(
      storageKey: _sharedStorageKey,
      dailyAttemptLimit: _dailyAttemptLimit,
      perLevelAttempts: true,
    );
    syncStencilAttemptLevel(_difficulty.id);
    unawaited(_loadBoard());
  }

  Future<void> _loadBoard() async {
    final dictionary = ref.read(dictionaryServiceProvider);
    await dictionary.initialize();
    if (!mounted) return;

    if (!hasStencilAttemptsLeft) {
      setState(() => _loaded = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showStencilAttemptsExhaustedDialog());
      });
      return;
    }

    setState(() {
      _board = UgadaykaBoard.fromDictionary(
        dictionary,
        difficulty: _difficulty,
      );
      _firstPick = null;
      _evaluating = false;
      _loaded = true;
    });
  }

  void _startNewBoard() {
    clearStencilFlightState();
    final dictionary = ref.read(dictionaryServiceProvider);
    setState(() {
      _board = UgadaykaBoard.fromDictionary(
        dictionary,
        difficulty: _difficulty,
      );
      _firstPick = null;
      _evaluating = false;
    });
  }

  Future<void> _changeDifficulty(UgadaykaDifficulty difficulty) async {
    if (difficulty == _difficulty) return;
    await AppFeedback.tap();
    if (!mounted) return;

    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(difficulty.id);
    setState(() {
      _difficulty = difficulty;
      _firstPick = null;
      _evaluating = false;
    });

    if (!hasStencilAttemptsLeft) {
      setState(() => _board = null);
      await showStencilAttemptsExhaustedDialog();
      return;
    }

    _startNewBoard();
  }

  bool get _canInteract =>
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _board != null &&
      !_board!.isComplete;

  bool get _canRestartBoard =>
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _board != null;

  Future<void> _restartBoard() async {
    if (!_canRestartBoard) return;
    await AppFeedback.tap();
    _startNewBoard();
  }

  Future<void> _onCellTap(int index) async {
    final board = _board;
    if (!_canInteract || board == null) return;
    if (board.isEmpty(index) || board.isFaceUp(index)) return;

    await AppFeedback.tap();
    setState(() => board.reveal(index));

    final first = _firstPick;
    if (first == null) {
      setState(() => _firstPick = index);
      return;
    }
    if (first == index) return;

    setState(() => _evaluating = true);
    await Future<void>.delayed(_revealPause);
    if (!mounted) return;

    if (board.syllablesMatch(first, index)) {
      await AppFeedback.success();
      setState(() {
        board.clearPair(first, index);
        _firstPick = null;
        _evaluating = false;
      });

      await reactStencilToAnswer(
        correct: true,
        flightOriginKey: _gridKey,
        rewardTrainerId: TrainerIds.ugadayka,
        starSlots: 1,
      );
      if (!mounted) return;
      reloadTrainerStars();

      if (board.isComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все пары найдены!', textAlign: TextAlign.center),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await consumeStencilAttempt();
    if (!mounted) return;
    await AppFeedback.softHint();
    await Future<void>.delayed(_mismatchPause);
    if (!mounted) return;

    setState(() {
      board.hide(first);
      board.hide(index);
      _firstPick = null;
      _evaluating = false;
    });

    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Угадайка'),
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Уровень',
          initialValue: _difficulty.id,
          onSelected: (id) => unawaited(_changeDifficulty(UgadaykaDifficulty.byId(id))),
          itemBuilder: (ctx) => [
            for (final level in UgadaykaDifficulty.values)
              PopupMenuItem(
                value: level.id,
                child: Text('${level.label} — ${level.cardCount} слогов'),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(_difficulty.label),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Заново',
          onPressed: _canRestartBoard ? () => unawaited(_restartBoard()) : null,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final board = _board;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          key: stackKey,
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Padding(
                  padding: _headerPadding,
                  child: Column(
                    children: [
                      buildStencilHeader(),
                      const SizedBox(height: 8),
                      Text(
                        board?.isComplete == true
                            ? 'Все пары найдены!'
                            : 'Найди парные слоги',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (board?.isComplete == true && _canRestartBoard) ...[
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () => unawaited(_restartBoard()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Играть снова'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: board == null
                      ? Center(
                          child: Text(
                            'Попытки на уровне «${_difficulty.label}» закончились',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final cellSide = _cellSide(
                              constraints.maxWidth,
                              constraints.maxHeight,
                              board.cols,
                              board.rows,
                            );

                            return Center(
                              child: UgadaykaGrid(
                                gridKey: _gridKey,
                                cols: board.cols,
                                rows: board.rows,
                                cells: board.cells,
                                faceUp: board.faceUp,
                                cellSide: cellSide,
                                gap: _gridGap,
                                canInteract: _canInteract,
                                syllableFontScale: _difficulty.syllableFontScale,
                                onCellTap: (index) => unawaited(_onCellTap(index)),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
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

  double _cellSide(double width, double height, int cols, int rows) {
    final byWidth = (width - _gridGap * (cols - 1)) / cols;
    final byHeight = (height - _gridGap * (rows - 1)) / rows;
    final gridHeight = byWidth * rows + _gridGap * (rows - 1);
    if (gridHeight <= height) return byWidth;
    return byHeight;
  }
}
