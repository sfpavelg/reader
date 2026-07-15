import 'dart:math';

import '../../services/dictionary_service.dart';
import '../bookmark_window/bookmark_window_board.dart';
import '../schulte/schulte_word_index.dart';
import 'ugadayka_difficulty.dart';

/// Поле «Угадайка»: пары слогов, переворот и удаление совпадений.
class UgadaykaBoard {
  UgadaykaBoard({
    required this.cols,
    required this.rows,
    required List<String?> cells,
    List<bool>? faceUp,
  })  : _cells = List<String?>.from(cells),
        _faceUp = List<bool>.from(faceUp ?? List.filled(cells.length, false));

  static const defaultCols = 6;
  static const defaultRows = 8;

  final int cols;
  final int rows;
  final List<String?> _cells;
  final List<bool> _faceUp;

  int get cellCount => cols * rows;
  List<String?> get cells => List.unmodifiable(_cells);
  List<bool> get faceUp => List.unmodifiable(_faceUp);

  String? cellAt(int index) => _cells[index];

  bool isEmpty(int index) => _cells[index] == null;

  bool isFaceUp(int index) => _faceUp[index];

  bool get isComplete => _cells.every((cell) => cell == null);

  int get remainingCards => _cells.where((cell) => cell != null).length;

  void reveal(int index) {
    if (isEmpty(index)) return;
    _faceUp[index] = true;
  }

  void hide(int index) {
    if (isEmpty(index)) return;
    _faceUp[index] = false;
  }

  void clearPair(int a, int b) {
    _cells[a] = null;
    _cells[b] = null;
    _faceUp[a] = false;
    _faceUp[b] = false;
  }

  bool syllablesMatch(int a, int b) {
    final left = _cells[a];
    final right = _cells[b];
    return left != null && left == right;
  }

  factory UgadaykaBoard.create({
    required List<String> syllablePool,
    Random? random,
    int cols = defaultCols,
    int rows = defaultRows,
  }) {
    final rng = random ?? Random();
    final slotCount = cols * rows;
    if (slotCount.isOdd) {
      throw ArgumentError('Grid must have an even number of cells');
    }
    final pairCount = slotCount ~/ 2;
    if (syllablePool.length < pairCount) {
      throw StateError('Need at least $pairCount unique syllables');
    }

    final pool = List<String>.from(syllablePool)..shuffle(rng);
    final picked = pool.take(pairCount).toList();
    final deck = <String>[];
    for (final syllable in picked) {
      deck
        ..add(syllable)
        ..add(syllable);
    }
    deck.shuffle(rng);

    return UgadaykaBoard(
      cols: cols,
      rows: rows,
      cells: deck,
    );
  }

  factory UgadaykaBoard.fromDictionary(
    DictionaryService dictionary, {
    Random? random,
    UgadaykaDifficulty difficulty = UgadaykaDifficulty.hard,
  }) {
    final words = SchulteWordIndex.build(dictionary)
        .where((word) => word.syllables.isNotEmpty)
        .toList();
    final pool = BookmarkWindowBoard.buildSyllableWordCounts(words).keys.toList()
      ..sort();
    return UgadaykaBoard.create(
      syllablePool: pool,
      random: random,
      cols: difficulty.cols,
      rows: difficulty.rows,
    );
  }
}
