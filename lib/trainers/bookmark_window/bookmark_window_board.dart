import 'dart:math';

import '../../services/dictionary_service.dart';
import '../schulte/schulte_spellable_words.dart';
import '../schulte/schulte_word_index.dart';

/// Направление слова на поле «Окошко».
enum BookmarkWindowOrientation {
  horizontalLtr,
  horizontalRtl,
  verticalTtb,
  verticalBtt,
}

/// Слово на поле «Окошко» (горизонталь или вертикаль, любое направление).
class BookmarkWindowMatch {
  const BookmarkWindowMatch({
    required this.row,
    required this.col,
    required this.orientation,
    required this.word,
  });

  /// Якорь — клетка первого слога слова в порядке чтения.
  final int row;
  final int col;
  final BookmarkWindowOrientation orientation;
  final SchulteSpellableWord word;

  int get length => word.syllables.length;

  bool intersectsIndices(Set<int> cellIndices, int cols) {
    for (final index in this.cellIndices(cols)) {
      if (cellIndices.contains(index)) return true;
    }
    return false;
  }

  List<int> cellIndices(int cols) {
    final indices = <int>[];
    for (var i = 0; i < length; i++) {
      switch (orientation) {
        case BookmarkWindowOrientation.horizontalLtr:
          indices.add(row * cols + col + i);
        case BookmarkWindowOrientation.horizontalRtl:
          indices.add(row * cols + col - i);
        case BookmarkWindowOrientation.verticalTtb:
          indices.add((row + i) * cols + col);
        case BookmarkWindowOrientation.verticalBtt:
          indices.add((row - i) * cols + col);
      }
    }
    return indices;
  }
}

/// Пара соседних ячеек, обмен которых собирает слово.
class BookmarkWindowSwapHint {
  const BookmarkWindowSwapHint({
    required this.indexA,
    required this.indexB,
    required this.previewWord,
  });

  final int indexA;
  final int indexB;
  final String previewWord;
}

/// Сначала нижние совпадения, затем левее.
List<BookmarkWindowMatch> sortMatchesBottomFirst(
  List<BookmarkWindowMatch> matches,
  int cols,
) {
  int bottomRow(BookmarkWindowMatch match) {
    return match
        .cellIndices(cols)
        .map((index) => index ~/ cols)
        .reduce((a, b) => a > b ? a : b);
  }

  int leftCol(BookmarkWindowMatch match) {
    return match
        .cellIndices(cols)
        .map((index) => index % cols)
        .reduce((a, b) => a < b ? a : b);
  }

  final sorted = List<BookmarkWindowMatch>.from(matches);
  sorted.sort((a, b) {
    final rowCmp = bottomRow(b).compareTo(bottomRow(a));
    if (rowCmp != 0) return rowCmp;
    return leftCol(a).compareTo(leftCol(b));
  });
  return sorted;
}

/// Совпадения без общих слогов: каждый слог — только в одном слове за шаг.
List<BookmarkWindowMatch> pickNonOverlappingMatches(
  List<BookmarkWindowMatch> matches,
  int cols,
) {
  final usedCells = <int>{};
  final picked = <BookmarkWindowMatch>[];

  for (final match in matches) {
    final indices = match.cellIndices(cols);
    if (indices.any(usedCells.contains)) continue;
    picked.add(match);
    usedCells.addAll(indices);
  }
  return picked;
}

/// Совпадение после хода игрока; при подсказке — слово, показанное в демо.
BookmarkWindowMatch? pickPlayerSwapMatch(
  List<BookmarkWindowMatch> matches,
  int cols, {
  String? hintedWord,
  Set<int>? swapIndices,
  bool Function(BookmarkWindowMatch)? isValid,
}) {
  if (matches.isEmpty) return null;

  bool valid(BookmarkWindowMatch match) => isValid == null || isValid(match);

  Iterable<BookmarkWindowMatch> candidates = matches;
  if (hintedWord != null) {
    final hinted =
        matches.where((match) => match.word.text == hintedWord).toList();
    if (hinted.isNotEmpty) candidates = hinted;
  }

  final primary = pickPrimarySwapMatch(
    candidates.toList(),
    swapIndices ?? const {},
    cols,
  );
  if (primary != null && valid(primary)) return primary;

  for (final match in pickNonOverlappingMatches(
    sortMatchesBottomFirst(matches, cols),
    cols,
  )) {
    if (valid(match)) return match;
  }
  return null;
}

/// Главное слово после обмена: сначала то, что использует оба слога хода.
BookmarkWindowMatch? pickPrimarySwapMatch(
  List<BookmarkWindowMatch> matches,
  Set<int> swapIndices,
  int cols,
) {
  if (matches.isEmpty) return null;

  List<BookmarkWindowMatch> pool = matches;
  if (swapIndices.length == 2) {
    final usingBoth = matches.where((match) {
      final cells = match.cellIndices(cols).toSet();
      return swapIndices.every(cells.contains);
    }).toList();
    if (usingBoth.isNotEmpty) pool = usingBoth;
  }

  pool = List<BookmarkWindowMatch>.from(pool);
  pool.sort((a, b) {
    final len = b.length.compareTo(a.length);
    if (len != 0) return len;
    final bottomFirst = sortMatchesBottomFirst([a, b], cols);
    return bottomFirst.first == a ? -1 : 1;
  });
  return pool.first;
}

/// Падение слога вниз после удаления слова.
class BookmarkWindowGravityMove {
  const BookmarkWindowGravityMove({
    required this.fromIndex,
    required this.toIndex,
    required this.syllable,
  });

  final int fromIndex;
  final int toIndex;
  final String syllable;
}

/// Новый слог, выезжающий сверху.
class BookmarkWindowGravitySpawn {
  const BookmarkWindowGravitySpawn({
    required this.toIndex,
    required this.syllable,
    required this.fromRow,
  });

  final int toIndex;
  final String syllable;

  /// Стартовая строка (может быть < 0 — над сеткой).
  final double fromRow;
}

class BookmarkWindowGravityPlan {
  const BookmarkWindowGravityPlan({
    required this.moves,
    required this.spawns,
  });

  final List<BookmarkWindowGravityMove> moves;
  final List<BookmarkWindowGravitySpawn> spawns;

  int maxFallRowsFor(int cols) {
    var max = 1;
    for (final move in moves) {
      final delta = (move.fromIndex ~/ cols) - (move.toIndex ~/ cols);
      final distance = delta.abs();
      if (distance > max) max = distance;
    }
    for (final spawn in spawns) {
      final toRow = spawn.toIndex ~/ cols;
      final fall = (toRow - spawn.fromRow).ceil();
      if (fall > max) max = fall;
    }
    return max;
  }
}

/// Поле слогов: обмен соседей, гравитация, сбор слов.
class BookmarkWindowBoard {
  BookmarkWindowBoard({
    required this.cols,
    required this.rows,
    required List<String?> cells,
    required this.syllablePool,
    required List<SchulteSpellableWord> wordsByLengthDesc,
    required Random random,
    Map<String, int>? syllableWordCounts,
  })  : _cells = List<String?>.from(cells),
        _wordsByLengthDesc = wordsByLengthDesc
            .where((w) => w.syllables.length >= 2)
            .toList()
          ..sort((a, b) => b.syllables.length.compareTo(a.syllables.length)),
        _random = random,
        _syllableWordCounts = syllableWordCounts ??
            buildSyllableWordCounts(
              wordsByLengthDesc.where((w) => w.syllables.length >= 2).toList(),
            );

  final int cols;
  final int rows;
  final List<String> syllablePool;
  final List<SchulteSpellableWord> _wordsByLengthDesc;
  final Random _random;
  final Map<String, int> _syllableWordCounts;

  final List<String?> _cells;

  int get cellCount => cols * rows;

  List<String?> get cells => List.unmodifiable(_cells);

  String? cellAt(int index) => _cells[index];

  static Map<String, int> buildSyllableWordCounts(
    List<SchulteSpellableWord> words,
  ) {
    final counts = <String, int>{};
    for (final word in words) {
      if (word.syllables.length < 2) continue;
      for (final syllable in word.syllables.toSet()) {
        if (syllable.length != 2) continue;
        counts[syllable] = (counts[syllable] ?? 0) + 1;
      }
    }
    return counts;
  }

  int _maxOnBoardFor(String syllable) {
    final wordCount = _syllableWordCounts[syllable] ?? 1;
    if (wordCount <= 1) return 1;
    if (wordCount <= 4) return 2;
    return 3;
  }

  int _countOnBoard(String syllable, {Map<String, int>? extraOnBoard}) {
    var count = 0;
    for (final cell in _cells) {
      if (cell == syllable) count++;
    }
    if (extraOnBoard != null) {
      count += extraOnBoard[syllable] ?? 0;
    }
    return count;
  }

  String _pickBalancedSyllable({Map<String, int>? extraOnBoard}) {
    final candidates = <String>[];
    final weights = <int>[];

    for (final syllable in syllablePool) {
      if (_countOnBoard(syllable, extraOnBoard: extraOnBoard) >=
          _maxOnBoardFor(syllable)) {
        continue;
      }
      candidates.add(syllable);
      weights.add(_syllableWordCounts[syllable] ?? 1);
    }

    if (candidates.isNotEmpty) {
      return _weightedPick(candidates, weights);
    }

    var best = syllablePool.first;
    var bestCount = _countOnBoard(best, extraOnBoard: extraOnBoard);
    for (final syllable in syllablePool.skip(1)) {
      final onBoard = _countOnBoard(syllable, extraOnBoard: extraOnBoard);
      if (onBoard < bestCount) {
        best = syllable;
        bestCount = onBoard;
      }
    }
    return best;
  }

  String _weightedPick(List<String> candidates, List<int> weights) {
    var total = 0;
    for (final weight in weights) {
      total += weight;
    }
    var roll = _random.nextInt(total);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) return candidates[i];
    }
    return candidates.last;
  }

  bool areAdjacent(int a, int b) {
    final ar = a ~/ cols;
    final ac = a % cols;
    final br = b ~/ cols;
    final bc = b % cols;
    final dr = (ar - br).abs();
    final dc = (ac - bc).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  /// Соседняя пара, одним обменом которой можно собрать слово.
  BookmarkWindowSwapHint? findFirstWordSwapHint() {
    final before = cells;
    for (var a = 0; a < cellCount; a++) {
      for (var b = a + 1; b < cellCount; b++) {
        if (!areAdjacent(a, b)) continue;
        swap(a, b);
        final matches = findAllMatches()
            .where((m) => m.intersectsIndices({a, b}, cols))
            .where((m) => !matchExistedBefore(before, m))
            .toList();
        swap(a, b);
        if (matches.isNotEmpty) {
          final primary = pickPrimarySwapMatch(matches, {a, b}, cols);
          return BookmarkWindowSwapHint(
            indexA: a,
            indexB: b,
            previewWord: primary!.word.text,
          );
        }
      }
    }
    return null;
  }

  void swap(int a, int b) {
    final tmp = _cells[a];
    _cells[a] = _cells[b];
    _cells[b] = tmp;
  }

  factory BookmarkWindowBoard.create({
    required DictionaryService dictionary,
    Random? random,
    int cols = 6,
    int rows = 8,
  }) {
    final rng = random ?? Random();
    final words = SchulteWordIndex.build(dictionary)
        .where((w) => w.syllables.length >= 2)
        .toList();

    final syllableWordCounts = buildSyllableWordCounts(words);
    final syllablePool = syllableWordCounts.keys.toList()..sort();
    if (syllablePool.isEmpty) {
      throw StateError('No two-letter syllables available for bookmark window');
    }

    BookmarkWindowBoard? board;
    for (var attempt = 0; attempt < 24; attempt++) {
      board = BookmarkWindowBoard(
        cols: cols,
        rows: rows,
        cells: List<String?>.filled(cols * rows, null),
        syllablePool: syllablePool,
        wordsByLengthDesc: words,
        random: rng,
        syllableWordCounts: syllableWordCounts,
      );
      for (var i = 0; i < board.cellCount; i++) {
        board._cells[i] = board._pickBalancedSyllable();
      }
      board._resolveInitialWithoutStars();
      if (board.findFirstWordSwapHint() != null) {
        return board;
      }
    }

    return board!;
  }

  void _resolveInitialWithoutStars() {
    while (true) {
      final matches = findAllMatches();
      if (matches.isEmpty) break;
      for (final match in matches) {
        _clearMatch(match);
      }
      applyGravityAndRefill();
    }
  }

  List<BookmarkWindowMatch> findAllMatches() {
    final results = <BookmarkWindowMatch>[];
    for (var row = 0; row < rows; row++) {
      results.addAll(_matchesInRow(row, BookmarkWindowOrientation.horizontalLtr));
      results.addAll(_matchesInRow(row, BookmarkWindowOrientation.horizontalRtl));
    }
    for (var col = 0; col < cols; col++) {
      results.addAll(_matchesInCol(col, BookmarkWindowOrientation.verticalTtb));
      results.addAll(_matchesInCol(col, BookmarkWindowOrientation.verticalBtt));
    }
    return _dedupeMatches(results);
  }

  List<BookmarkWindowMatch> _dedupeMatches(List<BookmarkWindowMatch> matches) {
    final seen = <String>{};
    final unique = <BookmarkWindowMatch>[];
    for (final match in matches) {
      final indices = match.cellIndices(cols)..sort();
      final key = indices.join(',');
      if (seen.add(key)) {
        unique.add(match);
      }
    }
    return unique;
  }

  List<BookmarkWindowMatch> _matchesInRow(
    int row,
    BookmarkWindowOrientation orientation,
  ) {
    final matches = <BookmarkWindowMatch>[];
    final rtl = orientation == BookmarkWindowOrientation.horizontalRtl;
    var col = rtl ? cols - 1 : 0;

    while (rtl ? col >= 0 : col < cols) {
      BookmarkWindowMatch? best;
      for (final word in _wordsByLengthDesc) {
        final len = word.syllables.length;
        if (rtl) {
          if (col - len + 1 < 0) continue;
        } else if (col + len > cols) {
          continue;
        }

        var ok = true;
        for (var i = 0; i < len; i++) {
          final cellCol = rtl ? col - i : col + i;
          if (_cells[row * cols + cellCol] != word.syllables[i]) {
            ok = false;
            break;
          }
        }
        if (ok) {
          best = BookmarkWindowMatch(
            row: row,
            col: col,
            orientation: orientation,
            word: word,
          );
          break;
        }
      }
      if (best != null) {
        matches.add(best);
        col += rtl ? -best.length : best.length;
      } else {
        col += rtl ? -1 : 1;
      }
    }
    return matches;
  }

  List<BookmarkWindowMatch> _matchesInCol(
    int col,
    BookmarkWindowOrientation orientation,
  ) {
    final matches = <BookmarkWindowMatch>[];
    final btt = orientation == BookmarkWindowOrientation.verticalBtt;
    var row = btt ? rows - 1 : 0;

    while (btt ? row >= 0 : row < rows) {
      BookmarkWindowMatch? best;
      for (final word in _wordsByLengthDesc) {
        final len = word.syllables.length;
        if (btt) {
          if (row - len + 1 < 0) continue;
        } else if (row + len > rows) {
          continue;
        }

        var ok = true;
        for (var i = 0; i < len; i++) {
          final cellRow = btt ? row - i : row + i;
          if (_cells[cellRow * cols + col] != word.syllables[i]) {
            ok = false;
            break;
          }
        }
        if (ok) {
          best = BookmarkWindowMatch(
            row: row,
            col: col,
            orientation: orientation,
            word: word,
          );
          break;
        }
      }
      if (best != null) {
        matches.add(best);
        row += btt ? -best.length : best.length;
      } else {
        row += btt ? -1 : 1;
      }
    }
    return matches;
  }

  bool matchExistedBefore(List<String?> before, BookmarkWindowMatch match) {
    final indices = match.cellIndices(cols);
    if (indices.length != match.length) return false;
    for (var i = 0; i < match.length; i++) {
      if (before[indices[i]] != match.word.syllables[i]) {
        return false;
      }
    }
    return true;
  }

  bool matchStillOnBoard(BookmarkWindowMatch match) {
    final indices = match.cellIndices(cols);
    for (var i = 0; i < match.length; i++) {
      if (_cells[indices[i]] != match.word.syllables[i]) {
        return false;
      }
    }
    return true;
  }

  bool isPlayerMatch(
    List<String?> before,
    BookmarkWindowMatch match,
    Set<int> swapIndices,
  ) =>
      match.intersectsIndices(swapIndices, cols) &&
      !matchExistedBefore(before, match);

  void clearMatch(BookmarkWindowMatch match) => _clearMatch(match);

  void _clearMatch(BookmarkWindowMatch match) {
    for (final index in match.cellIndices(cols)) {
      _cells[index] = null;
    }
  }

  void applyGravityAndRefill() {
    _applyGravityPlan(_buildGravityPlan());
  }

  BookmarkWindowGravityPlan planGravityAndRefill() => _buildGravityPlan();

  void applyGravityPlan(BookmarkWindowGravityPlan plan) =>
      _applyGravityPlan(plan);

  BookmarkWindowGravityPlan _buildGravityPlan() {
    final moves = <BookmarkWindowGravityMove>[];
    final spawns = <BookmarkWindowGravitySpawn>[];
    final pendingSpawns = <String, int>{};

    for (var col = 0; col < cols; col++) {
      final stack = <String>[];
      final fromRows = <int>[];
      for (var row = rows - 1; row >= 0; row--) {
        final value = _cells[row * cols + col];
        if (value != null) {
          stack.add(value);
          fromRows.add(row);
        }
      }

      var writeRow = rows - 1;
      for (var i = 0; i < stack.length; i++) {
        final fromRow = fromRows[i];
        final toIndex = writeRow * cols + col;
        if (fromRow != writeRow) {
          moves.add(
            BookmarkWindowGravityMove(
              fromIndex: fromRow * cols + col,
              toIndex: toIndex,
              syllable: stack[i],
            ),
          );
        }
        writeRow--;
      }

      var spawnOrder = 0;
      final spawnCount = writeRow + 1;
      while (writeRow >= 0) {
        final syllable = _pickBalancedSyllable(extraOnBoard: pendingSpawns);
        pendingSpawns[syllable] = (pendingSpawns[syllable] ?? 0) + 1;
        spawns.add(
          BookmarkWindowGravitySpawn(
            toIndex: writeRow * cols + col,
            syllable: syllable,
            fromRow: -(spawnCount - spawnOrder).toDouble(),
          ),
        );
        spawnOrder++;
        writeRow--;
      }
    }

    return BookmarkWindowGravityPlan(moves: moves, spawns: spawns);
  }

  void _applyGravityPlan(BookmarkWindowGravityPlan plan) {
    for (var col = 0; col < cols; col++) {
      final stack = <String>[];
      for (var row = rows - 1; row >= 0; row--) {
        final value = _cells[row * cols + col];
        if (value != null) stack.add(value);
      }

      var writeRow = rows - 1;
      for (final value in stack) {
        _cells[writeRow * cols + col] = value;
        writeRow--;
      }

      final colSpawns = plan.spawns
          .where((s) => s.toIndex % cols == col)
          .toList()
        ..sort((a, b) => a.toIndex.compareTo(b.toIndex));
      for (final spawn in colSpawns) {
        _cells[spawn.toIndex] = spawn.syllable;
      }
    }
  }
}
