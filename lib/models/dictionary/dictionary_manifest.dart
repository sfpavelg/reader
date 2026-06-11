import 'dictionary_level.dart';

class DictionaryLevelRef {
  const DictionaryLevelRef({
    required this.id,
    required this.file,
    required this.title,
    required this.worldId,
    required this.entryType,
  });

  final int id;
  final String file;
  final String title;
  final String worldId;
  final DictionaryEntryType entryType;

  factory DictionaryLevelRef.fromJson(Map<String, dynamic> json) {
    return DictionaryLevelRef(
      id: json['id'] as int,
      file: json['file'] as String,
      title: json['title'] as String,
      worldId: json['worldId'] as String,
      entryType: dictionaryEntryTypeFromString(json['entryType'] as String),
    );
  }
}

class DictionaryManifest {
  const DictionaryManifest({
    required this.version,
    required this.locale,
    required this.levels,
  });

  final int version;
  final String locale;
  final List<DictionaryLevelRef> levels;

  factory DictionaryManifest.fromJson(Map<String, dynamic> json) {
    return DictionaryManifest(
      version: json['version'] as int,
      locale: json['locale'] as String,
      levels: (json['levels'] as List<dynamic>)
          .map((e) => DictionaryLevelRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
