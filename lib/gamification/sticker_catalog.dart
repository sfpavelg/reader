class StickerDef {
  const StickerDef({
    required this.id,
    required this.label,
    required this.emoji,
    required this.starCost,
  });

  final String id;
  final String label;
  final String emoji;
  final int starCost;
}

class StickerTheme {
  const StickerTheme({
    required this.id,
    required this.title,
    required this.stickers,
  });

  final String id;
  final String title;
  final List<StickerDef> stickers;
}

abstract final class StickerCatalog {
  static const themes = <StickerTheme>[
    StickerTheme(
      id: 'dinosaurs',
      title: 'Динозавры',
      stickers: [
        StickerDef(id: 'd1', label: 'Тирекс', emoji: '🦖', starCost: 1),
        StickerDef(id: 'd2', label: 'Диплодок', emoji: '🦕', starCost: 1),
        StickerDef(id: 'd3', label: 'Яйцо', emoji: '🥚', starCost: 2),
        StickerDef(id: 'd4', label: 'Отпечаток', emoji: '🦴', starCost: 2),
        StickerDef(id: 'd5', label: 'Вулкан', emoji: '🌋', starCost: 3),
        StickerDef(id: 'd6', label: 'Костёр', emoji: '🔥', starCost: 3),
      ],
    ),
    StickerTheme(
      id: 'space',
      title: 'Космос',
      stickers: [
        StickerDef(id: 's1', label: 'Ракета', emoji: '🚀', starCost: 1),
        StickerDef(id: 's2', label: 'Луна', emoji: '🌙', starCost: 1),
        StickerDef(id: 's3', label: 'Звезда', emoji: '⭐', starCost: 2),
        StickerDef(id: 's4', label: 'Планета', emoji: '🪐', starCost: 2),
        StickerDef(id: 's5', label: 'Комета', emoji: '☄️', starCost: 3),
        StickerDef(id: 's6', label: 'Астронавт', emoji: '👨‍🚀', starCost: 3),
      ],
    ),
    StickerTheme(
      id: 'cars',
      title: 'Машинки',
      stickers: [
        StickerDef(id: 'c1', label: 'Машина', emoji: '🚗', starCost: 1),
        StickerDef(id: 'c2', label: 'Автобус', emoji: '🚌', starCost: 1),
        StickerDef(id: 'c3', label: 'Грузовик', emoji: '🚚', starCost: 2),
        StickerDef(id: 'c4', label: 'Поезд', emoji: '🚂', starCost: 2),
        StickerDef(id: 'c5', label: 'Светофор', emoji: '🚦', starCost: 3),
        StickerDef(id: 'c6', label: 'Мост', emoji: '🌉', starCost: 3),
      ],
    ),
  ];
}
