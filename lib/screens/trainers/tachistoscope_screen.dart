import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../app/trainer_ids.dart';
import '../../gamification/trainer_reward_feedback.dart';
import '../../main.dart';
import '../../trainers/tachistoscope/tachistoscope_generator.dart';
import '../../trainers/tachistoscope/tachistoscope_session_state.dart';
import '../../trainers/tachistoscope/tachistoscope_session_store.dart';
import '../../trainers/tachistoscope/tachistoscope_task.dart';

enum _TachPhase { flashing, choosing, feedback }

class TachistoscopeScreen extends ConsumerStatefulWidget {
  const TachistoscopeScreen({super.key});

  @override
  ConsumerState<TachistoscopeScreen> createState() =>
      _TachistoscopeScreenState();
}

class _TachistoscopeScreenState extends ConsumerState<TachistoscopeScreen> {
  static const _feedbackPause = Duration(milliseconds: 650);

  int _levelId = 1;
  bool _ready = false;

  TachistoscopeSessionState _session = const TachistoscopeSessionState();
  List<String> _recentTargetIds = const [];

  TachistoscopeTask? _task;
  _TachPhase _phase = _TachPhase.flashing;
  bool _wordVisible = false;
  int? _selectedIndex;
  bool? _lastCorrect;

  Timer? _flashTimer;
  Timer? _feedbackTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
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
    _recentTargetIds =
        List<String>.from(TachistoscopeSessionStore.loadRecentTargetIds(_levelId));
    _startRound();
  }

  void _startRound() {
    _flashTimer?.cancel();
    _feedbackTimer?.cancel();

    final dictionary = ref.read(dictionaryServiceProvider);
    final generator = TachistoscopeGenerator(dictionary: dictionary);
    final task = generator.generate(
      levelId: _levelId,
      session: _session,
      recentTargetIds: _recentTargetIds.toSet(),
    );

    setState(() {
      _task = task;
      _phase = _TachPhase.flashing;
      _wordVisible = true;
      _selectedIndex = null;
      _lastCorrect = null;
    });

    _flashTimer = Timer(task.flashDuration, () {
      if (!mounted) return;
      setState(() {
        _wordVisible = false;
        _phase = _TachPhase.choosing;
      });
    });
  }

  Future<void> _onOptionTap(int index) async {
    final task = _task;
    if (task == null || _phase != _TachPhase.choosing) return;

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

    if (correct && nextSession.tasksCompleted % 5 == 0 && mounted) {
      await grantTrainerReward(context, trainerId: TrainerIds.tachistoscope);
    }

    _feedbackTimer = Timer(_feedbackPause, () {
      if (!mounted) return;
      _startRound();
    });
  }

  Future<void> _changeLevel(int levelId) async {
    if (levelId == _levelId) return;
    unawaited(AppFeedback.tap());
    setState(() => _levelId = levelId);
    _session = TachistoscopeSessionStore.loadSession(levelId);
    _recentTargetIds =
        List<String>.from(TachistoscopeSessionStore.loadRecentTargetIds(levelId));
    _startRound();
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
    final flashSeconds = (task.flashDuration.inMilliseconds / 1000)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вспышки'),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _phase == _TachPhase.flashing
                    ? 'Запомни слово'
                    : 'Что ты видел?',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Вспышка: $flashSeconds с',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 2,
                child: RepaintBoundary(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _wordVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: _wordVisible ? 1 : 0.96,
                        duration: const Duration(milliseconds: 120),
                        child: Text(
                          task.target.text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: AnimatedOpacity(
                  opacity: _phase == _TachPhase.flashing ? 0.35 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: _phase != _TachPhase.choosing &&
                        _phase != _TachPhase.feedback,
                    child: Column(
                      children: [
                        for (var i = 0; i < task.options.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OptionButton(
                                label: task.options[i].label,
                                onTap: () => _onOptionTap(i),
                                backgroundColor: _optionColor(
                                  colors: colors,
                                  index: i,
                                  task: task,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Верно: ${_session.correctAnswers} из ${_session.tasksCompleted}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_lastCorrect == false && _phase == _TachPhase.feedback)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Было: ${task.target.text}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                  ),
                ),
            ],
          ),
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
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
