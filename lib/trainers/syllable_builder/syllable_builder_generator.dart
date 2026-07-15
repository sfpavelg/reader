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

  static const _dictionaryLevelId = 2;

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
    final levelId = _picker.trainerLevelId;
    final count = entry.syllables.length;
    final distractorCount =
        SyllableBuilderLevel.distractorCount(count, levelId);
    final distractorTexts = _pickDistractorSyllables(
      entry: entry,
      count: distractorCount,
      trainerLevelId: levelId,
    );

    final targetLeadWaves = max(3, distractorCount ~/ 2);
    final targetWaveStride = 2;

    final blocks = <FallingSyllableBlock>[];

    for (var i = 0; i < distractorCount; i++) {
      final block = FallingSyllableBlock(
        blockId: '${entry.id}_d$i',
        text: distractorTexts[i],
        targetSequenceIndex: null,
        spawnWave: i,
        xFactor: SyllableBuilderLayout.randomXFactor(_random.nextDouble()),
        startY: SyllableBuilderLayout.startY(
          stackIndex: i,
          randomOffset: _random.nextDouble(),
        ),
        driftSpeed: 1.2 + _random.nextDouble() * 1.6,
        xPhase: _random.nextDouble() * pi * 2,
      );
      block.y = block.startY;
      blocks.add(block);
    }

    final lanes = List.generate(
      count,
      (i) => SyllableBuilderLayout.laneXFactor(i, count),
    )..shuffle(_random);

    for (var i = 0; i < count; i++) {
      final spawnWave = distractorCount + targetLeadWaves + i * targetWaveStride;
      final block = FallingSyllableBlock(
        blockId: '${entry.id}_t$i',
        text: entry.syllables[i],
        targetSequenceIndex: i,
        spawnWave: spawnWave,
        xFactor: lanes[i],
        startY: SyllableBuilderLayout.startY(
          stackIndex: spawnWave,
          randomOffset: _random.nextDouble(),
        ),
        driftSpeed: 1.4 + _random.nextDouble() * 1.2,
        xPhase: _random.nextDouble() * pi * 2,
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

  List<String> _pickDistractorSyllables({
    required DictionaryEntry entry,
    required int count,
    required int trainerLevelId,
  }) {
    final targetSet = entry.syllables.toSet();
    final pool = _dictionary
        .entriesForLevel(_dictionaryLevelId)
        .where((e) => SyllableBuilderLevel.isEligibleEntry(e, trainerLevelId))
        .expand((e) => e.syllables)
        .where(
          (s) =>
              SyllableBuilderLevel.isDistractorSyllableAllowed(
                s,
                trainerLevelId,
              ) &&
              !targetSet.contains(s),
        )
        .toSet()
        .toList();

    if (pool.isEmpty) {
      final fallback = ['БУ', 'КУ', 'ЛЯ', 'НЯ', 'РА', 'ТИ', 'СО', 'ДА', 'МА'];
      pool.addAll(
        fallback.where(
          (s) =>
              SyllableBuilderLevel.isDistractorSyllableAllowed(
                s,
                trainerLevelId,
              ) &&
              !targetSet.contains(s),
        ),
      );
    }

    pool.shuffle(_random);
    return List.generate(count, (i) => pool[i % pool.length]);
  }
}
