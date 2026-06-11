import 'dictionary_entry.dart';

enum DictionaryEntryType { syllable, word, sentence }

DictionaryEntryType dictionaryEntryTypeFromString(String raw) {
  switch (raw) {
    case 'syllable':
      return DictionaryEntryType.syllable;
    case 'word':
      return DictionaryEntryType.word;
    case 'sentence':
      return DictionaryEntryType.sentence;
    default:
      throw ArgumentError('Unknown dictionary type: $raw');
  }
}

/// Слой словаря по уровню сложности / миру.
class DictionaryLevel {
  const DictionaryLevel({
    required this.level,
    required this.type,
    required this.title,
    required this.entries,
  });

  final int level;
  final DictionaryEntryType type;
  final String title;
  final List<DictionaryEntry> entries;

  factory DictionaryLevel.fromJson(Map<String, dynamic> json) {
    return DictionaryLevel(
      level: json['level'] as int,
      type: dictionaryEntryTypeFromString(json['type'] as String),
      title: json['title'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
