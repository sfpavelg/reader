/// Идентификаторы разделов главной (для родительской блокировки).
abstract final class SectionIds {
  static const reading = 'reading';
  static const math = 'math';
  static const pet = 'pet';
  static const fairytales = 'fairytales';
  static const stickers = 'stickers';
  static const coloring = 'coloring';
  static const music = 'music';
  static const toys = 'toys';

  static const all = <String>[
    reading,
    math,
    pet,
    fairytales,
    stickers,
    coloring,
    music,
    toys,
  ];

  static String title(String id) => switch (id) {
        reading => 'Читайка',
        math => 'Считайка',
        pet => 'Питомец',
        fairytales => 'Сказки',
        stickers => 'Наклейки',
        coloring => 'Краски',
        music => 'Музыка',
        toys => 'Игрушки',
        _ => id,
      };
}
