import 'package:flutter/material.dart';

import '../kolobok/kolobok_stage.dart';

/// Идентификатор питомца.
enum PetId {
  kotenok,
  lisenok,
  ezhik,
  chernushka,
  shelkovushka,
  zolotushka,
  poprygunchik,
  pyatochok,
  sova,
  oslik,
}

PetId petIdFromString(String raw) {
  if (raw == 'kurochka') return PetId.chernushka;
  for (final id in PetId.values) {
    if (id.name == raw) return id;
  }
  return PetId.kotenok;
}

/// Карточка питомца в каталоге.
class PetDef {
  const PetDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.hasStageImages = false,
  });

  final PetId id;
  final String name;
  final String emoji;
  final Color color;

  /// Полноэкранные PNG по этапам (без кликов по частям).
  final bool hasStageImages;
}

/// Каталог питомцев.
abstract final class PetCatalog {
  /// Доступные сейчас: котёнок, лисёнок, ёжик, чернушка, шёлковушка, золотушка; остальных добавим позже.
  static const pets = <PetDef>[
    PetDef(
      id: PetId.kotenok,
      name: 'Котёнок',
      emoji: '🐱',
      color: Color(0xFFFFC1E3),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.lisenok,
      name: 'Лисёнок',
      emoji: '🦊',
      color: Color(0xFFFFCC80),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.ezhik,
      name: 'Ёжик',
      emoji: '🦔',
      color: Color(0xFFFFE082),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.chernushka,
      name: 'Чернушка',
      emoji: '🐔',
      color: Color(0xFFFFAB91),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.shelkovushka,
      name: 'Шёлковушка',
      emoji: '🦢',
      color: Color(0xFFF5F5F5),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.zolotushka,
      name: 'Золотушка',
      emoji: '🐓',
      color: Color(0xFFFFB74D),
      hasStageImages: true,
    ),
    // PetDef(
    //   id: PetId.poprygunchik,
    //   name: 'Попрыгунчик',
    //   emoji: '🟠',
    //   color: Color(0xFFFFB15A),
    // ),
    // PetDef(
    //   id: PetId.pyatochok,
    //   name: 'Пяточек',
    //   emoji: '🐷',
    //   color: Color(0xFFFF8FAB),
    // ),
    // PetDef(
    //   id: PetId.sova,
    //   name: 'Сова',
    //   emoji: '🦉',
    //   color: Color(0xFFBCAAA4),
    // ),
    // PetDef(
    //   id: PetId.oslik,
    //   name: 'Ослик',
    //   emoji: '🫏',
    //   color: Color(0xFF90A4AE),
    // ),
  ];

  static PetDef byId(PetId id) =>
      pets.firstWhere((p) => p.id == id, orElse: () => pets.first);

  static PetDef byIdName(String name) => byId(petIdFromString(name));

  /// Общие названия этапов роста (1…6).
  static KolobokStage stageForLevel(int level) {
    final clamped = level.clamp(1, 6);
    return KolobokStage.values.firstWhere((s) => s.level == clamped);
  }

  /// Подпись этапа с учётом вида питомца.
  static String stageTitle(PetId petId, KolobokStage stage) {
    if (petId == PetId.kotenok ||
        petId == PetId.lisenok ||
        petId == PetId.ezhik ||
        petId == PetId.chernushka ||
        petId == PetId.shelkovushka ||
        petId == PetId.zolotushka) {
      switch (stage) {
        case KolobokStage.young:
          return 'Юный';
        case KolobokStage.adult:
          return switch (petId) {
            PetId.lisenok => 'Лисёнок',
            PetId.ezhik => 'Ёжик',
            PetId.chernushka => 'Чернушка',
            PetId.shelkovushka => 'Шёлковушка',
            PetId.zolotushka => 'Золотушка',
            _ => 'Котёнок',
          };
        case KolobokStage.tadpole:
        case KolobokStage.sprout:
        case KolobokStage.child:
        case KolobokStage.teen:
          return stage.title;
      }
    }
    return stage.title;
  }

  /// PNG этапа для питомцев с картинками; иначе `null`.
  static String? stageImageAsset(PetId id, int level) {
    final folder = switch (id) {
      PetId.kotenok => 'kotenok',
      PetId.lisenok => 'lisenok',
      PetId.ezhik => 'ezhik',
      PetId.chernushka => 'chernushka',
      PetId.shelkovushka => 'shelkovushka',
      PetId.zolotushka => 'zolotushka',
      _ => null,
    };
    if (folder == null) return null;
    final n = level.clamp(1, 6).toString().padLeft(2, '0');
    return 'assets/characters/$folder/stage_$n.png';
  }

  /// Круглая мордашка взрослой особи (этап 6) для кнопок выбора.
  static String? adultFaceAsset(PetId id) => stageImageAsset(id, 6);
}
