import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../content/fairytale_catalog.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/fairytale_progress.dart';
import '../../gamification/rewards_service.dart';
import '../../services/fairytale_audio_service.dart';
import '../../widgets/app_feedback.dart';

class FairytaleDetailScreen extends StatefulWidget {
  const FairytaleDetailScreen({super.key, required this.taleId});

  final String taleId;

  @override
  State<FairytaleDetailScreen> createState() => _FairytaleDetailScreenState();
}

class _FairytaleDetailScreenState extends State<FairytaleDetailScreen> {
  FairytaleProgress _progress = const FairytaleProgress();
  int _stars = 0;

  Fairytale? get _tale => FairytaleCatalog.byId(widget.taleId);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    unawaited(FairytaleAudioService.stop());
    super.dispose();
  }

  void _reload() {
    setState(() {
      _progress = LocalStorage.isReady
          ? LocalStorage.readFairytaleProgress()
          : const FairytaleProgress();
      _stars = LocalStorage.isReady ? RewardsService.availableStars() : 0;
    });
  }

  FairytaleChapter? get _mainChapter {
    final tale = _tale;
    if (tale == null || tale.chapters.isEmpty) return null;
    return tale.chapters.first;
  }

  bool _isUnlocked(FairytaleChapter chapter) =>
      _progress.isChapterUnlocked(chapter.id);

  Future<void> _unlockChapter(FairytaleChapter chapter) async {
    if (_isUnlocked(chapter)) return;

    final cost = Fairytale.chapterStarCost;
    if (_stars < cost) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нужно $cost ⭐. Сейчас у тебя $_stars.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Открыть сказку?'),
        content: Text(
          '«${_tale?.title ?? chapter.title}» откроется за $cost ⭐.\n'
          'У тебя сейчас: $_stars ⭐.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Открыть · $cost ⭐'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await RewardsService.unlockFairytaleChapter(
      chapterId: chapter.id,
      starCost: cost,
    );
    if (!mounted) return;
    if (!ok) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть сказку')),
      );
      return;
    }
    await AppFeedback.success();
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${_tale?.title ?? chapter.title}» открыта!'),
      ),
    );
  }

  Future<void> _openNarration(FairytaleChapter chapter) async {
    if (!_isUnlocked(chapter)) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала открой сказку за звёзды'),
        ),
      );
      return;
    }

    final asset = chapter.audioAsset;
    if (asset == null || asset.isEmpty) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Озвучка ещё не добавлена')),
      );
      return;
    }

    await AppFeedback.tap();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _FairytalePlayerSheet(
        title: _tale?.title ?? chapter.title,
        synopsis: chapter.synopsis,
        audioAsset: asset,
        durationHint: chapter.duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tale = _tale;
    if (tale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сказка')),
        body: const Center(child: Text('Сказка не найдена')),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final chapter = _mainChapter;
    final unlocked = chapter != null && _isUnlocked(chapter);

    return Scaffold(
      appBar: AppBar(
        title: Text(tale.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '⭐ $_stars',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(tale.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tale.author,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(tale.blurb),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Открытие — ${Fairytale.chapterStarCost} ⭐. '
            'Потом нажми карточку, чтобы слушать.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (chapter != null)
            _ChapterTile(
              index: 1,
              chapter: chapter,
              unlocked: unlocked,
              lockedLabel: 'Закрыто · ${Fairytale.chapterStarCost} ⭐',
              onTap: () => unawaited(
                unlocked ? _openNarration(chapter) : _unlockChapter(chapter),
              ),
            ),
          if (tale.chapters.length > 1) ...[
            const SizedBox(height: 20),
            Text(
              'Главы',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 1; i < tale.chapters.length; i++) ...[
              if (i > 1) const SizedBox(height: 10),
              _ChapterTile(
                index: i + 1,
                chapter: tale.chapters[i],
                unlocked: _isUnlocked(tale.chapters[i]),
                lockedLabel: 'Закрыто · ${Fairytale.chapterStarCost} ⭐',
                onTap: () => unawaited(
                  _isUnlocked(tale.chapters[i])
                      ? _openNarration(tale.chapters[i])
                      : _unlockChapter(tale.chapters[i]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.unlocked,
    required this.lockedLabel,
    required this.onTap,
  });

  final int index;
  final FairytaleChapter chapter;
  final bool unlocked;
  final String lockedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: unlocked
          ? colors.primaryContainer.withValues(alpha: 0.55)
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                child: Text(
                  unlocked ? '▶' : '$index',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      unlocked ? chapter.synopsis : lockedLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.headphones_rounded : Icons.lock_outline,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FairytalePlayerSheet extends StatefulWidget {
  const _FairytalePlayerSheet({
    required this.title,
    required this.synopsis,
    required this.audioAsset,
    this.durationHint,
  });

  final String title;
  final String synopsis;
  final String audioAsset;
  final Duration? durationHint;

  @override
  State<_FairytalePlayerSheet> createState() => _FairytalePlayerSheetState();
}

class _FairytalePlayerSheetState extends State<_FairytalePlayerSheet> {
  final AudioPlayer _player = FairytaleAudioService.player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  String? _error;
  bool _loading = true;
  bool _ready = false;
  bool _dragging = false;

  bool get _playing => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _duration = widget.durationHint ?? Duration.zero;
    _posSub = _player.onPositionChanged.listen((d) {
      if (!mounted || _dragging) return;
      setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted || d <= Duration.zero) return;
      setState(() => _duration = d);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
      _ready = false;
    });
    try {
      final probed = await FairytaleAudioService.prepareAsset(widget.audioAsset);
      if (mounted) {
        setState(() {
          if (probed != null && probed > Duration.zero) {
            _duration = probed;
          } else if (widget.durationHint != null) {
            _duration = widget.durationHint!;
          }
          _position = Duration.zero;
          _loading = false;
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _ready = false;
          _error = 'Не удалось загрузить аудио.\n$e';
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_state == PlayerState.paused) {
      await _player.resume();
      return;
    }
    await FairytaleAudioService.playPrepared();
  }

  Future<void> _stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    if (mounted) setState(() => _position = Duration.zero);
  }

  Future<void> _seekTo(Duration pos) async {
    final max = _duration;
    final clamped = max > Duration.zero && pos > max ? max : pos;
    setState(() => _position = clamped);
    await _player.seek(clamped);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    unawaited(_posSub?.cancel() ?? Future<void>.value());
    unawaited(_durSub?.cancel() ?? Future<void>.value());
    unawaited(_stateSub?.cancel() ?? Future<void>.value());
    unawaited(FairytaleAudioService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds;
    final canSeek = _ready && maxMs > 0;
    final value = !canSeek
        ? 0.0
        : (_position.inMilliseconds.clamp(0, maxMs) / maxMs);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            widget.synopsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else ...[
            Slider(
              value: value,
              onChangeStart: canSeek
                  ? (_) => setState(() => _dragging = true)
                  : null,
              onChanged: canSeek
                  ? (v) {
                      setState(() {
                        _position = Duration(
                          milliseconds: (v * maxMs).round(),
                        );
                      });
                    }
                  : null,
              onChangeEnd: canSeek
                  ? (v) {
                      final pos = Duration(milliseconds: (v * maxMs).round());
                      setState(() => _dragging = false);
                      unawaited(_seekTo(pos));
                    }
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(_position)),
                Text(_fmt(_duration)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Стоп',
                  onPressed: () => unawaited(_stop()),
                  icon: const Icon(Icons.stop_rounded),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _ready ? () => unawaited(_toggle()) : null,
                  icon: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_playing ? 'Пауза' : 'Слушать'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
