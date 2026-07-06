import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_spellable_words.dart';
import 'schulte_task.dart';
import 'schulte_word_picker.dart';

class SchulteGenerator {
  SchulteGenerator({
    required DictionaryService dictionary,
    Random? random,
    int gridSize = 3,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _picker = SchulteWordPicker(
          dictionary: dictionary,
          random: random,
          maxSyllables: gridSize * gridSize,
        ),
        _gridSize = gridSize;

  final DictionaryService _dictionary;
  final Random _random;
  final SchulteWordPicker _picker;
  final int _gridSize;

  SchulteWordPicker get wordPicker => _picker;

  SchulteTask generate() {
    return fromEntry(_picker.pickNext());
  }

  SchulteTask fromEntry(DictionaryEntry entry) {
    if (!SchulteWordPicker.isEligibleEntry(
      entry,
      maxSyllables: _gridSize * _gridSize,
    )) {
      throw ArgumentError('Entry ${entry.id} is not eligible for Schulte');
    }
    return _taskFromEntry(entry);
  }

  SchulteTask _taskFromEntry(DictionaryEntry entry) {
    final count = _gridSize * _gridSize;
    final gridTexts = _buildGridTexts(entry.syllables, count);

    final positions = List.generate(count, (i) => i)..shuffle(_random);
    final cells = <SchulteCell>[];
    for (var i = 0; i < count; i++) {
      cells.add(
        SchulteCell(
          gridIndex: positions[i],
          text: gridTexts[i],
        ),
      );
    }
    cells.sort((a, b) => a.gridIndex.compareTo(b.gridIndex));

    final gridSyllables = cells.map((c) => c.text).toList();
    final spellableWords = SchulteSpellableWords.findForGrid(
      dictionary: _dictionary,
      gridSyllables: gridSyllables,
    );

    return SchulteTask(
      taskId: 'schulte_${DateTime.now().microsecondsSinceEpoch}',
      entryId: entry.id,
      word: entry.text,
      syllables: List<String>.from(entry.syllables),
      gridSize: _gridSize,
      cells: cells,
      spellableWords: spellableWords,
    );
  }

  List<String> _buildGridTexts(List<String> targetSyllables, int count) {
    final texts = List<String>.from(targetSyllables);
    if (texts.length > count) {
      throw StateError('Target syllables exceed grid size');
    }

    final distractors = _dictionary
        .entriesForLevel(1)
        .map((e) => e.text)
        .where((t) => t.length == 2)
        .toList();

    final needed = count - texts.length;
    if (needed > 0 && distractors.isNotEmpty) {
      final shuffled = List<String>.from(distractors)..shuffle(_random);
      for (var i = 0; i < needed; i++) {
        texts.add(shuffled[i % shuffled.length]);
      }
    }

    texts.shuffle(_random);
    return texts;
  }
}
