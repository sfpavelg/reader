import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/trainer_ids.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/trainer_completion_dialog.dart';
import '../../main.dart';
import '../../trainers/rsvp/rsvp_fixation.dart';
import '../../trainers/rsvp/rsvp_generator.dart';
import '../../trainers/rsvp/rsvp_session_store.dart';

class RsvpScreen extends ConsumerStatefulWidget {
  const RsvpScreen({super.key});

  @override
  ConsumerState<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends ConsumerState<RsvpScreen> {
  int _levelId = 1;
  bool _ready = false;
  bool _playing = false;

  RsvpTrainerProgress _progress = RsvpTrainerProgress(
    wpm: 45,
    levelId: 1,
    words: const [],
    wordIndex: 0,
    sourceEntryIds: const [],
  );

  Timer? _tickTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _progress = RsvpSessionStore.load(_levelId);
      if (!_progress.hasPassage || _progress.isComplete) {
        _loadNewPassage();
      }
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    unawaited(RsvpSessionStore.save(_progress));
    super.dispose();
  }

  void _loadNewPassage() {
    final dictionary = ref.read(dictionaryServiceProvider);
    final generator = RsvpGenerator(dictionary: dictionary);
    final passage = generator.generate(
      levelId: _levelId,
      excludeEntryIds: _progress.sourceEntryIds.toSet(),
    );
    setState(() {
      _progress = RsvpSessionStore.applyPassage(_progress, passage);
    });
    unawaited(RsvpSessionStore.save(_progress));
  }

  void _togglePlay() {
    if (_progress.isComplete) {
      _loadNewPassage();
    }
    if (_playing) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_progress.words.isEmpty || _progress.isComplete) {
      _loadNewPassage();
    }

    _tickTimer?.cancel();
    if (_progress.wordIndex == 0 && _progress.words.isNotEmpty) {
      setState(() => _progress = _progress.copyWith(wordIndex: 1));
      unawaited(RsvpSessionStore.save(_progress));
    }
    setState(() => _playing = true);
    _scheduleTick();
  }

  void _scheduleTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer(
      RsvpGenerator.intervalForWpm(_progress.wpm),
      _onTick,
    );
  }

  void _onTick() {
    if (!mounted) return;

    final nextIndex = _progress.wordIndex + 1;
    if (nextIndex > _progress.words.length) {
      _pause();
      _showComplete();
      return;
    }

    setState(() {
      _progress = _progress.copyWith(wordIndex: nextIndex);
    });
    unawaited(RsvpSessionStore.save(_progress));

    if (_playing) {
      _scheduleTick();
    }
  }

  void _pause() {
    _tickTimer?.cancel();
    setState(() => _playing = false);
    unawaited(RsvpSessionStore.save(_progress));
  }

  void _changeWpm(int delta) {
    final next = (_progress.wpm + delta).clamp(25, 180);
    setState(() => _progress = _progress.copyWith(wpm: next));
    unawaited(RsvpSessionStore.save(_progress));
    if (_playing) {
      _scheduleTick();
    }
  }

  Future<void> _changeLevel(int levelId) async {
    unawaited(AppFeedback.tap());
    _pause();
    setState(() {
      _levelId = levelId;
      _progress = RsvpSessionStore.load(levelId);
    });
    if (!_progress.hasPassage || _progress.isComplete) {
      _loadNewPassage();
    }
  }

  Future<void> _showComplete() async {
    await completeTrainerRound(
      context,
      trainerId: TrainerIds.rsvp,
      title: 'Серия прочитана',
      message: 'Можно продолжить со следующей серией слов.',
      primaryLabel: 'Дальше',
      onPrimary: _loadNewPassage,
    );
  }

  String? get _currentWord {
    if (_progress.words.isEmpty) return null;
    final i = _progress.wordIndex;
    if (i <= 0) return null;
    if (i > _progress.words.length) return null;
    return _progress.words[i - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final word = _currentWord;
    final total = _progress.words.length;
    final shown = _progress.wordIndex.clamp(0, total);
    final value = total == 0 ? 0.0 : shown / total;

    final wordStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бегущая строка'),
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
                _playing ? 'Читай в центре' : 'Нажми ▶ чтобы начать',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_progress.wpm} слов в минуту',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: RepaintBoundary(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 80),
                      child: word == null
                          ? Text(
                              '…',
                              key: const ValueKey('ellipsis'),
                              style: wordStyle,
                            )
                          : RichText(
                              key: ValueKey(word),
                              textAlign: TextAlign.center,
                              text: buildRsvpWordSpan(
                                word: word,
                                baseStyle: wordStyle!,
                                fixationColor: colors.error,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total == 0 ? null : value,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text('$shown из $total'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Медленнее',
                    onPressed: () {
                      unawaited(AppFeedback.tap());
                      _changeWpm(-5);
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {
                      unawaited(AppFeedback.tap());
                      _togglePlay();
                    },
                    icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                    label: Text(_playing ? 'Пауза' : 'Старт'),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    tooltip: 'Быстрее',
                    onPressed: () {
                      unawaited(AppFeedback.tap());
                      _changeWpm(5);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  unawaited(AppFeedback.tap());
                  _pause();
                  _loadNewPassage();
                },
                child: const Text('Новая серия'),
              ),
            ],
          ),
        ),
      ),
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
}
