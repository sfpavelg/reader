import 'dart:async';

import 'package:flutter/material.dart';

import '../gamification/rewards_service.dart';
import '../gamification/trainer_reward_feedback.dart';
import '../gamification/trainer_stencil_progress.dart';
import '../widgets/star_stencil_bar.dart';
import '../widgets/tach_star_animations.dart';
import 'trainer_stars_mixin.dart';

/// Трафарет из 5 звёзд, полёты, рассыпание и дневной лимит попыток.
mixin TrainerStencilStarsMixin<T extends StatefulWidget>
    on State<T>, TrainerStarsMixin<T> {
  static const starSlotWidth = 26.0;

  final stackKey = GlobalKey();
  final stencilBarKey = GlobalKey();
  final walletKey = GlobalKey();

  late TrainerStencilProgressStore stencilStore;
  TrainerStencilProgress stencilProgress =
      const TrainerStencilProgress(dateKey: '', dailyAttemptLimit: 20);

  int stencilFilled = 0;
  int? shatterStencilIndex;
  Offset? shatterCenter;
  Color shatterColor = StarStencilBar.paleYellow;

  Offset? flightFrom;
  Offset? flightTo;
  VoidCallback? flightOnComplete;
  bool flightZigzag = false;
  int flightGeneration = 0;
  bool walletBatchRunning = false;

  final List<_StencilAnimJob> _stencilAnimQueue = [];
  bool _stencilAnimPumpRunning = false;

  bool pendingAttemptsDialog = false;
  bool attemptsDialogVisible = false;

  bool perLevelAttempts = false;
  int? activeAttemptLevelId;

  /// Идёт визуальная анимация звёзд (не должна блокировать ввод).
  bool get stencilAnimating =>
      flightFrom != null ||
      shatterCenter != null ||
      walletBatchRunning ||
      _stencilAnimPumpRunning ||
      _stencilAnimQueue.isNotEmpty;

  bool get hasStencilAttemptsLeft {
    if (perLevelAttempts && activeAttemptLevelId != null) {
      return stencilProgress.hasAttemptsLeftForLevel(activeAttemptLevelId!);
    }
    return stencilProgress.hasAttemptsLeft;
  }

  int get currentStencilAttemptsUsed {
    if (perLevelAttempts && activeAttemptLevelId != null) {
      return stencilProgress.attemptsUsedForLevel(activeAttemptLevelId!);
    }
    return stencilProgress.attemptsUsed;
  }

  void initStencilStars({
    required String storageKey,
    required int dailyAttemptLimit,
    bool perLevelAttempts = false,
  }) {
    this.perLevelAttempts = perLevelAttempts;
    stencilStore = TrainerStencilProgressStore(
      storageKey: storageKey,
      dailyAttemptLimit: dailyAttemptLimit,
    );
    stencilProgress = stencilStore.load();
    _loadStencilFilledForActiveLevel();
  }

  void syncStencilAttemptLevel(int levelId) {
    activeAttemptLevelId = levelId;
    _loadStencilFilledForActiveLevel();
  }

  void _loadStencilFilledForActiveLevel() {
    if (perLevelAttempts && activeAttemptLevelId != null) {
      stencilFilled =
          stencilProgress.stencilFilledForLevel(activeAttemptLevelId!);
    } else {
      stencilFilled = stencilProgress.stencilFilled;
    }
  }

  Future<void> persistStencilProgress({int? filled}) async {
    if (filled != null) stencilFilled = filled;

    if (perLevelAttempts && activeAttemptLevelId != null) {
      final byLevel = Map<String, int>.from(stencilProgress.stencilFilledByLevel);
      byLevel['$activeAttemptLevelId'] = stencilFilled;
      stencilProgress = stencilProgress.copyWith(
        stencilFilled: stencilFilled,
        stencilFilledByLevel: byLevel,
      );
    } else {
      stencilProgress = stencilProgress.copyWith(stencilFilled: stencilFilled);
    }
    await stencilStore.persist(stencilProgress);
  }

  Future<void> consumeStencilAttempt() async {
    if (perLevelAttempts && activeAttemptLevelId != null) {
      stencilProgress = stencilProgress.registerAttemptForLevel(
        activeAttemptLevelId!,
      );
      if (!stencilProgress.hasAttemptsLeftForLevel(activeAttemptLevelId!)) {
        pendingAttemptsDialog = true;
      }
    } else {
      stencilProgress = stencilProgress.registerAttempt();
      if (!stencilProgress.hasAttemptsLeft) {
        pendingAttemptsDialog = true;
      }
    }
    await stencilStore.persist(stencilProgress);
    if (mounted) setState(() {});
  }

  Future<void> showStencilAttemptsExhaustedDialog() async {
    if (attemptsDialogVisible || !mounted) return;
    attemptsDialogVisible = true;
    pendingAttemptsDialog = false;

    final colors = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.emoji_events_rounded, color: colors.primary, size: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ты молодец!', textAlign: TextAlign.center),
        content: const Text(
          'Сегодня ты отлично потренировался! '
          'Попытки на сегодня закончились — отдохни и приходи завтра.',
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

    if (mounted) attemptsDialogVisible = false;
  }

  void maybeShowStencilAttemptsDialog() {
    final exhausted = perLevelAttempts && activeAttemptLevelId != null
        ? !stencilProgress.hasAttemptsLeftForLevel(activeAttemptLevelId!)
        : !stencilProgress.hasAttemptsLeft;
    if (exhausted && pendingAttemptsDialog) {
      unawaited(showStencilAttemptsExhaustedDialog());
    }
  }

  Offset? globalCenter(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft + Offset(box.size.width / 2, box.size.height / 2);
  }

  Offset toStackLocal(Offset global) {
    final box = stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  Offset? stencilSlotCenter(int index) {
    final barCenter = globalCenter(stencilBarKey);
    if (barCenter == null) return null;
    final totalWidth = StarStencilBar.stencilCount * starSlotWidth - 4;
    final startX = barCenter.dx - totalWidth / 2 + starSlotWidth / 2;
    return Offset(startX + index * starSlotWidth, barCenter.dy);
  }

  void startFlight({
    required Offset from,
    required Offset to,
    required VoidCallback onComplete,
    bool zigzag = false,
  }) {
    final localFrom = toStackLocal(from);
    final localTo = toStackLocal(to);
    final generation = ++flightGeneration;

    setState(() {
      flightFrom = localFrom;
      flightTo = localTo;
      flightZigzag = zigzag;
      flightOnComplete = () {
        if (generation != flightGeneration) return;
        setState(() {
          flightFrom = null;
          flightTo = null;
          flightOnComplete = null;
          flightZigzag = false;
        });
        onComplete();
      };
    });
  }

  Future<void> runFlight({
    required Offset from,
    required Offset to,
    bool zigzag = false,
  }) async {
    final completer = Completer<void>();
    var finished = false;
    void completeOnce() {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) completer.complete();
    }

    startFlight(from: from, to: to, zigzag: zigzag, onComplete: completeOnce);
    await WidgetsBinding.instance.endOfFrame;

    try {
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: completeOnce,
      );
    } catch (_) {
      completeOnce();
    }

    if (!finished) completeOnce();
  }

  void startShatter({
    required Offset center,
    required VoidCallback onComplete,
    Color color = StarStencilBar.paleYellow,
  }) {
    final local = toStackLocal(center);
    shatterOnComplete = onComplete;
    setState(() {
      shatterCenter = local;
      shatterColor = color;
    });
  }

  VoidCallback? shatterOnComplete;

  void onShatterComplete() {
    final done = shatterOnComplete;
    setState(() {
      shatterCenter = null;
      shatterStencilIndex = null;
      shatterOnComplete = null;
    });
    done?.call();
  }

  /// Ставит анимацию звёзд в очередь и сразу возвращается — ввод не ждёт.
  Future<void> reactStencilToAnswer({
    required bool correct,
    required GlobalKey flightOriginKey,
    required String rewardTrainerId,
    int starSlots = 1,
  }) async {
    _stencilAnimQueue.add(
      _StencilAnimJob(
        correct: correct,
        flightOriginKey: flightOriginKey,
        rewardTrainerId: rewardTrainerId,
        starSlots: starSlots < 1 ? 1 : starSlots,
      ),
    );
    unawaited(_pumpStencilAnimQueue());
  }

  Future<void> _pumpStencilAnimQueue() async {
    if (_stencilAnimPumpRunning) return;
    _stencilAnimPumpRunning = true;
    try {
      while (_stencilAnimQueue.isNotEmpty && mounted) {
        final job = _stencilAnimQueue.removeAt(0);
        if (job.correct) {
          await onCorrectStencilFlow(
            flightOriginKey: job.flightOriginKey,
            rewardTrainerId: job.rewardTrainerId,
            starSlots: job.starSlots,
          );
        } else {
          await onWrongStencilFlow();
        }
      }
    } finally {
      _stencilAnimPumpRunning = false;
      if (mounted && _stencilAnimQueue.isNotEmpty) {
        unawaited(_pumpStencilAnimQueue());
      }
    }
  }

  Future<(Offset?, Offset?)> resolveFlightEndpoints({
    required GlobalKey originKey,
    required int stencilIndex,
  }) async {
    for (var i = 0; i < 4; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return (null, null);
      final from = globalCenter(originKey);
      final to = stencilSlotCenter(stencilIndex);
      if (from != null && to != null) return (from, to);
    }
    return (null, null);
  }

  Future<void> onCorrectStencilFlow({
    required GlobalKey flightOriginKey,
    required String rewardTrainerId,
    int starSlots = 1,
  }) async {
    final slots = starSlots < 1 ? 1 : starSlots;
    for (var i = 0; i < slots; i++) {
      if (!mounted) return;

      if (stencilFilled >= StarStencilBar.stencilCount) {
        await flyAllStencilsToWallet(rewardTrainerId: rewardTrainerId);
      }
      if (!mounted || stencilFilled >= StarStencilBar.stencilCount) continue;

      final targetIndex = stencilFilled;
      final (from, to) = await resolveFlightEndpoints(
        originKey: flightOriginKey,
        stencilIndex: targetIndex,
      );

      if (from == null || to == null) {
        setState(() => stencilFilled = (stencilFilled + 1).clamp(0, 5));
        await persistStencilProgress();
        if (stencilFilled >= StarStencilBar.stencilCount) {
          await flyAllStencilsToWallet(rewardTrainerId: rewardTrainerId);
        }
        continue;
      }

      await runFlight(from: from, to: to, zigzag: true);
      if (!mounted) return;

      setState(() => stencilFilled++);
      await persistStencilProgress();
      if (stencilFilled >= StarStencilBar.stencilCount) {
        await flyAllStencilsToWallet(rewardTrainerId: rewardTrainerId);
      }
    }
  }

  Future<void> onWrongStencilFlow() async {
    if (stencilFilled > 0) {
      final idx = stencilFilled - 1;
      final center = stencilSlotCenter(idx);
      if (center == null) {
        setState(() => stencilFilled--);
        await persistStencilProgress();
        return;
      }

      final completer = Completer<void>();
      void completeOnce() {
        if (!completer.isCompleted) completer.complete();
      }

      setState(() => shatterStencilIndex = idx);
      startShatter(
        center: center,
        color: StarStencilBar.paleYellow,
        onComplete: () {
          unawaited(() async {
            setState(() => stencilFilled--);
            await persistStencilProgress();
            completeOnce();
          }());
        },
      );
      try {
        await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: completeOnce,
        );
      } catch (_) {
        completeOnce();
      }
      return;
    }

    final wallet = globalCenter(walletKey);
    if (wallet == null) {
      await penalizeWalletStencilStar();
      return;
    }

    final completer = Completer<void>();
    void completeOnce() {
      if (!completer.isCompleted) completer.complete();
    }

    startShatter(
      center: wallet,
      color: const Color(0xFFFFD54F),
      onComplete: () {
        unawaited(() async {
          await penalizeWalletStencilStar();
          completeOnce();
        }());
      },
    );
    try {
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: completeOnce,
      );
    } catch (_) {
      completeOnce();
    }
  }

  Future<void> flyAllStencilsToWallet({required String rewardTrainerId}) async {
    if (walletBatchRunning) return;
    walletBatchRunning = true;

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final wallet = globalCenter(walletKey);
      if (wallet == null) {
        await grantStencilReward(rewardTrainerId);
        setState(() => stencilFilled = 0);
        await persistStencilProgress(filled: 0);
        return;
      }

      for (var i = 0; i < StarStencilBar.stencilCount; i++) {
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;

        final from = stencilSlotCenter(i);
        if (from == null) {
          setState(() => stencilFilled = (stencilFilled - 1).clamp(0, 5));
          await persistStencilProgress();
          continue;
        }

        await runFlight(from: from, to: wallet);
        if (!mounted) return;
        setState(() => stencilFilled = (stencilFilled - 1).clamp(0, 5));
        await persistStencilProgress();
        await Future<void>.delayed(const Duration(milliseconds: 12));
      }

      if (!mounted) return;
      await grantStencilReward(rewardTrainerId);
      setState(() => stencilFilled = 0);
      await persistStencilProgress(filled: 0);
    } finally {
      walletBatchRunning = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> grantStencilReward(String trainerId) async {
    await grantTrainerReward(
      context,
      trainerId: trainerId,
      showSnackBar: false,
    );
    reloadTrainerStars();
  }

  Future<void> penalizeWalletStencilStar() async {
    await RewardsService.penalizeTrainerFailure();
    if (!mounted) return;
    reloadTrainerStars();
    setState(() => stencilFilled = 4);
    await persistStencilProgress(filled: 4);
  }

  void clearStencilFlightState() {
    _stencilAnimQueue.clear();
    flightGeneration++;
    flightFrom = null;
    flightTo = null;
    flightOnComplete = null;
    flightZigzag = false;
    shatterCenter = null;
    shatterStencilIndex = null;
    shatterOnComplete = null;
    walletBatchRunning = false;
  }

  List<Widget> buildStencilStarOverlays() {
    return [
      if (flightFrom != null && flightTo != null)
        FlyingStarOverlay(
          key: ValueKey(flightGeneration),
          from: flightFrom!,
          to: flightTo!,
          zigzag: flightZigzag,
          onComplete: flightOnComplete ?? () {},
        ),
      if (shatterCenter != null)
        ShatterStarOverlay(
          center: shatterCenter!,
          color: shatterColor,
          onComplete: onShatterComplete,
        ),
    ];
  }

  Widget buildStencilHeader() {
    return TachStarsHeader(
      stencilFilled: stencilFilled,
      walletStars: trainerStars,
      shatterStencilIndex: shatterStencilIndex,
      stencilBarKey: stencilBarKey,
      walletKey: walletKey,
    );
  }

  Widget buildAttemptsCounter() {
    return Text(
      'Попытки: $currentStencilAttemptsUsed из '
      '${stencilProgress.dailyAttemptLimit}',
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }
}

class _StencilAnimJob {
  const _StencilAnimJob({
    required this.correct,
    required this.flightOriginKey,
    required this.rewardTrainerId,
    required this.starSlots,
  });

  final bool correct;
  final GlobalKey flightOriginKey;
  final String rewardTrainerId;
  final int starSlots;
}
