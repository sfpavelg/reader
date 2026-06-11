import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/schulte/schulte_generator.dart';
import 'package:reader/trainers/schulte/schulte_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late SchulteGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(7));
    await dictionary.initialize();
    generator = SchulteGenerator(dictionary: dictionary, random: Random(7));
  });

  test('3x3 grid has 9 unique cells', () {
    final task = generator.generate(levelId: 1, gridSize: 3);
    expect(task.gridSize, 3);
    expect(task.cells, hasLength(9));
    expect(task.cells.map((c) => c.entryId).toSet(), hasLength(9));
  });

  test('alphabetical order ranks match sorted text', () {
    final task = generator.generate(
      levelId: 1,
      gridSize: 3,
      orderMode: SchulteOrderMode.alphabetical,
    );

    final textsByRank = List.generate(
      9,
      (rank) => task.cellWithOrderRank(rank).text,
    );
    final sorted = List<String>.from(textsByRank)..sort();
    expect(textsByRank, sorted);
  });

  test('order rank equals cellCount is out of range', () {
    final task = generator.generate(levelId: 1, gridSize: 3);
    expect(task.cellCount, 9);
    expect(() => task.cellWithOrderRank(task.cellCount), throwsStateError);
  });

  test('difficulty order is non-decreasing', () {
    final task = generator.generate(
      levelId: 1,
      gridSize: 3,
      orderMode: SchulteOrderMode.difficulty,
    );

    final entries = dictionary.entriesForLevel(1);
    final diffById = {for (final e in entries) e.id: e.difficulty};

    var prev = -1;
    for (var rank = 0; rank < 9; rank++) {
      final cell = task.cellWithOrderRank(rank);
      final d = diffById[cell.entryId]!;
      expect(d, greaterThanOrEqualTo(prev));
      prev = d;
    }
  });
}
