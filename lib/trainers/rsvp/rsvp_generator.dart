import 'dart:math' as math;
import 'dart:math' show Random;

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import '../schulte/schulte_spellable_words.dart';
import '../schulte/schulte_word_picker.dart';
import 'rsvp_session_store.dart';
import 'rsvp_task.dart';

class RsvpGenerator {
  RsvpGenerator({
    required DictionaryService dictionary,
    Random? random,
    this.streamLength = 14,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _picker = SchulteWordPicker(
          dictionary: dictionary,
          random: random,
          maxSyllables: 9,
          loadRecentEntryIds: RsvpSessionStore.loadRecentEntryIds,
          loadLastEntryId: RsvpSessionStore.loadLastEntryId,
        );

  final DictionaryService _dictionary;
  final Random _random;
  final SchulteWordPicker _picker;
  final int streamLength;

  SchulteWordPicker get wordPicker => _picker;

  RsvpTask generate() => fromEntry(_picker.pickNext());

  RsvpTask fromEntry(DictionaryEntry entry) {
    if (!SchulteWordPicker.isEligibleEntry(entry, maxSyllables: 9)) {
      throw ArgumentError('Entry ${entry.id} is not eligible for RSVP');
    }

    final streamSyllables = _buildStreamSyllables(entry.syllables);
    final spellableWords = SchulteSpellableWords.findForGrid(
      dictionary: _dictionary,
      gridSyllables: streamSyllables,
    );

    return RsvpTask(
      taskId: 'rsvp_${DateTime.now().microsecondsSinceEpoch}',
      entryId: entry.id,
      word: entry.text,
      syllables: List<String>.from(entry.syllables),
      streamSyllables: streamSyllables,
      spellableWords: spellableWords,
    );
  }

  List<String> _buildStreamSyllables(List<String> targetSyllables) {
    final required = List<String>.from(targetSyllables);
    final distractors = _dictionary
        .entriesForLevel(1)
        .map((e) => e.text)
        .where((t) => t.length == 2)
        .toList();

    final extras = <String>[];
    final targetLength = math.max(streamLength, required.length);
    while (required.length + extras.length < targetLength &&
        distractors.isNotEmpty) {
      extras.add(distractors[_random.nextInt(distractors.length)]);
    }

    final pool = [...required, ...extras]..shuffle(_random);
    assert(
      SchulteSpellableWords.canSpell(pool, targetSyllables),
      'Stream must contain every hint syllable',
    );
    return pool;
  }
}
