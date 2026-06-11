import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/trainer_ids.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/trainer_completion_dialog.dart';
import '../../main.dart';
import '../../trainers/bookmark_window/bookmark_window_generator.dart';
import '../../trainers/bookmark_window/bookmark_window_session_store.dart';
import '../../trainers/rsvp/rsvp_fixation.dart';

class BookmarkWindowScreen extends ConsumerStatefulWidget {
  const BookmarkWindowScreen({super.key});

  @override
  ConsumerState<BookmarkWindowScreen> createState() =>
      _BookmarkWindowScreenState();
}

class _BookmarkWindowScreenState extends ConsumerState<BookmarkWindowScreen> {
  int _levelId = 3;
  bool _ready = false;
  bool _playing = false;

  BookmarkWindowProgress _progress = BookmarkWindowProgress(
    msPerFragment: 1200,
    levelId: 3,
    fragments: const [],
    fullText: '',
    fragmentIndex: 0,
    sourceEntryIds: const [],
  );

  Timer? _tickTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _progress = BookmarkWindowSessionStore.load(_levelId);
      if (!_progress.hasPassage || _progress.isComplete) {
        _loadNewPassage();
      }
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    unawaited(BookmarkWindowSessionStore.save(_progress));
    super.dispose();
  }

  void _loadNewPassage() {
    final dictionary = ref.read(dictionaryServiceProvider);
    final generator = BookmarkWindowGenerator(dictionary: dictionary);
    final passage = generator.generate(
      levelId: _levelId,
      excludeEntryIds: _progress.sourceEntryIds.toSet(),
    );
    setState(() {
      _progress = BookmarkWindowSessionStore.applyPassage(_progress, passage);
    });
    unawaited(BookmarkWindowSessionStore.save(_progress));
  }

  String? get _currentFragment {
    final i = _progress.fragmentIndex;
    if (i <= 0 || i > _progress.fragments.length) return null;
    return _progress.fragments[i - 1];
  }

  void _togglePlay() {
    if (_progress.isComplete) _loadNewPassage();
    if (_playing) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_progress.fragments.isEmpty || _progress.isComplete) {
      _loadNewPassage();
    }
    _tickTimer?.cancel();
    if (_progress.fragmentIndex == 0 && _progress.fragments.isNotEmpty) {
      setState(() => _progress = _progress.copyWith(fragmentIndex: 1));
      unawaited(BookmarkWindowSessionStore.save(_progress));
    }
    setState(() => _playing = true);
    _scheduleTick();
  }

  void _scheduleTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer(
      BookmarkWindowGenerator.intervalForMs(_progress.msPerFragment),
      _advance,
    );
  }

  void _advance() {
    if (!mounted) return;

    final next = _progress.fragmentIndex + 1;
    if (next > _progress.fragments.length) {
      _pause();
      _showComplete();
      return;
    }

    setState(() => _progress = _progress.copyWith(fragmentIndex: next));
    unawaited(BookmarkWindowSessionStore.save(_progress));

    if (_playing) _scheduleTick();
  }

  void _pause() {
    _tickTimer?.cancel();
    setState(() => _playing = false);
    unawaited(BookmarkWindowSessionStore.save(_progress));
  }

  void _changeSpeed(int deltaMs) {
    final next = (_progress.msPerFragment + deltaMs).clamp(700, 3500);
    setState(() => _progress = _progress.copyWith(msPerFragment: next));
    unawaited(BookmarkWindowSessionStore.save(_progress));
    if (_playing) _scheduleTick();
  }

  Future<void> _changeLevel(int levelId) async {
    unawaited(AppFeedback.tap());
    _pause();
    setState(() {
      _levelId = levelId;
      _progress = BookmarkWindowSessionStore.load(levelId);
    });
    if (!_progress.hasPassage || _progress.isComplete) {
      _loadNewPassage();
    }
  }

  Future<void> _showComplete() async {
    await completeTrainerRound(
      context,
      trainerId: TrainerIds.bookmarkWindow,
      title: 'Фрагмент прочитан',
      message: 'Ты прочитал весь текст в окошке — отлично!',
      primaryLabel: 'Дальше',
      onPrimary: _loadNewPassage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fragment = _currentFragment;
    final total = _progress.fragments.length;
    final shown = _progress.fragmentIndex.clamp(0, total);
    final wordStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w800,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Окошко'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Уровень',
            initialValue: _levelId,
            onSelected: _changeLevel,
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 2, child: Text('Слова')),
              PopupMenuItem(value: 3, child: Text('Фразы')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(_levelId == 3 ? 'Фразы' : 'Слова'),
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
                _playing ? 'Читай только в окошке' : 'Нажми ▶ или тап по окошку',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress.msPerFragment / 1000).toStringAsFixed(1)} с на фрагмент',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.85),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _progress.fullText,
                        maxLines: 4,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.25),
                              height: 1.6,
                            ),
                      ),
                    ),
                    RepaintBoundary(
                      child: Material(
                        elevation: 4,
                        color: colors.primaryContainer.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _playing
                              ? null
                              : () {
                                  unawaited(AppFeedback.tap());
                                  _advance();
                                },
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.primary,
                                width: 3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 100),
                              child: fragment == null
                                  ? Text(
                                      '…',
                                      key: const ValueKey('empty'),
                                      style: wordStyle,
                                    )
                                  : RichText(
                                      key: ValueKey(fragment),
                                      textAlign: TextAlign.center,
                                      text: buildRsvpWordSpan(
                                        word: fragment,
                                        baseStyle: wordStyle!,
                                        fixationColor: colors.error,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total == 0 ? null : shown / total,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text('$shown из $total'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Медленнее',
                    onPressed: () {
                      unawaited(AppFeedback.tap());
                      _changeSpeed(150);
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
                      _changeSpeed(-150);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  unawaited(AppFeedback.tap());
                  _pause();
                  _loadNewPassage();
                },
                child: const Text('Новый текст'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
