import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_difficulty.dart';
import 'schulte_spellable_words.dart';
import 'schulte_task.dart';
import 'schulte_word_picker.dart';

class SchulteGenerator {
  SchulteGenerator({
    required DictionaryService dictionary,
    Random? random,
    SchulteDifficulty difficulty = SchulteDifficulty.easy,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _difficulty = difficulty,
        _picker = SchulteWordPicker(
          dictionary: dictionary,
          random: random,
          maxSyllables: 5,
        );

  final DictionaryService _dictionary;
  final Random _random;
  final SchulteDifficulty _difficulty;
  final SchulteWordPicker _picker;

  SchulteDifficulty get difficulty => _difficulty;

  int get cols => _difficulty.cols;
  int get rows => _difficulty.rows;
  int get maxSpareSyllables => _difficulty.maxSpareSyllables;

  SchulteWordPicker get wordPicker => _picker;

  int get cellCount => _difficulty.cellCount;

  SchulteTask generate() {
    final packed = _packWords(capacity: cellCount);
    if (packed.isEmpty) {
      throw StateError('No words to pack into Schulte grid');
    }
    return _taskFromPacked(packed);
  }

  /// Подбирает слова так, чтобы слогами заполнить поле по максимуму.
  List<DictionaryEntry> _packWords({required int capacity}) {
    final pool = _picker.eligiblePool;
    if (pool.isEmpty) {
      throw StateError('No two-letter-syllable words for Schulte');
    }

    var best = <DictionaryEntry>[];
    var bestScore = -1;
    final attempts = capacity >= 40 ? 64 : 48;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final shuffled = List<DictionaryEntry>.from(pool)..shuffle(_random);
      final picked = <DictionaryEntry>[];
      final seenTexts = <String>{};
      var used = 0;

      for (final entry in shuffled) {
        if (!seenTexts.add(entry.text)) continue;
        final n = entry.syllables.length;
        if (used + n > capacity) continue;
        picked.add(entry);
        used += n;
        if (capacity - used <= maxSpareSyllables) break;
      }

      final lengths = {for (final e in picked) e.syllables.length};
      // Плотность заполнения важнее, но смесь длин (2+3) делает комбинации понятнее.
      final score = used * 100 + lengths.length * 15 + picked.length;
      if (score > bestScore) {
        best = picked;
        bestScore = score;
      }
      if (used >= capacity - maxSpareSyllables && lengths.length >= 2) break;
    }

    return best;
  }

  SchulteTask _taskFromPacked(List<DictionaryEntry> packed) {
    final count = cellCount;
    final wordSyllables = <String>[
      for (final e in packed) ...e.syllables,
    ];
    final gridTexts = _fillGridTexts(wordSyllables, count);

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

    final gridSyllables = [
      for (final c in cells)
        if (c.text != null) c.text!,
    ];
    final spellableWords = SchulteSpellableWords.findForGrid(
      dictionary: _dictionary,
      gridSyllables: gridSyllables,
    );

    final primary = packed.first;
    return SchulteTask(
      taskId: 'schulte_${DateTime.now().microsecondsSinceEpoch}',
      entryId: primary.id,
      word: primary.text,
      syllables: List<String>.from(primary.syllables),
      packedEntryIds: packed.map((e) => e.id).toList(),
      packedWords: packed.map((e) => e.text).toList(),
      cols: cols,
      rows: rows,
      cells: cells,
      spellableWords: spellableWords,
    );
  }

  List<String> _fillGridTexts(List<String> wordSyllables, int count) {
    final texts = List<String>.from(wordSyllables);
    if (texts.length > count) {
      throw StateError('Packed syllables exceed grid size');
    }

    final needed = count - texts.length;
    if (needed > 0) {
      final distractors = _dictionary
          .entriesForLevel(1)
          .map((e) => e.text)
          .where((t) => t.length == 2)
          .toList();
      if (distractors.isEmpty) {
        throw StateError('No distractor syllables for Schulte');
      }
      final shuffled = List<String>.from(distractors)..shuffle(_random);
      for (var i = 0; i < needed; i++) {
        texts.add(shuffled[i % shuffled.length]);
      }
    }

    texts.shuffle(_random);
    return texts;
  }
}
