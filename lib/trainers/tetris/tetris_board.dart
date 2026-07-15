import '../../services/tetris_dictionary_service.dart';

class TetrisWordMatch {
  const TetrisWordMatch({
    required this.indices,
    required this.word,
  });

  final List<int> indices;
  final TetrisWordEntry word;
}

class TetrisBoard {
  TetrisBoard({required this.cols, required this.rows})
      : _cells = List<String?>.filled(cols * rows, null);

  final int cols;
  final int rows;
  final List<String?> _cells;

  List<String?> get cells => List.unmodifiable(_cells);

  String? cellAt(int index) => _cells[index];

  bool get isFull => _cells.every((c) => c != null);

  int placeInColumn(int col, String block) {
    for (var row = rows - 1; row >= 0; row--) {
      final index = row * cols + col;
      if (_cells[index] == null) {
        _cells[index] = block;
        return index;
      }
    }
    return -1;
  }

  List<TetrisWordMatch> findAllMatches(
    Map<int, Map<String, List<TetrisWordEntry>>> indexByLength,
  ) {
    final matches = <TetrisWordMatch>[];
    final seen = <String>{};
    if (indexByLength.isEmpty) return matches;
    final lengths = indexByLength.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var row = 0; row < rows; row++) {
      final lineIndices = [for (var c = 0; c < cols; c++) row * cols + c];
      _scanLine(lineIndices, lengths, indexByLength, matches, seen);
    }
    for (var col = 0; col < cols; col++) {
      final lineIndices = [for (var r = 0; r < rows; r++) r * cols + col];
      _scanLine(lineIndices, lengths, indexByLength, matches, seen);
    }

    return matches;
  }

  void clearMatches(Iterable<TetrisWordMatch> matches) {
    for (final match in matches) {
      for (final index in match.indices) {
        _cells[index] = null;
      }
    }
  }

  void applyGravity() {
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
      while (writeRow >= 0) {
        _cells[writeRow * cols + col] = null;
        writeRow--;
      }
    }
  }

  void _scanLine(
    List<int> lineIndices,
    List<int> lengths,
    Map<int, Map<String, List<TetrisWordEntry>>> indexByLength,
    List<TetrisWordMatch> out,
    Set<String> seen,
  ) {
    for (var start = 0; start < lineIndices.length; start++) {
      for (final len in lengths) {
        final end = start + len;
        if (end > lineIndices.length) continue;
        final slice = lineIndices.sublist(start, end);
        final values = <String>[];
        var hasNull = false;
        for (final idx in slice) {
          final value = _cells[idx];
          if (value == null) {
            hasNull = true;
            break;
          }
          values.add(value);
        }
        if (hasNull) continue;
        final bucket = indexByLength[len];
        if (bucket == null) continue;

        final key = values.join('|');
        final reversedKey = values.reversed.join('|');
        final words = <TetrisWordEntry>[
          ...?bucket[key],
          ...?bucket[reversedKey],
        ];
        if (words.isEmpty) continue;

        for (final word in words) {
          final sorted = [...slice]..sort();
          final uniqueKey = '${word.text}:${sorted.join(",")}';
          if (!seen.add(uniqueKey)) continue;
          out.add(TetrisWordMatch(indices: slice, word: word));
        }
      }
    }
  }
}
