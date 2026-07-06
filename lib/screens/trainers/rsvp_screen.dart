import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_feedback.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../app/trainer_ids.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../main.dart';
import '../../trainers/rsvp/rsvp_generator.dart';
import '../../trainers/rsvp/rsvp_session_store.dart';
import '../../trainers/rsvp/rsvp_chaos_layout.dart';
import '../../trainers/rsvp/rsvp_movement_mode.dart';
import '../../trainers/rsvp/rsvp_snake_track.dart';
import '../../trainers/rsvp/rsvp_speed.dart';
import '../../trainers/rsvp/rsvp_task.dart';

class RsvpScreen extends ConsumerStatefulWidget {
  const RsvpScreen({super.key});

  @override
  ConsumerState<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends ConsumerState<RsvpScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _sharedStorageKey = 'rsvp_shared';
  static const _dailyAttemptLimit = 20;
  static const _assemblyPanelHeight = 64.0;
  static const _streamTickMs = 16;
  static const _trainCarWidth = 72.0;
  static const _trainCarHeight = 56.0;
  static const _trainCarGap = 6.0;
  static const _fixedPlayfield = true;
  static const _playfieldTargetRows = 5;
  static const _playfieldRowGap = 8.0;
  static const _playfieldHeight =
      _trainCarHeight + (_playfieldTargetRows - 1) * (_trainCarHeight + _playfieldRowGap);

  bool get _usesFixedPlayfield => _fixedPlayfield && _usesPathCars;

  bool _usesSnakePath(RsvpSnakeTrack track) =>
      _movementModeId == RsvpMovementMode.snake &&
      _usesFixedPlayfield &&
      track.rowCount >= 2;

  bool _usesChaosPath(RsvpSnakeTrack track) =>
      _movementModeId == RsvpMovementMode.chaos &&
      _usesFixedPlayfield &&
      track.rowCount >= 2;

  bool get _usesPathCars =>
      _movementModeId == RsvpMovementMode.snake ||
      _movementModeId == RsvpMovementMode.chaos;

  RsvpSnakeTrack? _activePathTrack() {
    if (!_usesPathCars) return null;
    return _playfieldTrack;
  }

  final _assemblyKey = GlobalKey();

  RsvpGenerator? _generator;
  RsvpTask? _task;
  bool _ready = false;
  bool _loaded = false;
  bool _evaluating = false;
  bool _streamPlaying = false;

  int _speedId = RsvpSpeed.medium;
  int _movementModeId = RsvpMovementMode.snake;
  double _headDistance = 0;
  Timer? _streamTimer;

  String _displayWord = '';
  final Set<String> _collectedWords = {};
  final List<int> _pickedStreamIndices = [];
  List<int> _trainQueue = [];
  final Map<int, RsvpChaosCarState> _chaosCars = {};
  RsvpSnakeTrack? _playfieldTrack;
  bool _pathLayoutReady = false;

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
      syncStencilAttemptLevel(_speedId);
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
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

    _pauseStream();
    _generator ??= RsvpGenerator(
      dictionary: ref.read(dictionaryServiceProvider),
    );

    clearStencilFlightState();
    final task = _generator!.generate();
    unawaited(
      RsvpSessionStore.recordPresented(
        task.entryId,
        recentCap: _generator!.wordPicker.recentCap,
      ),
    );
    setState(() {
      _task = task;
      _displayWord = task.word;
      _collectedWords.clear();
      _pickedStreamIndices.clear();
      _trainQueue = List.generate(task.streamLength, (i) => i);
      _headDistance = 0;
      _resetPathSimulation();
      _evaluating = false;
    });
    if (_usesPathCars) {
      _playfieldTrack = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playStream();
    });
  }

  double get _trainPitch => _trainCarWidth + _trainCarGap;

  double get _pixelsPerSecond {
    final spm = RsvpSpeed.syllablesPerMinute(_speedId);
    return _trainPitch * spm / 60.0;
  }

  List<String> get _pickedSyllables {
    final task = _task;
    if (task == null) return const [];
    return [
      for (final index in _pickedStreamIndices) task.streamSyllables[index],
    ];
  }

  bool get _canInteract =>
      !_evaluating &&
      !stencilAnimating &&
      hasStencilAttemptsLeft &&
      _task != null;

  bool get _canPressDone =>
      !_evaluating && !stencilAnimating && _task != null;

  void _playStream() {
    final task = _task;
    if (task == null || task.streamLength == 0 || !_canInteract) return;

    _streamTimer?.cancel();
    if (_usesPathCars) {
      final track = _activePathTrack();
      if (track == null) return;
      _initPathCars(track);
    }
    setState(() => _streamPlaying = true);
    _streamTimer = Timer.periodic(
      const Duration(milliseconds: _streamTickMs),
      (_) => _onStreamTick(),
    );
  }

  void _onStreamTick() {
    if (!mounted || !_streamPlaying) return;
    if (!_canInteract) {
      _pauseStream();
      return;
    }

    final delta = _pixelsPerSecond * (_streamTickMs / 1000);
    final pathTrack = _activePathTrack();
    if (pathTrack != null) {
      RsvpChaosLayout.tick(
        states: _chaosCars,
        activeStreamIndices: _trainQueue,
        track: pathTrack,
        delta: delta,
        multiRowSnake: _usesSnakePath(pathTrack),
        multiRowChaos: _usesChaosPath(pathTrack),
      );
    } else {
      _headDistance += delta;
    }
    setState(() {});
  }

  void _resetPathSimulation() {
    _chaosCars.clear();
    _pathLayoutReady = false;
  }

  void _initPathCars(RsvpSnakeTrack track) {
    if (!_usesPathCars || _trainQueue.isEmpty) {
      return;
    }
    if (_pathLayoutReady && _chaosCars.isNotEmpty) {
      return;
    }

    RsvpChaosLayout.spreadInitial(
      states: _chaosCars,
      streamIndices: _trainQueue,
      track: track,
      multiRowSnake: _usesSnakePath(track),
      multiRowChaos: _usesChaosPath(track),
    );
    _pathLayoutReady = true;
  }

  void _ensurePlayfieldTrack(RsvpSnakeTrack track) {
    final sizeChanged = _playfieldTrack != null &&
        (_playfieldTrack!.laneWidth != track.laneWidth ||
            _playfieldTrack!.laneHeight != track.laneHeight);
    _playfieldTrack = track;

    if (_streamPlaying && _chaosCars.isNotEmpty) {
      return;
    }

    if (sizeChanged && !_streamPlaying) {
      _resetPathSimulation();
    }

    if (!_usesPathCars) {
      return;
    }

    if (_streamPlaying) {
      return;
    }

    _initPathCars(track);
  }

  void _placeReturnedOnPath(int streamIndex) {
    final track = _activePathTrack();
    if (track == null) return;
    RsvpChaosLayout.placeReturned(
      states: _chaosCars,
      streamIndex: streamIndex,
      track: track,
      activeStreamIndices: _trainQueue,
      multiRowSnake: _usesSnakePath(track),
      multiRowChaos: _usesChaosPath(track),
    );
  }

  void _pauseStream() {
    _streamTimer?.cancel();
    if (_streamPlaying) {
      setState(() => _streamPlaying = false);
    }
  }

  void _catchSyllable(int streamIndex) {
    if (!_canInteract || !_streamPlaying) return;
    final task = _task!;
    if (streamIndex < 0 || streamIndex >= task.streamLength) return;
    if (!_trainQueue.contains(streamIndex)) return;
    if (_pickedStreamIndices.contains(streamIndex)) return;

    unawaited(AppFeedback.tap());
    setState(() {
      _trainQueue.remove(streamIndex);
      _pickedStreamIndices.add(streamIndex);
    });
  }

  void _undoLastPick() {
    if (!_canInteract || _pickedStreamIndices.isEmpty) return;
    unawaited(AppFeedback.tap());
    setState(() {
      final streamIndex = _pickedStreamIndices.removeLast();
      _trainQueue.add(streamIndex);
      if (_usesPathCars) {
        _placeReturnedOnPath(streamIndex);
      }
    });
  }

  void _returnPickedToTrainTail() {
    if (_pickedStreamIndices.isEmpty) return;
    final returning = List<int>.from(_pickedStreamIndices);
    _pickedStreamIndices.clear();
    for (final streamIndex in returning) {
      _trainQueue.add(streamIndex);
      if (_usesPathCars) {
        _placeReturnedOnPath(streamIndex);
      }
    }
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
    if (_pickedStreamIndices.isEmpty) return;

    _pauseStream();
    final task = _task!;
    final attempt = _pickedSyllables.join();

    if (_collectedWords.contains(attempt)) {
      unawaited(AppFeedback.softHint());
      setState(_returnPickedToTrainTail);
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
        rewardTrainerId: TrainerIds.rsvp,
      );
      if (!mounted) return;
      reloadTrainerStars();
      setState(() {
        _returnPickedToTrainTail();
        _evaluating = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _canInteract) _playStream();
      });
      if (!hasStencilAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

    setState(() => _evaluating = true);

    final guessedWithoutHint = match.text != task.word;
    if (!guessedWithoutHint) {
      await consumeStencilAttempt();
    }

    await RsvpSessionStore.recordCompleted(
      match.entryId,
      recentCap: _generator?.wordPicker.recentCap ?? 40,
    );
    await AppFeedback.success();

    await reactStencilToAnswer(
      correct: true,
      flightOriginKey: _assemblyKey,
      rewardTrainerId: TrainerIds.rsvp,
      starSlots: guessedWithoutHint ? match.syllables.length : 1,
    );
    if (!mounted) return;
    reloadTrainerStars();

    setState(() {
      _collectedWords.add(match.text);
      _displayWord = match.text;
      _pickedStreamIndices.clear();
      _evaluating = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _canInteract) _playStream();
    });

    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
    }
  }

  Future<void> _changeSpeed(int speedId) async {
    if (speedId == _speedId) return;
    unawaited(AppFeedback.tap());
    _pauseStream();

    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(speedId);

    final returning = List<int>.from(_pickedStreamIndices);
    setState(() {
      _speedId = speedId;
      _pickedStreamIndices.clear();
      for (final streamIndex in returning) {
        _trainQueue.add(streamIndex);
        if (_usesPathCars) {
          _placeReturnedOnPath(streamIndex);
        }
      }
    });

    if (_task != null && hasStencilAttemptsLeft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playStream();
      });
    }

    if (!hasStencilAttemptsLeft) {
      setState(() => _task = null);
      await showStencilAttemptsExhaustedDialog();
      return;
    }

    if (_task == null) {
      _startNewTask();
    }
  }

  Widget _buildSyllableSnake(RsvpTask task) {
    final track = _playfieldTrack;
    final snakePath = track != null && _usesSnakePath(track);
    final chaosPath = track != null && _usesChaosPath(track);
    return _SyllableSnake(
      syllables: task.streamSyllables,
      trainQueue: _trainQueue,
      headDistance: _headDistance,
      movementModeId: _movementModeId,
      pathCars: _chaosCars,
      usesPathCars: _usesPathCars,
      crossRowWrap: snakePath || chaosPath,
      multiRowSnake: snakePath,
      multiRowChaos: chaosPath,
      onTrackReady: _ensurePlayfieldTrack,
      carWidth: _trainCarWidth,
      carHeight: _trainCarHeight,
      carGap: _trainCarGap,
      rowGap: _playfieldRowGap,
      canCatch: _canInteract && _streamPlaying,
      onCatch: _catchSyllable,
    );
  }

  void _changeMovementMode(int modeId) {
    if (modeId == _movementModeId) return;
    unawaited(AppFeedback.tap());
    final switchingToChaos =
        modeId == RsvpMovementMode.chaos &&
        _movementModeId != RsvpMovementMode.chaos;
    setState(() {
      _movementModeId = modeId;
      _resetPathSimulation();
      _headDistance = 0;
    });
    if (switchingToChaos && hasStencilAttemptsLeft) {
      _startNewTask();
      return;
    }
    if (_usesPathCars && _trainQueue.isNotEmpty) {
      final track = _activePathTrack();
      if (track != null) {
        if (_streamPlaying) {
          _initPathCars(track);
        } else {
          _ensurePlayfieldTrack(track);
        }
      }
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
                  Text(
                    _displayWord,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Поймай слоги и собери слово',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  _AssemblyLine(
                    lineKey: _assemblyKey,
                    pickedSyllables: picked,
                    panelHeight: _assemblyPanelHeight,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: picked.isNotEmpty && _canInteract
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
                        onPressed: picked.isNotEmpty &&
                                !_evaluating &&
                                !stencilAnimating
                            ? () => unawaited(_onSubmit())
                            : null,
                        child: const Text('Готово'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: _usesFixedPlayfield
                          ? SizedBox(
                              height: _playfieldHeight,
                              width: double.infinity,
                              child: _buildSyllableSnake(task),
                            )
                          : _buildSyllableSnake(task),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Бегущая строка'),
      actions: [
        IconButton(
          tooltip: 'Новая строка',
          onPressed: _canPressDone
              ? () {
                  unawaited(AppFeedback.tap());
                  _startNewTask();
                }
              : null,
          icon: const Icon(Icons.refresh),
        ),
        PopupMenuButton<int>(
          tooltip: 'Режим',
          initialValue: _movementModeId,
          onSelected: _changeMovementMode,
          itemBuilder: (ctx) => [
            for (final mode in RsvpMovementMode.all)
              PopupMenuItem(
                value: mode,
                child: Text(RsvpMovementMode.label(mode)),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(RsvpMovementMode.label(_movementModeId)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'Скорость',
          initialValue: _speedId,
          onSelected: _changeSpeed,
          itemBuilder: (ctx) => [
            for (final speed in RsvpSpeed.all)
              PopupMenuItem(
                value: speed,
                child: Text(RsvpSpeed.label(speed)),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(RsvpSpeed.label(_speedId)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SyllableSnake extends StatelessWidget {
  const _SyllableSnake({
    required this.syllables,
    required this.trainQueue,
    required this.headDistance,
    required this.movementModeId,
    required this.pathCars,
    required this.usesPathCars,
    required this.crossRowWrap,
    required this.multiRowSnake,
    required this.multiRowChaos,
    required this.onTrackReady,
    required this.carWidth,
    required this.carHeight,
    required this.carGap,
    required this.rowGap,
    required this.canCatch,
    required this.onCatch,
  });

  final List<String> syllables;
  final List<int> trainQueue;
  final double headDistance;
  final int movementModeId;
  final Map<int, RsvpChaosCarState> pathCars;
  final bool usesPathCars;
  final bool crossRowWrap;
  final bool multiRowSnake;
  final bool multiRowChaos;
  final ValueChanged<RsvpSnakeTrack> onTrackReady;
  final double carWidth;
  final double carHeight;
  final double carGap;
  final double rowGap;
  final bool canCatch;
  final ValueChanged<int> onCatch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final track = RsvpSnakeTrack(
              laneWidth: constraints.maxWidth,
              laneHeight: constraints.maxHeight,
              carWidth: carWidth,
              carHeight: carHeight,
              carGap: carGap,
              rowGap: rowGap,
            );
        onTrackReady(track);
        final pitch = track.pitch;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var queueIndex = 0;
                    queueIndex < trainQueue.length;
                    queueIndex++)
                  if (_carVisible(track, pitch, queueIndex))
                    for (final pos in _carPositions(
                      track,
                      pitch,
                      trainQueue[queueIndex],
                    ))
                      if (!usesPathCars || track.intersectsLane(pos))
                        Positioned(
                          left: pos.dx - SyllableTapTarget.hitSlop,
                          top: pos.dy - SyllableTapTarget.hitSlop,
                          child: _TrainCar(
                            text: syllables[trainQueue[queueIndex]],
                            width: carWidth,
                            height: carHeight,
                            onTap: () => onCatch(trainQueue[queueIndex]),
                            enabled: canCatch,
                          ),
                        ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _carDistance(double pitch, int queueIndex) =>
      headDistance - queueIndex * pitch;

  List<Offset> _carPositions(
    RsvpSnakeTrack track,
    double pitch,
    int streamIndex,
  ) {
    if (usesPathCars) {
      final state = pathCars[streamIndex];
      if (state == null) return const [];
      if (multiRowChaos) {
        return RsvpChaosLayout.multiRowChaosPositions(
          track,
          state.distance,
          crossRowWrap: crossRowWrap,
        );
      }
      if (multiRowSnake) {
        return RsvpChaosLayout.multiRowSnakePositions(
          track,
          state.distance,
          crossRowWrap: crossRowWrap,
        );
      }
      return track.chaosCarPositionsAt(
        row: state.row,
        distance: state.distance,
        crossRowWrap: crossRowWrap,
      );
    }
    final queueIndex = trainQueue.indexOf(streamIndex);
    if (queueIndex < 0) return const [];
    return [track.snakeCarPosition(_carDistance(pitch, queueIndex))];
  }

  bool _carVisible(RsvpSnakeTrack track, double pitch, int queueIndex) {
    final streamIndex = trainQueue[queueIndex];
    if (!usesPathCars) {
      final distance = _carDistance(pitch, queueIndex);
      if (distance < 0) return false;
      return track.visibleInLane(track.snakeCarPosition(distance));
    }
    if (!pathCars.containsKey(streamIndex)) {
      return false;
    }
    return _carPositions(track, pitch, streamIndex)
        .any(track.intersectsLane);
  }
}

class _TrainCar extends StatelessWidget {
  const _TrainCar({
    required this.text,
    required this.width,
    required this.height,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final double width;
  final double height;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SyllableTapTarget(
      enabled: enabled,
      onActivated: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline, width: 2),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _AssemblyLine extends StatelessWidget {
  const _AssemblyLine({
    required this.lineKey,
    required this.pickedSyllables,
    required this.panelHeight,
  });

  final GlobalKey lineKey;
  final List<String> pickedSyllables;
  final double panelHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return KeyedSubtree(
      key: lineKey,
      child: Container(
        width: double.infinity,
        height: panelHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline, width: 2),
        ),
        alignment: Alignment.center,
        child: pickedSyllables.isEmpty
            ? Text(
                'Слоги появятся здесь',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pickedSyllables.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.outline),
                        ),
                        child: Text(
                          pickedSyllables[i],
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
