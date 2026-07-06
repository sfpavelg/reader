import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'syllable_builder_layout.dart';
import 'syllable_builder_level.dart';
import 'syllable_builder_task.dart';
import 'syllable_builder_word_picker.dart';

class SyllableBuilderGenerator {
  SyllableBuilderGenerator({
    required DictionaryService dictionary,
    Random? random,
    int trainerLevelId = SyllableBuilderLevel.level1,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _picker = SyllableBuilderWordPicker(
          dictionary: dictionary,
          random: random,
          trainerLevelId: trainerLevelId,
        );

  final DictionaryService _dictionary;
  final Random _random;
  final SyllableBuilderWordPicker _picker;

  SyllableBuilderWordPicker get wordPicker => _picker;

  void setTrainerLevel(int trainerLevelId) {
    _picker.trainerLevelId = trainerLevelId;
  }

  SyllableBuilderTask generate({
    Set<String> excludeEntryIds = const {},
  }) {
    DictionaryEntry entry;
    if (excludeEntryIds.isEmpty) {
      entry = _picker.pickNext();
    } else {
      final pool = _picker.eligiblePool
          .where((e) => !excludeEntryIds.contains(e.id))
          .toList();
      if (pool.isEmpty) {
        entry = _picker.pickNext();
      } else {
        pool.shuffle(_random);
        entry = pool.first;
      }
    }
    return _taskFromEntry(entry);
  }

  SyllableBuilderTask fromEntry(DictionaryEntry entry) {
    if (!entry.hasSyllableBreakdown) {
      throw ArgumentError('Entry ${entry.id} has no syllable breakdown');
    }
    return _taskFromEntry(entry);
  }

  SyllableBuilderTask _taskFromEntry(DictionaryEntry entry) {
    final count = entry.syllables.length;
    final lanes = List.generate(
      count,
      (i) => SyllableBuilderLayout.laneXFactor(i, count),
    )..shuffle(_random);

    final blocks = <FallingSyllableBlock>[];
    for (var i = 0; i < count; i++) {
      final block = FallingSyllableBlock(
        blockId: '${entry.id}_$i',
        text: entry.syllables[i],
        sequenceIndex: i,
        xFactor: lanes[i],
        startY: SyllableBuilderLayout.startY(
          sequenceIndex: i,
          syllableCount: count,
          randomOffset: _random.nextDouble(),
        ),
      );
      block.y = block.startY;
      blocks.add(block);
    }

    return SyllableBuilderTask(
      taskId: 'syllable_${DateTime.now().microsecondsSinceEpoch}',
      entryId: entry.id,
      word: entry.text,
      syllables: List<String>.from(entry.syllables),
      blocks: blocks,
    );
  }
}
