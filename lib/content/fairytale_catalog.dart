/// Каталог аудиосказок (дорожки добавим позже).
class FairytaleChapter {
  const FairytaleChapter({
    required this.id,
    required this.title,
    required this.synopsis,
  });

  final String id;
  final String title;
  final String synopsis;
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
      id: 'oz',
      title: 'Волшебник изумрудного города',
      author: 'А. Волков',
      emoji: '🪄',
      blurb: 'Дорога из жёлтого кирпича, друзья и волшебный город.',
      chapters: [
        FairytaleChapter(
          id: 'oz_1',
          title: 'Ураган',
          synopsis: 'Домик Элли уносит в волшебную страну.',
        ),
        FairytaleChapter(
          id: 'oz_2',
          title: 'Железный Дровосек',
          synopsis: 'Элли встречает друга, которому нужно сердце.',
        ),
        FairytaleChapter(
          id: 'oz_3',
          title: 'Трусливый Лев',
          synopsis: 'К компании присоединяется Лев без храбрости.',
        ),
        FairytaleChapter(
          id: 'oz_4',
          title: 'Изумрудный город',
          synopsis: 'Друзья входят в сверкающий город волшебника.',
        ),
        FairytaleChapter(
          id: 'oz_5',
          title: 'Дорога домой',
          synopsis: 'Исполняются желания — и начинается путь обратно.',
        ),
      ],
    ),
    Fairytale(
      id: 'hansel',
      title: 'Гензель и Гретель',
      author: 'Братья Гримм',
      emoji: '🍬',
      blurb: 'Лес, пряничный домик и хитрая колдунья.',
      chapters: [
        FairytaleChapter(
          id: 'hansel_1',
          title: 'Хлебные крошки',
          synopsis: 'Дети оставляют след, чтобы найти дорогу домой.',
        ),
        FairytaleChapter(
          id: 'hansel_2',
          title: 'Пряничный домик',
          synopsis: 'Сладкий запах приводит Гензеля и Гретель к домику.',
        ),
        FairytaleChapter(
          id: 'hansel_3',
          title: 'Клетка и печь',
          synopsis: 'Колдунья готовит ловушку — но дети умнее.',
        ),
        FairytaleChapter(
          id: 'hansel_4',
          title: 'Сокровища леса',
          synopsis: 'Дети спасаются и возвращаются с чудесными дарами.',
        ),
      ],
    ),
    Fairytale(
      id: 'buratino',
      title: 'Приключения Буратино',
      author: 'А. Толстой',
      emoji: '🎭',
      blurb: 'Золотой ключик, кукольный театр и весёлые проказы.',
      chapters: [
        FairytaleChapter(
          id: 'bur_1',
          title: 'Полено оживает',
          synopsis: 'Папа Карло вырезает из полена озорного мальчишку.',
        ),
        FairytaleChapter(
          id: 'bur_2',
          title: 'Театр Карабаса',
          synopsis: 'Буратино попадает в кукольный театр.',
        ),
        FairytaleChapter(
          id: 'bur_3',
          title: 'Поле чудес',
          synopsis: 'Лиса и кот заманивают его на площадь чудес.',
        ),
        FairytaleChapter(
          id: 'bur_4',
          title: 'Золотой ключик',
          synopsis: 'Друзья находят тайную дверцу и чудесный ключ.',
        ),
        FairytaleChapter(
          id: 'bur_5',
          title: 'Новый театр',
          synopsis: 'Все вместе открывают свой добрый театр.',
        ),
      ],
    ),
    Fairytale(
      id: 'alice',
      title: 'Алиса в Стране чудес',
      author: 'Л. Кэрролл',
      emoji: '🐇',
      blurb: 'Кроличья нора, чаепитие и королева червей.',
      chapters: [
        FairytaleChapter(
          id: 'alice_1',
          title: 'Вниз по норе',
          synopsis: 'Алиса следует за Белым Кроликом.',
        ),
        FairytaleChapter(
          id: 'alice_2',
          title: 'Выпей меня',
          synopsis: 'Зелья меняют рост — и открывают новые двери.',
        ),
        FairytaleChapter(
          id: 'alice_3',
          title: 'Безумное чаепитие',
          synopsis: 'Шляпник, Заяц и Соня за странным столом.',
        ),
        FairytaleChapter(
          id: 'alice_4',
          title: 'Крокет с королевой',
          synopsis: 'Игра, где правила меняются каждую минуту.',
        ),
        FairytaleChapter(
          id: 'alice_5',
          title: 'Суд и пробуждение',
          synopsis: 'Алиса смело спорит с королевой и просыпается.',
        ),
      ],
    ),
    Fairytale(
      id: 'mowgli',
      title: 'Маугли',
      author: 'Р. Киплинг',
      emoji: '🐯',
      blurb: 'Джунгли, волчья семья и закон джунглей.',
      chapters: [
        FairytaleChapter(
          id: 'mow_1',
          title: 'Волчий выводок',
          synopsis: 'Маленького мальчика принимают в волчью семью.',
        ),
        FairytaleChapter(
          id: 'mow_2',
          title: 'Багира и Балу',
          synopsis: 'Пантера и медведь учат Маугли закону джунглей.',
        ),
        FairytaleChapter(
          id: 'mow_3',
          title: 'Шер-Хан',
          synopsis: 'Тигр угрожает, и друзья готовят защиту.',
        ),
        FairytaleChapter(
          id: 'mow_4',
          title: 'Красный цветок',
          synopsis: 'Огонь помогает Маугли победить страх.',
        ),
        FairytaleChapter(
          id: 'mow_5',
          title: 'Песня джунглей',
          synopsis: 'Маугли находит своё место между мирами.',
        ),
      ],
    ),
    Fairytale(
      id: 'snow_queen',
      title: 'Снежная королева',
      author: 'Г. Х. Андерсен',
      emoji: '❄️',
      blurb: 'Ледяное зеркало, верная дружба и тёплое сердце.',
      chapters: [
        FairytaleChapter(
          id: 'sq_1',
          title: 'Осколок зеркала',
          synopsis: 'Кай становится холодным и странным.',
        ),
        FairytaleChapter(
          id: 'sq_2',
          title: 'Путь Герды',
          synopsis: 'Герда отправляется на поиски друга.',
        ),
        FairytaleChapter(
          id: 'sq_3',
          title: 'Дворец роз',
          synopsis: 'Волшебный сад почти заставляет забыть цель.',
        ),
        FairytaleChapter(
          id: 'sq_4',
          title: 'Ледяной дворец',
          synopsis: 'Герда находит Кая во дворце Королевы.',
        ),
        FairytaleChapter(
          id: 'sq_5',
          title: 'Тёплые слёзы',
          synopsis: 'Любовь растапливает лёд в сердце Кая.',
        ),
      ],
    ),
    Fairytale(
      id: 'mermaid',
      title: 'Русалочка',
      author: 'Г. Х. Андерсен',
      emoji: '🧜',
      blurb: 'Подводное царство, мечта о земле и смелый выбор.',
      chapters: [
        FairytaleChapter(
          id: 'mer_1',
          title: 'Пять сестёр',
          synopsis: 'Младшая русалочка мечтает увидеть верхний мир.',
        ),
        FairytaleChapter(
          id: 'mer_2',
          title: 'Буря и принц',
          synopsis: 'Она спасает принца во время шторма.',
        ),
        FairytaleChapter(
          id: 'mer_3',
          title: 'Сделка с ведьмой',
          synopsis: 'Голос меняют на ноги — цена очень высока.',
        ),
        FairytaleChapter(
          id: 'mer_4',
          title: 'Танец на берегу',
          synopsis: 'Русалочка учится ходить и молча говорить сердцем.',
        ),
        FairytaleChapter(
          id: 'mer_5',
          title: 'Рассвет',
          synopsis: 'Финал о выборе, смелости и настоящей любви.',
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
