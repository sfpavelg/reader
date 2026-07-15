import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../app/trainer_ids.dart';
import '../../main.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../widgets/trainer_start_prompt.dart';
import '../../trainers/tachistoscope/tachistoscope_generator.dart';
import '../../trainers/tachistoscope/tachistoscope_session_state.dart';
import '../../trainers/tachistoscope/tachistoscope_session_store.dart';
import '../../trainers/tachistoscope/tachistoscope_task.dart';

enum _TachPhase { ready, flashing, choosing, feedback, animating }

class TachistoscopeScreen extends ConsumerStatefulWidget {
  const TachistoscopeScreen({super.key});

  @override
  ConsumerState<TachistoscopeScreen> createState() =>
      _TachistoscopeScreenState();
}

class _TachistoscopeScreenState extends ConsumerState<TachistoscopeScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _feedbackPause = Duration(milliseconds: 400);
  static const _sharedStorageKey = 'tachistoscope_shared';
  static const _dailyAttemptLimit = 20;

  final _flashCardKey = GlobalKey();

  int _levelId = 1;
  bool _ready = false;
  bool _loaded = false;

  TachistoscopeSessionState _session = const TachistoscopeSessionState();
  List<String> _recentTargetIds = const [];

  TachistoscopeTask? _task;
  _TachPhase _phase = _TachPhase.ready;
  int? _selectedIndex;
  bool? _lastCorrect;

  Timer? _flashTimer;
  Timer? _feedbackTimer;

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
      syncStencilAttemptLevel(_levelId);
      _restoreAndStart();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _restoreAndStart() {
    _session = TachistoscopeSessionStore.loadSession(_levelId);
    _recentTargetIds = List<String>.from(
      TachistoscopeSessionStore.loadRecentTargetIds(_levelId),
    );
    if (!hasStencilAttemptsLeft) {
      _task = null;
      _loaded = true;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showStencilAttemptsExhaustedDialog());
      });
      return;
    }
    _startRound();
    _loaded = true;
  }

  void _cancelTimers() {
    _flashTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  void _startRound() {
    _cancelTimers();
    if (!hasStencilAttemptsLeft) {
      setState(() => _task = null);
      return;
    }

    final dictionary = ref.read(dictionaryServiceProvider);
    final generator = TachistoscopeGenerator(dictionary: dictionary);
    final task = generator.generate(
      levelId: _levelId,
      session: _session,
      recentTargetIds: _recentTargetIds.toSet(),
    );

    clearStencilFlightState();
    setState(() {
      _task = task;
      _phase = _TachPhase.ready;
      _selectedIndex = null;
      _lastCorrect = null;
    });
  }

  void _onFlashCardTap() {
    final task = _task;
    if (task == null ||
        _phase != _TachPhase.ready ||
        !hasStencilAttemptsLeft) {
      return;
    }

    unawaited(AppFeedback.tap());
    setState(() => _phase = _TachPhase.flashing);

    _flashTimer = Timer(task.flashDuration, () {
      if (!mounted) return;
      setState(() => _phase = _TachPhase.choosing);
    });
  }

  void _finishAnimationAndNextRound() {
    if (!mounted) return;
    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
      setState(() => _task = null);
      return;
    }
    _startRound();
  }

  Future<void> _handleStarReaction(bool correct) async {
    setState(() => _phase = _TachPhase.animating);
    await reactStencilToAnswer(
      correct: correct,
      flightOriginKey: _flashCardKey,
      rewardTrainerId: TrainerIds.tachistoscope,
    );
    if (!mounted) return;
    reloadTrainerStars();
    _finishAnimationAndNextRound();
  }

  Future<void> _onOptionTap(int index) async {
    final task = _task;
    if (task == null ||
        _phase != _TachPhase.choosing ||
        !hasStencilAttemptsLeft) {
      return;
    }

    final correct = task.isCorrect(index);
    final nextSession = _session.registerAnswer(isCorrect: correct);
    final nextRecent = TachistoscopeSessionStore.bumpRecent(
      _recentTargetIds,
      task.target.id,
    );

    if (correct) {
      unawaited(AppFeedback.success());
    } else {
      unawaited(AppFeedback.softHint());
    }

    setState(() {
      _phase = _TachPhase.feedback;
      _selectedIndex = index;
      _lastCorrect = correct;
      _session = nextSession;
      _recentTargetIds = nextRecent;
    });

    await TachistoscopeSessionStore.persist(
      levelId: _levelId,
      session: nextSession,
      recentTargetIds: nextRecent,
    );
    await consumeStencilAttempt();

    _feedbackTimer = Timer(_feedbackPause, () {
      if (!mounted) return;
      unawaited(_handleStarReaction(correct));
    });
  }

  Future<void> _changeLevel(int levelId) async {
    if (levelId == _levelId) return;
    unawaited(AppFeedback.tap());
    _cancelTimers();
    stencilProgress = stencilStore.load();
    syncStencilAttemptLevel(levelId);
    setState(() {
      _levelId = levelId;
    });
    _session = TachistoscopeSessionStore.loadSession(levelId);
    _recentTargetIds = List<String>.from(
      TachistoscopeSessionStore.loadRecentTargetIds(levelId),
    );
    if (!hasStencilAttemptsLeft) {
      setState(() => _task = null);
      await showStencilAttemptsExhaustedDialog();
      return;
    }
    _startRound();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Вспышка'),
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Уровень',
          initialValue: _levelId,
          onSelected: _changeLevel,
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 1, child: Text('Слоги')),
            PopupMenuItem(value: 2, child: Text('Слова')),
            PopupMenuItem(value: 3, child: Text('Фразы')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(_levelLabel(_levelId)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _levelLabel(int levelId) {
    switch (levelId) {
      case 2:
        return 'Слова';
      case 3:
        return 'Фразы';
      default:
        return 'Слоги';
    }
  }

  String _targetKindLabel() {
    switch (_levelId) {
      case 2:
        return 'слово';
      case 3:
        return 'фразу';
      default:
        return 'слог';
    }
  }

  String _phaseTitle() {
    return switch (_phase) {
      _TachPhase.ready => 'Готов?',
      _TachPhase.flashing => 'Запомни ${_targetKindLabel()}',
      _TachPhase.choosing => 'Что ты видел?',
      _TachPhase.feedback =>
        _lastCorrect == true ? 'Верно!' : 'Попробуем ещё раз',
      _TachPhase.animating => 'Отлично!',
    };
  }

  String _phaseSubtitle(TachistoscopeTask task) {
    final flashSeconds = (task.flashDuration.inMilliseconds / 1000)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    return switch (_phase) {
      _TachPhase.ready => 'Нажми на «?», чтобы увидеть ${_targetKindLabel()}',
      _TachPhase.flashing => 'Вспышка: $flashSeconds с',
      _TachPhase.choosing => 'Выбери правильный ответ',
      _TachPhase.feedback => 'Выбери правильный ответ',
      _TachPhase.animating => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
    final showTarget = _phase == _TachPhase.flashing;
    final showChoices =
        _phase == _TachPhase.choosing || _phase == _TachPhase.feedback;
    final interactionsLocked =
        _phase == _TachPhase.animating ||
        _phase == _TachPhase.feedback ||
        !hasStencilAttemptsLeft;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          key: stackKey,
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildStencilHeader(),
                  const SizedBox(height: 12),
                  Text(
                    _phaseTitle(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_phaseSubtitle(task).isNotEmpty)
                    Text(
                      _phaseSubtitle(task),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 2,
                    child: _FlashCard(
                      cardKey: _flashCardKey,
                      showTarget: showTarget,
                      ready: _phase == _TachPhase.ready,
                      choosing: _phase == _TachPhase.choosing,
                      feedback: _phase == _TachPhase.feedback,
                      text: task.target.text,
                      lastCorrect: _lastCorrect,
                      onReadyTap: interactionsLocked ? null : _onFlashCardTap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 3,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: showChoices
                          ? Column(
                              key: const ValueKey('choices'),
                              children: [
                                for (var i = 0; i < task.options.length; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _OptionButton(
                                        label: task.options[i].label,
                                        onTap: () => _onOptionTap(i),
                                        enabled: _phase == _TachPhase.choosing,
                                        backgroundColor: _optionColor(
                                          colors: colors,
                                          index: i,
                                          task: task,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Center(
                              key: ValueKey('waiting_${_phase.name}'),
                              child: Text(
                                _phase == _TachPhase.ready
                                    ? '👆'
                                    : _phase == _TachPhase.flashing
                                        ? '👀'
                                        : '',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildAttemptsCounter(),
                  if (_lastCorrect == false && _phase == _TachPhase.feedback)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Было: ${task.target.text}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            ...buildStencilStarOverlays(),
          ],
        ),
      ),
    );
  }

  Color _optionColor({
    required ColorScheme colors,
    required int index,
    required TachistoscopeTask task,
  }) {
    if (_phase != _TachPhase.feedback) {
      return colors.primaryContainer;
    }

    if (index == task.correctIndex) {
      return colors.primaryContainer;
    }
    if (index == _selectedIndex) {
      return colors.tertiaryContainer;
    }
    return colors.surfaceContainerHighest;
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({
    required this.cardKey,
    required this.showTarget,
    required this.ready,
    required this.choosing,
    required this.feedback,
    required this.text,
    required this.lastCorrect,
    required this.onReadyTap,
  });

  final GlobalKey cardKey;
  final bool showTarget;
  final bool ready;
  final bool choosing;
  final bool feedback;
  final String text;
  final bool? lastCorrect;
  final VoidCallback? onReadyTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pulsing = ready && onReadyTap != null;

    return KeyedSubtree(
      key: cardKey,
      child: PulsingShimmerPanel(
        onTap: onReadyTap,
        active: pulsing,
        emphasized: showTarget,
        baseColor: showTarget
            ? colors.primaryContainer.withValues(alpha: 0.75)
            : colors.surfaceContainerHighest,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: showTarget
                ? Text(
                    text,
                    key: ValueKey(text),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: colors.onPrimaryContainer,
                        ),
                  )
                : Text(
                    ready
                        ? '?'
                        : choosing
                            ? '?'
                            : (lastCorrect == true ? '✓' : '…'),
                    key: ValueKey(
                      ready
                          ? 'ready'
                          : choosing
                              ? 'choose'
                              : 'fb',
                    ),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ready || choosing
                              ? colors.onSurfaceVariant
                              : colors.primary,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: SyllableTapTarget(
        enabled: enabled,
        onActivated: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
