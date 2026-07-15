import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/bookmark_window/bookmark_window_board.dart';
import 'package:reader/trainers/schulte/schulte_spellable_words.dart';
import 'package:reader/trainers/schulte/schulte_word_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    dictionary = DictionaryService(random: Random(7));
    await dictionary.initialize();
  });

  BookmarkWindowBoard boardWithCells(List<String?> cells, {int cols = 4}) {
    final rows = cells.length ~/ cols;
    return BookmarkWindowBoard(
      cols: cols,
      rows: rows,
      cells: cells,
      syllablePool: const ['МА', 'ПА', 'КО', 'ЛО'],
      wordsByLengthDesc: const [],
      random: Random(1),
    );
  }

  test('detects horizontal word in row', () {
    final board = boardWithCells([
      'МА', 'МА', 'КО', 'ЛО',
    ]);

    final matches = board.findAllMatches();
    expect(matches, isEmpty);

    final board2 = BookmarkWindowBoard.create(
      dictionary: dictionary,
      random: Random(99),
      cols: 6,
      rows: 4,
    );
    expect(board2.cellCount, 24);
    expect(board2.cells.every((c) => c != null && c!.length == 2), isTrue);
  });

  test('swap adjacent cells', () {
    final board = boardWithCells([
      'КО', 'МА', 'ЛО', 'ТО',
    ]);
    board.swap(0, 1);
    expect(board.cellAt(0), 'МА');
    expect(board.cellAt(1), 'КО');
  });

  test('gravity keeps column filled', () {
    final board = boardWithCells([
      'АА', null, 'ББ', 'ВВ',
      'ГГ', 'ДД', null, 'ЕЕ',
    ], cols: 2);

    board.applyGravityAndRefill();

    expect(board.cellAt(0), isNotNull);
    expect(board.cellAt(1), isNotNull);
    expect(board.cellAt(2), isNotNull);
    expect(board.cellAt(3), isNotNull);
    expect(board.cells.every((c) => c != null), isTrue);
  });

  test('player match requires swap involvement and new word', () {
    final words = SchulteWordIndex.build(dictionary);
    final board = BookmarkWindowBoard(
      cols: 4,
      rows: 1,
      cells: ['МА', 'КО', 'МА', 'ЛО'],
      syllablePool: const ['МА', 'КО', 'ЛО'],
      wordsByLengthDesc: words,
      random: Random(1),
    );

    final before = board.cells;
    board.swap(1, 2);
    final matches = board
        .findAllMatches()
        .where((m) => m.intersectsIndices({1, 2}, board.cols))
        .toList();

    expect(matches, hasLength(1));
    expect(matches.first.word.text, 'МАМА');
    expect(board.isPlayerMatch(before, matches.first, {1, 2}), isTrue);
  });

  test('findFirstWordSwapHint finds adjacent swap', () {
    final words = SchulteWordIndex.build(dictionary);
    final board = BookmarkWindowBoard(
      cols: 4,
      rows: 1,
      cells: ['МА', 'КО', 'МА', 'ЛО'],
      syllablePool: const ['МА', 'КО', 'ЛО'],
      wordsByLengthDesc: words,
      random: Random(1),
    );

    final hint = board.findFirstWordSwapHint();
    expect(hint, isNotNull);
    expect(hint!.previewWord, 'МАМА');
    expect(board.areAdjacent(hint.indexA, hint.indexB), isTrue);
  });

  test('sortMatchesBottomFirst prefers lower rows', () {
    const cols = 6;
    final matches = [
      BookmarkWindowMatch(
        row: 0,
        col: 0,
        orientation: BookmarkWindowOrientation.horizontalLtr,
        word: _fakeWord('ВЕРХ'),
      ),
      BookmarkWindowMatch(
        row: 3,
        col: 1,
        orientation: BookmarkWindowOrientation.horizontalLtr,
        word: _fakeWord('НИЗ'),
      ),
    ];
    final sorted = sortMatchesBottomFirst(matches, cols);
    expect(sorted.first.row, 3);
    expect(sorted.last.row, 0);
  });

  test('pickNonOverlappingMatches skips shared syllables', () {
    const cols = 4;
    const loma = SchulteSpellableWord(
      entryId: 'loma',
      text: 'ЛОМА',
      syllables: ['ЛО', 'МА'],
    );
    const koza = SchulteSpellableWord(
      entryId: 'koza',
      text: 'КОЗА',
      syllables: ['КО', 'ЗА'],
    );

    final overlap = BookmarkWindowMatch(
      row: 0,
      col: 1,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: loma,
    );
    final shared = BookmarkWindowMatch(
      row: 0,
      col: 0,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: loma,
    );
    final separate = BookmarkWindowMatch(
      row: 1,
      col: 0,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: koza,
    );

    final picked = pickNonOverlappingMatches(
      [overlap, shared, separate],
      cols,
    );

    expect(picked, hasLength(2));
    expect(picked.any((m) => m.word.text == 'ЛОМА'), isTrue);
    expect(picked.any((m) => m.word.text == 'КОЗА'), isTrue);
  });

  test('pickPlayerSwapMatch prefers hinted word over other matches', () {
    const cols = 6;
    const loma = SchulteSpellableWord(
      entryId: 'loma',
      text: 'ЛОМА',
      syllables: ['ЛО', 'МА'],
    );
    const kora = SchulteSpellableWord(
      entryId: 'kora',
      text: 'КОРА',
      syllables: ['КО', 'РА'],
    );

    final lower = BookmarkWindowMatch(
      row: 3,
      col: 1,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: kora,
    );
    final upper = BookmarkWindowMatch(
      row: 0,
      col: 2,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: loma,
    );

    final withoutHint = pickPlayerSwapMatch([lower, upper], cols);
    expect(withoutHint!.word.text, 'КОРА');

    final withHint = pickPlayerSwapMatch(
      [lower, upper],
      cols,
      hintedWord: 'ЛОМА',
      swapIndices: const {7, 8},
    );
    expect(withHint!.word.text, 'ЛОМА');
  });

  test('pickPrimarySwapMatch prefers word built from both swapped cells', () {
    const cols = 6;
    const mama = SchulteSpellableWord(
      entryId: 'mama',
      text: 'МАМА',
      syllables: ['МА', 'МА'],
    );
    const masha = SchulteSpellableWord(
      entryId: 'masha',
      text: 'МАША',
      syllables: ['МА', 'ША'],
    );

    // Обмен 1↔2: горизонтально МАША (1,2); МАМА (1,7) задевает только один слог.
    final mashaMatch = BookmarkWindowMatch(
      row: 0,
      col: 1,
      orientation: BookmarkWindowOrientation.horizontalLtr,
      word: masha,
    );
    final mamaMatch = BookmarkWindowMatch(
      row: 0,
      col: 1,
      orientation: BookmarkWindowOrientation.verticalTtb,
      word: mama,
    );

    final picked = pickPrimarySwapMatch(
      [mamaMatch, mashaMatch],
      {1, 2},
      cols,
    );
    expect(picked!.word.text, 'МАША');
  });

  test('detects vertical and reverse horizontal words', () {
    const loma = SchulteSpellableWord(
      entryId: 'loma',
      text: 'ЛОМА',
      syllables: ['ЛО', 'МА'],
    );

    final verticalTtb = BookmarkWindowBoard(
      cols: 1,
      rows: 2,
      cells: ['ЛО', 'МА'],
      syllablePool: const ['ЛО', 'МА'],
      wordsByLengthDesc: const [loma],
      random: Random(1),
    );
    expect(verticalTtb.findAllMatches(), hasLength(1));
    expect(
      verticalTtb.findAllMatches().first.orientation,
      BookmarkWindowOrientation.verticalTtb,
    );

    final verticalBtt = BookmarkWindowBoard(
      cols: 1,
      rows: 2,
      cells: ['МА', 'ЛО'],
      syllablePool: const ['ЛО', 'МА'],
      wordsByLengthDesc: const [loma],
      random: Random(1),
    );
    expect(verticalBtt.findAllMatches(), hasLength(1));
    expect(
      verticalBtt.findAllMatches().first.orientation,
      BookmarkWindowOrientation.verticalBtt,
    );

    final horizontalRtl = BookmarkWindowBoard(
      cols: 2,
      rows: 1,
      cells: ['МА', 'ЛО'],
      syllablePool: const ['МА', 'ЛО'],
      wordsByLengthDesc: const [loma],
      random: Random(1),
    );
    expect(horizontalRtl.findAllMatches(), hasLength(1));
    expect(
      horizontalRtl.findAllMatches().first.orientation,
      BookmarkWindowOrientation.horizontalRtl,
    );
    expect(horizontalRtl.findAllMatches().first.word.text, 'ЛОМА');
  });

  test('limits duplicate syllables by dictionary usefulness', () {
    final words = SchulteWordIndex.build(dictionary);
    final syllableWordCounts = BookmarkWindowBoard.buildSyllableWordCounts(words);

    int maxAllowed(String syllable) {
      final wordCount = syllableWordCounts[syllable] ?? 1;
      if (wordCount <= 1) return 1;
      if (wordCount <= 4) return 2;
      return 3;
    }

    for (var seed = 0; seed < 30; seed++) {
      final board = BookmarkWindowBoard.create(
        dictionary: dictionary,
        random: Random(seed),
      );

      final onBoard = <String, int>{};
      for (final cell in board.cells) {
        onBoard[cell!] = (onBoard[cell] ?? 0) + 1;
      }

      for (final entry in onBoard.entries) {
        expect(
          entry.value,
          lessThanOrEqualTo(maxAllowed(entry.key)),
          reason: '${entry.key} x${entry.value} at seed $seed',
        );
      }

      for (var i = 0; i < 6; i++) {
        board.applyGravityAndRefill();
        final after = <String, int>{};
        for (final cell in board.cells) {
          after[cell!] = (after[cell] ?? 0) + 1;
        }
        for (final entry in after.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(maxAllowed(entry.key)),
            reason: '${entry.key} x${entry.value} after refill $i seed $seed',
          );
        }
      }
    }
  });

  test('detects KUCHA after swap from reversed syllables', () {
    const kucha = SchulteSpellableWord(
      entryId: 'kucha',
      text: 'КУЧА',
      syllables: ['КУ', 'ЧА'],
    );

    final before = ['ЧА', 'КУ', 'ЛО', 'ТО'];
    final board = BookmarkWindowBoard(
      cols: 4,
      rows: 1,
      cells: List<String?>.from(before),
      syllablePool: const ['КУ', 'ЧА', 'ЛО', 'ТО'],
      wordsByLengthDesc: const [kucha],
      random: Random(1),
    );

    // ЧА|КУ уже читается как КУЧА справа налево, но до обмена не снимается.
    final rtlBefore = board.findAllMatches();
    expect(rtlBefore, hasLength(1));
    expect(rtlBefore.first.word.text, 'КУЧА');

    board.swap(0, 1);
    final matches = board
        .findAllMatches()
        .where((m) => m.intersectsIndices({0, 1}, board.cols))
        .toList();

    expect(matches, hasLength(1));
    expect(matches.first.word.text, 'КУЧА');
    expect(
      board.isPlayerMatch(before, matches.first, {0, 1}),
      isTrue,
    );
  });
}

SchulteSpellableWord _fakeWord(String text) {
  return SchulteSpellableWord(
    entryId: text,
    text: text,
    syllables: [text.substring(0, 2)],
  );
}
