import 'dart:async';

import 'package:flutter/material.dart';

import '../../../mixins/trainer_stars_mixin.dart';
import '../../../mixins/trainer_stencil_stars_mixin.dart';
import '../../../trainers/math/math_problem.dart';
import '../../../trainers/math/math_problem_generator.dart';
import '../../../trainers/math/math_problem_kind.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/math_dots_visual.dart';

/// Универсальный экран с вариантами ответа для математических тренажёров.
class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({
    super.key,
    required this.kind,
    this.multiplyRow = 2,
  });

  final MathProblemKind kind;
  final int multiplyRow;

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen>
    with TrainerStarsMixin, TrainerStencilStarsMixin {
  static const _dailyAttemptLimit = 20;
  static const _speedBonusSeconds = 3;
  static const _correctRevealPause = Duration(milliseconds: 900);

  late final MathProblemGenerator _generator;
  MathProblem? _problem;
  bool _loaded = false;
  bool _evaluating = false;
  bool _answeredCorrectly = false;
  int? _selectedAnswer;
  int _secondsLeft = _speedBonusSeconds;
  bool _speedBonusActive = true;
  bool? _earnedSpeedBonus;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _generator = MathProblemGenerator();
    initTrainerStars();
    initStencilStars(
      storageKey: '${widget.kind.trainerId}_shared',
      dailyAttemptLimit: _dailyAttemptLimit,
    );
    _bootstrap();
  }

  void _bootstrap() {
    if (!hasStencilAttemptsLeft) {
      setState(() => _loaded = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(showStencilAttemptsExhaustedDialog());
      });
      return;
    }
    _nextProblem(setLoaded: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _usesSpeedBonus => widget.kind.usesSpeedBonus;

  void _startSpeedTimer() {
    _countdownTimer?.cancel();
    _secondsLeft = _speedBonusSeconds;
    _speedBonusActive = true;
    _runSpeedCountdown();
  }

  /// Продолжает текущий отсчёт без обнуления (после ошибочного ответа).
  void _resumeSpeedTimer() {
    _countdownTimer?.cancel();
    if (!_speedBonusActive || _secondsLeft <= 0) {
      _secondsLeft = 0;
      _speedBonusActive = false;
      return;
    }
    _runSpeedCountdown();
  }

  void _runSpeedCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = 0;
          _speedBonusActive = false;
          timer.cancel();
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  void _nextProblem({bool setLoaded = false}) {
    if (!hasStencilAttemptsLeft) {
      if (setLoaded && mounted) setState(() => _loaded = true);
      return;
    }
    _countdownTimer?.cancel();
    final previous = _problem;
    setState(() {
      _problem = _generator.generate(
        kind: widget.kind,
        multiplyRow: widget.multiplyRow,
        avoidSameAs: previous,
      );
      _selectedAnswer = null;
      _evaluating = false;
      _answeredCorrectly = false;
      _earnedSpeedBonus = null;
      if (setLoaded) _loaded = true;
    });
    _startSpeedTimer();
  }

  String _promptText(MathProblem problem) {
    if (_answeredCorrectly) {
      if (problem.kind == MathProblemKind.counting) {
        return '${problem.correctAnswer}';
      }
      return problem.promptWithAnswer(problem.correctAnswer);
    }
    return problem.promptText;
  }

  Future<void> _onAnswer(int value) async {
    if (_evaluating || _problem == null || !hasStencilAttemptsLeft) return;

    final problem = _problem!;
    final correct = value == problem.correctAnswer;
    final earnedBonus = correct && _usesSpeedBonus && _speedBonusActive;
    final starSlots = earnedBonus ? 2 : 1;

    setState(() {
      _selectedAnswer = value;
      _evaluating = true;
      _answeredCorrectly = correct;
      _earnedSpeedBonus = correct ? earnedBonus : null;
    });
    _countdownTimer?.cancel();

    await consumeStencilAttempt();

    if (correct) {
      await AppFeedback.success();
      await reactStencilToAnswer(
        correct: true,
        flightOriginKey: _answerKey,
        rewardTrainerId: widget.kind.trainerId,
        starSlots: starSlots,
      );
      if (!mounted) return;
      reloadTrainerStars();
      await Future<void>.delayed(_correctRevealPause);
      if (!mounted) return;
      _nextProblem();
      if (!hasStencilAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

    await AppFeedback.softHint();
    await reactStencilToAnswer(
      correct: false,
      flightOriginKey: _answerKey,
      rewardTrainerId: widget.kind.trainerId,
    );
    if (!mounted) return;
    reloadTrainerStars();
    setState(() {
      _evaluating = false;
      _answeredCorrectly = false;
      _earnedSpeedBonus = null;
      _selectedAnswer = null;
    });
    _resumeSpeedTimer();
    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
    }
  }

  _SpeedTimerBadgePhase _timerBadgePhase() {
    if (_evaluating && _answeredCorrectly) {
      return _earnedSpeedBonus == true
          ? _SpeedTimerBadgePhase.bonusEarned
          : _SpeedTimerBadgePhase.expired;
    }
    if (_speedBonusActive && !_evaluating) {
      return _SpeedTimerBadgePhase.counting;
    }
    return _SpeedTimerBadgePhase.expired;
  }

  final _answerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final problem = _problem;

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.kind.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (problem == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.kind.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
      appBar: AppBar(title: Text(widget.kind.title)),
      body: SafeArea(
              top: false,
              child: Stack(
                key: stackKey,
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        buildStencilHeader(),
                        const SizedBox(height: 8),
                        _SpeedTimerBadge(
                          phase: _timerBadgePhase(),
                          secondsLeft: _secondsLeft,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _promptText(problem),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: _ProblemVisual(
                                  problem: problem,
                                  maxWidth: constraints.maxWidth,
                                  maxHeight: constraints.maxHeight,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: _answerKey,
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.6,
                            children: [
                              for (final choice in problem.choices)
                                _AnswerButton(
                                  label: '$choice',
                                  selected: _selectedAnswer == choice,
                                  correct: _evaluating &&
                                      choice == problem.correctAnswer,
                                  wrong: _evaluating &&
                                      _selectedAnswer == choice &&
                                      choice != problem.correctAnswer,
                                  onTap: _evaluating
                                      ? null
                                      : () => unawaited(_onAnswer(choice)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
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

enum _SpeedTimerBadgePhase { counting, expired, bonusEarned }

class _SpeedTimerBadge extends StatelessWidget {
  const _SpeedTimerBadge({
    required this.phase,
    required this.secondsLeft,
  });

  final _SpeedTimerBadgePhase phase;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = switch (phase) {
      _SpeedTimerBadgePhase.counting => colors.primaryContainer,
      _SpeedTimerBadgePhase.bonusEarned => colors.primaryContainer,
      _SpeedTimerBadgePhase.expired => colors.surfaceContainerHighest,
    };
    final fg = switch (phase) {
      _SpeedTimerBadgePhase.counting => colors.onPrimaryContainer,
      _SpeedTimerBadgePhase.bonusEarned => colors.onPrimaryContainer,
      _SpeedTimerBadgePhase.expired => colors.onSurfaceVariant,
    };
    final border = switch (phase) {
      _SpeedTimerBadgePhase.counting => colors.primary,
      _SpeedTimerBadgePhase.bonusEarned => colors.primary,
      _SpeedTimerBadgePhase.expired => colors.outline,
    };
    final label = switch (phase) {
      _SpeedTimerBadgePhase.counting => '⏱ $secondsLeft c — ×2 звезды',
      _SpeedTimerBadgePhase.bonusEarned => '⏱ успел! — ×2 звезды',
      _SpeedTimerBadgePhase.expired => '⏱ время вышло — 1 звезда',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: border,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ProblemVisual extends StatelessWidget {
  const _ProblemVisual({
    required this.problem,
    required this.maxWidth,
    required this.maxHeight,
  });

  final MathProblem problem;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (problem.dotCount != null) {
      return MathDotsVisual.count(
        count: problem.dotCount!,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
    if (problem.leftAddend != null && problem.rightAddend != null) {
      if (problem.kind == MathProblemKind.subtraction10) {
        return MathAddendsVisual.subtraction(
          left: problem.leftAddend!,
          right: problem.rightAddend!,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      }
      return MathAddendsVisual.addition(
        left: problem.leftAddend!,
        right: problem.rightAddend!,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
    if (problem.groupRows != null && problem.groupCols != null) {
      return MathDotsVisual.grid(
        rows: problem.groupRows!,
        cols: problem.groupCols!,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
    return const SizedBox.shrink();
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool correct;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color bg = colors.surfaceContainerHighest;
    if (correct) {
      bg = colors.primaryContainer;
    } else if (wrong) {
      bg = colors.errorContainer;
    } else if (selected) {
      bg = colors.primaryContainer.withValues(alpha: 0.6);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outline,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
