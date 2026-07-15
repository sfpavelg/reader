import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/trainer_ids.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../mixins/trainer_stencil_stars_mixin.dart';
import '../../widgets/app_feedback.dart';
import '../../main.dart';
import '../../trainers/bookmark_window/bookmark_window_animated_grid.dart';
import '../../trainers/bookmark_window/bookmark_window_board.dart';
import '../../trainers/bookmark_window/bookmark_window_motion.dart';

class BookmarkWindowScreen extends ConsumerStatefulWidget {
  const BookmarkWindowScreen({super.key});

  @override
  ConsumerState<BookmarkWindowScreen> createState() =>
      _BookmarkWindowScreenState();
}

class _BookmarkWindowScreenState extends ConsumerState<BookmarkWindowScreen>
    with
        TrainerStarsMixin,
        TrainerStencilStarsMixin,
        TickerProviderStateMixin {
  static const _sharedStorageKey = 'bookmark_window_shared';
  static const _moveLimit = 40;
  static const _gridGap = 4.0;
  static const _headerPadding = EdgeInsets.fromLTRB(10, 8, 10, 0);
  static const _idleBeforeHintBlink = Duration(seconds: 10);

  final _gridKey = GlobalKey();
  final _collectedWordKey = GlobalKey();
  late final AnimationController _motionController;
  late final AnimationController _hintGlowController;
  Timer? _idleHintTimer;

  bool _ready = false;
  bool _loaded = false;
  bool _busy = false;
  bool _hintInFlight = false;
  bool _hintIdleBlink = false;

  BookmarkWindowBoard? _board;
  List<BookmarkWindowVisualTile> _tiles = [];
  int _nextTileId = 0;
  double _highlightPulse = 0;
  double _collectedWordPulse = 0;
  double _hintWordOpacity = 1.0;
  bool _freeHintUsed = false;
  String? _hintDemoBoardSignature;
  final Set<String> _demonstratedHintKeys = {};
  final Map<String, String> _demonstratedHintWords = {};

  int? _selectedIndex;
  String _lastWord = '';
  int _wordsCollected = 0;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(vsync: this);
    _hintGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _idleHintTimer?.cancel();
    _motionController.dispose();
    _hintGlowController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      initTrainerStars();
      initStencilStars(
        storageKey: _sharedStorageKey,
        dailyAttemptLimit: _moveLimit,
      );
      _bootstrap();
    }
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
    _startNewBoard();
    _loaded = true;
  }

  void _startNewBoard() {
    if (!hasStencilAttemptsLeft) return;
    clearStencilFlightState();
    setState(() {
      _board = BookmarkWindowBoard.create(
        dictionary: ref.read(dictionaryServiceProvider),
      );
      _selectedIndex = null;
      _lastWord = '';
      _wordsCollected = 0;
      _busy = false;
      _highlightPulse = 0;
      _collectedWordPulse = 0;
      _freeHintUsed = false;
      _clearHintDemoTracking();
      _rebuildTilesFromBoard();
    });
    _armIdleHintTimer();
  }

  void _clearHintIdleGlow() {
    _hintGlowController
      ..stop()
      ..value = 0;
    if (_hintIdleBlink) {
      setState(() => _hintIdleBlink = false);
    }
  }

  void _armIdleHintTimer() {
    _idleHintTimer?.cancel();
    if (!mounted) return;
    _clearHintIdleGlow();
    _idleHintTimer = Timer(_idleBeforeHintBlink, () {
      if (!mounted || !_canTapHint) return;
      if (_board?.findFirstWordSwapHint() == null) return;
      setState(() => _hintIdleBlink = true);
      _hintGlowController.repeat(reverse: true);
    });
  }

  void _markFreeHintUsed() {
    setState(() => _freeHintUsed = true);
  }

  void _clearHintDemoTracking() {
    _hintDemoBoardSignature = null;
    _demonstratedHintKeys.clear();
    _demonstratedHintWords.clear();
  }

  String _swapKey(Set<int> indices) {
    final sorted = indices.toList()..sort();
    return '${sorted[0]}:${sorted[1]}';
  }

  String? _hintedWordForSwap(
    Set<int> swapIndices, {
    List<String?>? boardBeforeSwap,
  }) {
    if (swapIndices.length != 2) return null;
    final signature = boardBeforeSwap == null
        ? (_board == null ? null : _boardSignature(_board!))
        : boardBeforeSwap.join('\x1f');
    if (signature == null || _hintDemoBoardSignature != signature) return null;
    return _demonstratedHintWords[_swapKey(swapIndices)];
  }

  String _boardSignature(BookmarkWindowBoard board) =>
      board.cells.join('\x1f');

  String _hintKey(BookmarkWindowSwapHint hint) {
    final a = hint.indexA < hint.indexB ? hint.indexA : hint.indexB;
    final b = hint.indexA < hint.indexB ? hint.indexB : hint.indexA;
    return '$a:$b';
  }

  bool _wasHintDemonstrated(
    BookmarkWindowBoard board,
    BookmarkWindowSwapHint hint,
  ) {
    final signature = _boardSignature(board);
    if (_hintDemoBoardSignature != signature) return false;
    return _demonstratedHintKeys.contains(_hintKey(hint));
  }

  void _markHintDemonstrated(
    BookmarkWindowBoard board,
    BookmarkWindowSwapHint hint,
    BookmarkWindowMatch match,
  ) {
    final signature = _boardSignature(board);
    if (_hintDemoBoardSignature != signature) {
      _hintDemoBoardSignature = signature;
      _demonstratedHintKeys.clear();
      _demonstratedHintWords.clear();
    }
    final key = _hintKey(hint);
    _demonstratedHintKeys.add(key);
    _demonstratedHintWords[key] = match.word.text;
  }

  void _rebuildTilesFromBoard() {
    final board = _board;
    if (board == null) {
      _tiles = [];
      return;
    }
    _nextTileId = 0;
    _tiles = List.generate(board.cellCount, (index) {
      final syllable = board.cellAt(index);
      if (syllable == null) return null;
      final col = index % board.cols;
      final row = index ~/ board.cols;
      return BookmarkWindowVisualTile(
        id: _nextTileId++,
        syllable: syllable,
        col: col.toDouble(),
        row: row.toDouble(),
        gridIndex: index,
      );
    }).whereType<BookmarkWindowVisualTile>().toList();
  }

  void _syncTilePositionsFromBoard() {
    final board = _board;
    if (board == null) return;
    final byIndex = <int, BookmarkWindowVisualTile>{
      for (final tile in _tiles)
        if (tile.gridIndex != null) tile.gridIndex!: tile,
    };

    for (var index = 0; index < board.cellCount; index++) {
      final syllable = board.cellAt(index);
      if (syllable == null) continue;
      final col = index % board.cols;
      final row = index ~/ board.cols;
      final tile = byIndex[index];
      if (tile != null) {
        tile.syllable = syllable;
        tile.col = col.toDouble();
        tile.row = row.toDouble();
        tile.gridIndex = index;
        tile.highlighted = false;
      } else {
        _tiles.add(
          BookmarkWindowVisualTile(
            id: _nextTileId++,
            syllable: syllable,
            col: col.toDouble(),
            row: row.toDouble(),
            gridIndex: index,
          ),
        );
      }
    }

    _tiles.removeWhere(
      (tile) =>
          tile.gridIndex == null || board.cellAt(tile.gridIndex!) == null,
    );
    _dedupeTileGridIndices();
  }

  BookmarkWindowVisualTile? _tileAtGridIndex(int index) {
    for (final tile in _tiles) {
      if (tile.gridIndex == index) return tile;
    }
    return null;
  }

  int? _visualGridIndex(BookmarkWindowVisualTile tile) {
    final board = _board;
    if (board == null) return null;
    final col = tile.col.round().clamp(0, board.cols - 1);
    final row = tile.row.round().clamp(0, board.rows - 1);
    return row * board.cols + col;
  }

  void _dedupeTileGridIndices() {
    final board = _board;
    if (board == null) return;

    final keepers = <int, BookmarkWindowVisualTile>{};
    final toRemove = <BookmarkWindowVisualTile>{};

    for (final tile in _tiles) {
      var index = tile.gridIndex;
      if (index == null) {
        index = _visualGridIndex(tile);
        if (index == null || board.cellAt(index) == null) {
          toRemove.add(tile);
          continue;
        }
        tile.gridIndex = index;
      }

      final existing = keepers[index];
      if (existing == null) {
        keepers[index] = tile;
        continue;
      }

      final boardSyllable = board.cellAt(index);
      final existingMatches = existing.syllable == boardSyllable;
      final tileMatches = tile.syllable == boardSyllable;
      if (existingMatches && !tileMatches) {
        toRemove.add(tile);
      } else {
        toRemove.add(existing);
        keepers[index] = tile;
      }
    }

    _tiles.removeWhere(toRemove.contains);
  }

  void _ensureSwapTiles(int a, int b) {
    final board = _board;
    if (board == null) return;

    for (final index in [a, b]) {
      if (_tileAtGridIndex(index) != null) continue;
      final syllable = board.cellAt(index);
      if (syllable == null) continue;
      final col = index % board.cols;
      final row = index ~/ board.cols;
      _tiles.add(
        BookmarkWindowVisualTile(
          id: _nextTileId++,
          syllable: syllable,
          col: col.toDouble(),
          row: row.toDouble(),
          gridIndex: index,
        ),
      );
    }
  }

  Future<void> _runMotion(
    void Function(double t) onTick, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    _motionController
      ..duration = duration
      ..value = 0;

    void listener() {
      onTick(curve.transform(_motionController.value));
      setState(() {});
    }

    _motionController.addListener(listener);
    await _motionController.forward();
    _motionController.removeListener(listener);
    onTick(1);
    setState(() {});
  }

  Future<bool> _animateCircularSwap(int a, int b) async {
    final board = _board!;
    _dedupeTileGridIndices();
    _ensureSwapTiles(a, b);
    final tileA = _tileAtGridIndex(a);
    final tileB = _tileAtGridIndex(b);
    if (tileA == null || tileB == null) return false;

    final startA = Offset(tileA.col, tileA.row);
    final startB = Offset(tileB.col, tileB.row);
    final endA = Offset((b % board.cols).toDouble(), (b ~/ board.cols).toDouble());
    final endB = Offset((a % board.cols).toDouble(), (a ~/ board.cols).toDouble());

    await _runMotion((t) {
      final posA = swapArcPosition(start: startA, end: endA, t: t);
      final posB = swapArcPosition(start: startB, end: endB, t: t);
      tileA
        ..col = posA.dx
        ..row = posA.dy;
      tileB
        ..col = posB.dx
        ..row = posB.dy;
    }, duration: bookmarkSwapDuration);

    tileA
      ..col = endA.dx
      ..row = endA.dy
      ..gridIndex = b;
    tileB
      ..col = endB.dx
      ..row = endB.dy
      ..gridIndex = a;
    _dedupeTileGridIndices();
    return true;
  }

  Future<void> _animateMatchCelebration({
    required Set<int> indices,
    required String word,
  }) async {
    final tiles = indices
        .map(_tileAtGridIndex)
        .whereType<BookmarkWindowVisualTile>()
        .toList();

    for (final tile in tiles) {
      tile.highlighted = false;
    }

    setState(() {
      _lastWord = word;
      _highlightPulse = 0;
      _collectedWordPulse = 0;
    });

    for (final tile in tiles) {
      tile.highlighted = true;
    }
    setState(() => _highlightPulse = 0);
    await _runMotion((t) {
      _highlightPulse = matchHighlightPulse(t);
      _collectedWordPulse = 0;
    }, duration: matchHighlightDuration());

    for (final tile in tiles) {
      tile.highlighted = false;
    }
    _highlightPulse = 0;
    if (!mounted) return;

    setState(() => _collectedWordPulse = 0);
    await _runMotion((t) {
      _collectedWordPulse = matchHighlightPulse(t);
      _highlightPulse = 0;
    }, duration: matchHighlightDuration());

    _collectedWordPulse = 0;
    if (mounted) setState(() {});
  }

  Future<bool> _playSwapHint({
    required BookmarkWindowSwapHint hint,
    required BookmarkWindowMatch match,
  }) async {
    final board = _board;
    if (board == null || !hasStencilAttemptsLeft) return false;

    final previousWord = _lastWord;
    final a = hint.indexA;
    final b = hint.indexB;
    final wordIndices = match.cellIndices(board.cols).toSet();

    _dedupeTileGridIndices();
    if (!await _animateCircularSwap(a, b)) {
      _syncTilePositionsFromBoard();
      return false;
    }
    if (!mounted) return false;
    board.swap(a, b);

    setState(() {
      _lastWord = match.word.text;
      _highlightPulse = 0;
      _collectedWordPulse = 0;
      _hintWordOpacity = 1.0;
    });
    for (final tile
        in wordIndices.map(_tileAtGridIndex).whereType<BookmarkWindowVisualTile>()) {
      tile.highlighted = true;
    }
    setState(() => _highlightPulse = 0);
    await _runMotion((t) {
      _highlightPulse = matchHighlightPulse(t);
      _collectedWordPulse = 0;
      _hintWordOpacity = 1.0;
    }, duration: matchHighlightDuration());
    if (!mounted) return false;

    for (final tile
        in wordIndices.map(_tileAtGridIndex).whereType<BookmarkWindowVisualTile>()) {
      tile.highlighted = false;
    }
    _highlightPulse = 0;
    setState(() => _collectedWordPulse = 0);
    await _runMotion((t) {
      _collectedWordPulse = matchHighlightPulse(t);
      _highlightPulse = 0;
      _hintWordOpacity = 1.0;
    }, duration: matchHighlightDuration());
    if (!mounted) return false;

    _collectedWordPulse = 0;

    if (!await _animateCircularSwap(a, b)) {
      board.swap(a, b);
      _syncTilePositionsFromBoard();
      return false;
    }
    if (!mounted) return false;
    board.swap(a, b);

    setState(() {
      _highlightPulse = 0;
      _collectedWordPulse = 0;
      _hintWordOpacity = 1.0;
      _lastWord = previousWord;
    });
    return true;
  }

  BookmarkWindowMatch? _previewMatchForHint(BookmarkWindowSwapHint hint) {
    final board = _board;
    if (board == null) return null;

    final before = board.cells;
    board.swap(hint.indexA, hint.indexB);
    final matches = board
        .findAllMatches()
        .where((m) => m.intersectsIndices({hint.indexA, hint.indexB}, board.cols))
        .where((m) => !board.matchExistedBefore(before, m))
        .toList();
    board.swap(hint.indexA, hint.indexB);

    if (matches.isEmpty) return null;
    return pickPrimarySwapMatch(
      matches,
      {hint.indexA, hint.indexB},
      board.cols,
    );
  }

  Future<void> _animateGravity(BookmarkWindowGravityPlan plan) async {
    final board = _board!;
    final cols = board.cols;
    _dedupeTileGridIndices();
    final tileByIndex = <int, BookmarkWindowVisualTile>{
      for (final tile in _tiles)
        if (tile.gridIndex != null) tile.gridIndex!: tile,
    };

    final newTiles = <BookmarkWindowVisualTile>[];
    for (final spawn in plan.spawns) {
      final toCol = spawn.toIndex % cols;
      newTiles.add(
        BookmarkWindowVisualTile(
          id: _nextTileId++,
          syllable: spawn.syllable,
          col: toCol.toDouble(),
          row: spawn.fromRow,
          gridIndex: spawn.toIndex,
        ),
      );
    }
    _tiles.addAll(newTiles);

    final duration = gravityDurationForRows(plan.maxFallRowsFor(cols));
    await _runMotion((t) {
      for (final move in plan.moves) {
        final tile = tileByIndex[move.fromIndex];
        if (tile == null) continue;
        final fromRow = move.fromIndex ~/ cols;
        final toRow = move.toIndex ~/ cols;
        tile.row = fromRow + (toRow - fromRow) * t;
        tile.col = (move.toIndex % cols).toDouble();
      }
      for (final spawn in plan.spawns) {
        final tile = newTiles.firstWhere((t) => t.gridIndex == spawn.toIndex);
        final toRow = spawn.toIndex ~/ cols;
        tile.row = spawn.fromRow + (toRow - spawn.fromRow) * t;
      }
    }, duration: duration, curve: Curves.easeOutCubic);

    for (final move in plan.moves) {
      final tile = tileByIndex[move.fromIndex];
      if (tile == null) continue;
      tile
        ..gridIndex = move.toIndex
        ..syllable = move.syllable
        ..col = (move.toIndex % cols).toDouble()
        ..row = (move.toIndex ~/ cols).toDouble();
    }

    board.applyGravityPlan(plan);
    _dedupeTileGridIndices();
    _syncTilePositionsFromBoard();
  }

  void _removeTilesAt(Set<int> indices) {
    _tiles.removeWhere((tile) {
      if (tile.gridIndex != null && indices.contains(tile.gridIndex!)) {
        return true;
      }
      final visual = _visualGridIndex(tile);
      return visual != null && indices.contains(visual);
    });
    _dedupeTileGridIndices();
  }

  Future<void> _awardMatch(
    BookmarkWindowMatch match, {
    required bool player,
    required List<String?> before,
    required Set<int> swapIndices,
  }) async {
    final board = _board!;
    final isPlayer = player &&
        board.isPlayerMatch(before, match, swapIndices);
    setState(() {
      _lastWord = match.word.text;
      _wordsCollected++;
    });
    await AppFeedback.success();
    await reactStencilToAnswer(
      correct: true,
      flightOriginKey: _collectedWordKey,
      rewardTrainerId: TrainerIds.bookmarkWindow,
      starSlots: isPlayer ? 2 : 1,
    );
    if (!mounted) return;
    reloadTrainerStars();
  }

  Future<void> _clearAndRefillMatch(BookmarkWindowMatch match) async {
    final board = _board!;
    final indices = match.cellIndices(board.cols).toSet();
    board.clearMatch(match);
    _removeTilesAt(indices);

    final plan = board.planGravityAndRefill();
    if (plan.moves.isNotEmpty || plan.spawns.isNotEmpty) {
      await _animateGravity(plan);
    } else {
      board.applyGravityPlan(plan);
      _syncTilePositionsFromBoard();
    }
  }

  BookmarkWindowMatch? _pickNextMatch(
    List<BookmarkWindowMatch> matches, {
    Set<int>? playerSwapIndices,
    List<String?>? boardBeforeSwap,
  }) {
    final board = _board;
    if (board == null || matches.isEmpty) return null;

    return pickPlayerSwapMatch(
      matches,
      board.cols,
      hintedWord: playerSwapIndices == null
          ? null
          : _hintedWordForSwap(
              playerSwapIndices,
              boardBeforeSwap: boardBeforeSwap,
            ),
      swapIndices: playerSwapIndices,
      isValid: board.matchStillOnBoard,
    );
  }

  Future<void> _resolveSingleMatchAnimated(
    BookmarkWindowMatch match, {
    required bool playerScored,
    required List<String?> before,
    required Set<int> swapIndices,
  }) async {
    final board = _board;
    if (board == null || !board.matchStillOnBoard(match)) return;

    final indices = match.cellIndices(board.cols).toSet();
    await _animateMatchCelebration(indices: indices, word: match.word.text);
    if (!mounted) return;

    await _awardMatch(
      match,
      player: playerScored,
      before: before,
      swapIndices: swapIndices,
    );
    if (!mounted) return;

    await _clearAndRefillMatch(match);
  }

  Future<void> _resolvePlayerSwapMatches({
    required List<String?> before,
    required Set<int> swapIndices,
  }) async {
    final board = _board;
    if (board == null) return;

    while (mounted) {
      final matches = board
          .findAllMatches()
          .where((m) => m.intersectsIndices(swapIndices, board.cols))
          .where((m) => !board.matchExistedBefore(before, m))
          .toList();
      final match = _pickNextMatch(
        matches,
        playerSwapIndices: swapIndices,
        boardBeforeSwap: before,
      );
      if (match == null) break;

      await _resolveSingleMatchAnimated(
        match,
        playerScored: true,
        before: before,
        swapIndices: swapIndices,
      );
    }
  }

  Future<void> _resolveMatchesAnimated(
    List<BookmarkWindowMatch> matches, {
    required List<String?> before,
    required Set<int> swapIndices,
    required bool playerScored,
  }) async {
    final match = _pickNextMatch(matches);
    if (match == null) return;

    await _resolveSingleMatchAnimated(
      match,
      playerScored: playerScored,
      before: before,
      swapIndices: swapIndices,
    );
  }

  bool get _canInteract =>
      !_busy && !stencilAnimating && hasStencilAttemptsLeft && _board != null;

  bool get _canTapHint =>
      !_hintInFlight &&
      _board != null &&
      hasStencilAttemptsLeft &&
      !_busy;

  Future<void> _onHintPressed() async {
    if (_hintInFlight || !_canTapHint) return;

    final board = _board;
    if (board == null) return;

    final hint = board.findFirstWordSwapHint();
    if (hint == null) {
      await AppFeedback.softHint();
      return;
    }

    final match = _previewMatchForHint(hint);
    if (match == null) {
      await AppFeedback.softHint();
      return;
    }

    final shouldCharge =
        _freeHintUsed && !_wasHintDemonstrated(board, hint);

    _hintInFlight = true;
    setState(() => _busy = true);

    try {
      await AppFeedback.tap();
      _idleHintTimer?.cancel();
      _clearHintIdleGlow();

      final played = await _playSwapHint(hint: hint, match: match);
      if (!played || !mounted) return;

      if (!_freeHintUsed) {
        _markFreeHintUsed();
      }
      if (shouldCharge) {
        await reactStencilToAnswer(
          correct: false,
          flightOriginKey: _collectedWordKey,
          rewardTrainerId: TrainerIds.bookmarkWindow,
        );
        if (!mounted) return;
        reloadTrainerStars();
      }
      _markHintDemonstrated(board, hint, match);
    } finally {
      _hintInFlight = false;
      if (mounted) {
        setState(() => _busy = false);
        _armIdleHintTimer();
      }
    }
  }

  Future<void> _onCellTap(int index) async {
    if (!_canInteract || _board == null) return;
    final board = _board!;

    if (_selectedIndex == null) {
      unawaited(AppFeedback.tap());
      setState(() => _selectedIndex = index);
      return;
    }

    final first = _selectedIndex!;
    if (first == index) {
      setState(() => _selectedIndex = null);
      return;
    }

    if (!board.areAdjacent(first, index)) {
      unawaited(AppFeedback.tap());
      setState(() => _selectedIndex = index);
      return;
    }

    setState(() {
      _busy = true;
      _selectedIndex = null;
    });
    _armIdleHintTimer();

    if (!await _animateCircularSwap(first, index)) {
      _syncTilePositionsFromBoard();
      setState(() => _busy = false);
      _armIdleHintTimer();
      return;
    }

    final before = board.cells;
    final swapIndices = {first, index};
    board.swap(first, index);

    await consumeStencilAttempt();

    final swapMatches = board
        .findAllMatches()
        .where((m) => m.intersectsIndices(swapIndices, board.cols))
        .toList();

    if (swapMatches.isEmpty) {
      await AppFeedback.softHint();
      await reactStencilToAnswer(
        correct: false,
        flightOriginKey: _collectedWordKey,
        rewardTrainerId: TrainerIds.bookmarkWindow,
      );
      if (!mounted) return;
      reloadTrainerStars();
      setState(() => _busy = false);
      _armIdleHintTimer();
      if (!hasStencilAttemptsLeft) {
        maybeShowStencilAttemptsDialog();
      }
      return;
    }

    await _resolvePlayerSwapMatches(
      before: before,
      swapIndices: swapIndices,
    );
    if (!mounted) return;

    await _resolveCascadesAnimated();
    if (!mounted) return;

    reloadTrainerStars();
    setState(() => _busy = false);
    _armIdleHintTimer();
    if (!hasStencilAttemptsLeft) {
      maybeShowStencilAttemptsDialog();
    }
  }

  Future<void> _resolveCascadesAnimated() async {
    final board = _board;
    if (board == null) return;

    while (mounted) {
      final autoMatches = board.findAllMatches();
      if (autoMatches.isEmpty) break;

      await _resolveMatchesAnimated(
        autoMatches,
        before: board.cells,
        swapIndices: const {},
        playerScored: false,
      );
      if (!mounted) return;
    }
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
      appBar: AppBar(
        title: const Text('Слогоменяйка'),
        actions: [
          _BookmarkHintButton(
            enabled: _canTapHint,
            costsStar: _freeHintUsed,
            idleBlink: _hintIdleBlink,
            glowAnimation: _hintGlowController,
            onPressed: _onHintPressed,
          ),
          IconButton(
            tooltip: 'Заново',
            onPressed: _canInteract || !hasStencilAttemptsLeft
                ? () {
                    unawaited(AppFeedback.tap());
                    if (hasStencilAttemptsLeft) {
                      _startNewBoard();
                    }
                  }
                : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                      _CollectedWordPanel(
                        panelKey: _collectedWordKey,
                        word: _lastWord,
                        wordsCollected: _wordsCollected,
                        wordOpacity: _hintWordOpacity,
                        wordHighlightPulse: _collectedWordPulse,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Меняй соседние слоги',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: board == null
                      ? const SizedBox.shrink()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final cellSide = _cellSide(
                              constraints.maxWidth,
                              constraints.maxHeight,
                              board.cols,
                              board.rows,
                            );

                            return Align(
                              alignment: Alignment.topCenter,
                              child: BookmarkWindowAnimatedGrid(
                                gridKey: _gridKey,
                                tiles: _tiles,
                                cols: board.cols,
                                rows: board.rows,
                                cellSide: cellSide,
                                gap: _gridGap,
                                canInteract: _canInteract,
                                selectedGridIndex: _selectedIndex,
                                highlightPulse: _highlightPulse,
                                onCellTap: (index) =>
                                    unawaited(_onCellTap(index)),
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

class _CollectedWordPanel extends StatelessWidget {
  const _CollectedWordPanel({
    required this.panelKey,
    required this.word,
    required this.wordsCollected,
    required this.wordOpacity,
    required this.wordHighlightPulse,
  });

  final GlobalKey panelKey;
  final String word;
  final int wordsCollected;
  final double wordOpacity;
  final double wordHighlightPulse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final display = word.isEmpty ? '—' : word;
    final pulse = wordHighlightPulse;
    final wordColor = pulse > 0
        ? Color.lerp(colors.primary, colors.tertiary, pulse) ?? colors.primary
        : colors.primary;

    return KeyedSubtree(
      key: panelKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primary, width: 2),
        ),
        child: Row(
          children: [
            Text(
              'Собрано:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: wordOpacity,
                  child: Text(
                    display,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: wordColor,
                          letterSpacing: 1.2,
                          shadows: pulse > 0
                              ? [
                                  Shadow(
                                    color: colors.tertiary
                                        .withValues(alpha: pulse * 0.6),
                                    blurRadius: 8 + pulse * 10,
                                  ),
                                ]
                              : null,
                        ),
                  ),
                ),
              ),
            ),
            if (wordsCollected > 0) ...[
              const SizedBox(width: 8),
              Text(
                '×$wordsCollected',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookmarkHintButton extends StatelessWidget {
  const _BookmarkHintButton({
    required this.enabled,
    required this.costsStar,
    required this.idleBlink,
    required this.glowAnimation,
    required this.onPressed,
  });

  final bool enabled;
  final bool costsStar;
  final bool idleBlink;
  final Animation<double> glowAnimation;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = costsStar ? 'Подсказка (1 ⭐)' : 'Подсказка';

    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? () => unawaited(onPressed()) : null,
      icon: idleBlink
          ? _HintBulbGlow(
              glowAnimation: glowAnimation,
            )
          : const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFFFB300),
            ),
    );
  }
}

class _HintBulbGlow extends StatelessWidget {
  const _HintBulbGlow({required this.glowAnimation});

  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        final breathe = 0.35 + 0.35 * glowAnimation.value;
        final blinkPulse = 0.35 +
            0.65 * ((math.sin(glowAnimation.value * math.pi * 4) + 1) / 2);
        final glow = breathe * blinkPulse;
        final iconColor = Color.lerp(
          const Color(0xFFFFD54F),
          const Color(0xFFFF8F00),
          glowAnimation.value,
        )!;

        return SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300)
                            .withValues(alpha: 0.45 + 0.45 * glow),
                        blurRadius: 8 + 14 * glow,
                        spreadRadius: 0.5 + 2.5 * glow,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.lightbulb_rounded,
                color: iconColor,
                size: 26,
              ),
            ],
          ),
        );
      },
    );
  }
}
