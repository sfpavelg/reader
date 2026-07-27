import 'package:flutter/material.dart';

import '../kolobok/kolobok_stage.dart';

/// Идентификатор питомца.
enum PetId {
  kotenok,
  poprygunchik,
  pyatochok,
  sova,
  oslik,
}

PetId petIdFromString(String raw) {
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
  static const pets = <PetDef>[
    PetDef(
      id: PetId.kotenok,
      name: 'Котёнок',
      emoji: '🐱',
      color: Color(0xFFFFC1E3),
      hasStageImages: true,
    ),
    PetDef(
      id: PetId.poprygunchik,
      name: 'Попрыгунчик',
      emoji: '🟠',
      color: Color(0xFFFFB15A),
    ),
    PetDef(
      id: PetId.pyatochok,
      name: 'Пяточек',
      emoji: '🐷',
      color: Color(0xFFFF8FAB),
    ),
    PetDef(
      id: PetId.sova,
      name: 'Сова',
      emoji: '🦉',
      color: Color(0xFFBCAAA4),
    ),
    PetDef(
      id: PetId.oslik,
      name: 'Ослик',
      emoji: '🫏',
      color: Color(0xFF90A4AE),
    ),
  ];

  static PetDef byId(PetId id) =>
      pets.firstWhere((p) => p.id == id, orElse: () => pets.first);

  static PetDef byIdName(String name) => byId(petIdFromString(name));

  /// Общие названия этапов роста (1…6).
  static KolobokStage stageForLevel(int level) {
    final clamped = level.clamp(1, 6);
    return KolobokStage.values.firstWhere((s) => s.level == clamped);
  }

  /// PNG этапа для питомцев с картинками; иначе `null`.
  static String? stageImageAsset(PetId id, int level) {
    if (id != PetId.kotenok) return null;
    final n = level.clamp(1, 6).toString().padLeft(2, '0');
    return 'assets/characters/kotenok/stage_$n.png';
  }
}
