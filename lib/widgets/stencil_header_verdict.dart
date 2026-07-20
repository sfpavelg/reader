import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/app_feedback.dart';

/// Реакция смайлика между трафаретом и кошельком.
enum StencilHeaderVerdict { none, success, fail }

/// Постоянный кликабельный смайлик: кивок / качание / подмигивание.
class StencilHeaderBuddy extends StatefulWidget {
  const StencilHeaderBuddy({
    super.key,
    required this.verdict,
    required this.generation,
  });

  final StencilHeaderVerdict verdict;
  final int generation;

  @override
  State<StencilHeaderBuddy> createState() => _StencilHeaderBuddyState();
}

enum _BuddyFace { smile, wink, bigSmile, sad }

class _StencilHeaderBuddyState extends State<StencilHeaderBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rng = math.Random();

  _BuddyFace _face = _BuddyFace.smile;
  /// nod | shake | tap
  String _motion = 'idle';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _face = _BuddyFace.smile;
            _motion = 'idle';
          });
          _controller.value = 0;
        }
      });
  }

  @override
  void didUpdateWidget(covariant StencilHeaderBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.generation != oldWidget.generation) {
      _reactToVerdict(widget.verdict);
    }
  }

  void _reactToVerdict(StencilHeaderVerdict verdict) {
    if (verdict == StencilHeaderVerdict.success) {
      _play(face: _BuddyFace.smile, motion: 'nod', ms: 900);
    } else if (verdict == StencilHeaderVerdict.fail) {
      _play(face: _BuddyFace.sad, motion: 'shake', ms: 1000);
    }
  }

  void _play({
    required _BuddyFace face,
    required String motion,
    required int ms,
  }) {
    _controller.stop();
    setState(() {
      _face = face;
      _motion = motion;
    });
    _controller.duration = Duration(milliseconds: ms);
    _controller.forward(from: 0);
  }

  Future<void> _onTap() async {
    await AppFeedback.tap();
    if (!mounted) return;
    final wink = _rng.nextBool();
    _play(
      face: wink ? _BuddyFace.wink : _BuddyFace.bigSmile,
      motion: 'tap',
      ms: wink ? 700 : 800,
    );
  }

  String get _emoji {
    switch (_face) {
      case _BuddyFace.smile:
        return '😊';
      case _BuddyFace.wink:
        return '😉';
      case _BuddyFace.bigSmile:
        return '😃';
      case _BuddyFace.sad:
        return '😢';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              var dx = 0.0;
              var dy = 0.0;
              var angle = 0.0;
              var scale = 1.0;

              if (_motion == 'nod' && t > 0) {
                // Кивок: вниз-вверх два раза.
                final wave = math.sin(t * math.pi * 2);
                dy = 5 * wave;
                angle = 0.18 * wave;
                scale = 1.0 + 0.06 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              } else if (_motion == 'shake' && t > 0) {
                // Качает головой.
                final wave = math.sin(t * math.pi * 4);
                angle = 0.35 * wave;
                dx = 4 * wave;
              } else if (_motion == 'tap' && t > 0) {
                final pop = Curves.easeOutBack.transform(
                  (t < 0.35 ? t / 0.35 : 1.0).clamp(0.0, 1.0),
                );
                final fade = t > 0.7 ? (1 - (t - 0.7) / 0.3) : 1.0;
                scale = 0.85 + 0.25 * pop * fade.clamp(0.0, 1.0);
              }

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              );
            },
            child: Text(
              _emoji,
              style: const TextStyle(fontSize: 30, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
