import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/ugadayka/ugadayka_board.dart';
import 'package:reader/trainers/ugadayka/ugadayka_difficulty.dart';

void main() {
  test('creates guaranteed pairs for full grid', () {
    final board = UgadaykaBoard.create(
      syllablePool: List.generate(30, (i) => 'S$i'.padLeft(2, '0')),
      random: Random(1),
      cols: UgadaykaDifficulty.hard.cols,
      rows: UgadaykaDifficulty.hard.rows,
    );

    expect(board.cols, UgadaykaDifficulty.hard.cols);
    expect(board.rows, UgadaykaDifficulty.hard.rows);
    expect(board.cellCount, 48);
    expect(board.remainingCards, 48);

    final counts = <String, int>{};
    for (final cell in board.cells) {
      expect(cell, isNotNull);
      counts[cell!] = (counts[cell] ?? 0) + 1;
    }
    expect(counts.values.every((count) => count == 2), isTrue);
    expect(counts.length, 24);
  });

  test('easy level uses 12 cards in 3x4 grid', () {
    final board = UgadaykaBoard.create(
      syllablePool: List.generate(10, (i) => 'S$i'),
      random: Random(2),
      cols: UgadaykaDifficulty.easy.cols,
      rows: UgadaykaDifficulty.easy.rows,
    );

    expect(board.cellCount, 12);
    expect(board.remainingCards, 12);
    expect(
      board.cells.where((cell) => cell != null).length,
      12,
    );
  });

  test('match clears cells and completion empties board', () {
    final board = UgadaykaBoard(
      cols: 2,
      rows: 2,
      cells: ['МА', 'МА', 'КО', 'ЛО'],
    );

    board.reveal(0);
    board.reveal(1);
    expect(board.syllablesMatch(0, 1), isTrue);
    board.clearPair(0, 1);

    expect(board.isEmpty(0), isTrue);
    expect(board.isEmpty(1), isTrue);
    expect(board.remainingCards, 2);
    expect(board.isComplete, isFalse);

    board.reveal(2);
    board.reveal(3);
    expect(board.syllablesMatch(2, 3), isFalse);
  });
}
