/// Каталог аудиосказок (народные / общественное достояние).
class FairytaleChapter {
  const FairytaleChapter({
    required this.id,
    required this.title,
    required this.synopsis,
    this.audioAsset,
    this.duration,
  });

  final String id;
  final String title;
  final String synopsis;

  /// Путь для [AssetSource] без префикса `assets/`.
  final String? audioAsset;

  /// Длительность для ползунка перемотки (если плеер ещё не отдал метаданные).
  final Duration? duration;
}

class Fairytale {
  const Fairytale({
    required this.id,
    required this.title,
    required this.author,
    required this.emoji,
    required this.blurb,
    required this.chapters,
  });

  final String id;
  final String title;
  final String author;
  final String emoji;
  final String blurb;
  final List<FairytaleChapter> chapters;

  static const chapterStarCost = 20;
}

abstract final class FairytaleCatalog {
  static const tales = <Fairytale>[
    Fairytale(
      id: 'havroshechka',
      title: 'Крошечка-Хаврошечка',
      author: 'Русская народная',
      emoji: '🐄',
      blurb: 'Добрая девочка, волшебная корова и завистливые сёстры.',
      chapters: [
        FairytaleChapter(
          id: 'havroshechka_1',
          title: 'Слушать сказку',
          synopsis: 'Полная озвучка русской народной сказки.',
          audioAsset: 'audio/fairytales/havroshechka/havroshechka.ogg',
          duration: Duration(minutes: 6, seconds: 21),
        ),
      ],
    ),
  ];

  static Fairytale? byId(String id) {
    for (final tale in tales) {
      if (tale.id == id) return tale;
    }
    return null;
  }
}
