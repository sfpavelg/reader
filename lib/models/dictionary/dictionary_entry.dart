/// Одна единица словаря: слог, слово или короткая фраза.
class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.text,
    required this.difficulty,
    this.tags = const [],
    this.imageAsset,
    this.syllables = const [],
  });

  final String id;
  final String text;
  final int difficulty;
  final List<String> tags;
  final String? imageAsset;
  final List<String> syllables;

  bool get hasSyllableBreakdown => syllables.length >= 2;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      id: json['id'] as String,
      text: (json['text'] as String).trim().toUpperCase(),
      difficulty: json['difficulty'] as int? ?? 1,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageAsset: json['imageAsset'] as String?,
      syllables: (json['syllables'] as List<dynamic>?)
              ?.map((e) => e.toString().trim().toUpperCase())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'difficulty': difficulty,
        'tags': tags,
        if (imageAsset != null) 'imageAsset': imageAsset,
        if (syllables.isNotEmpty) 'syllables': syllables,
      };
}
