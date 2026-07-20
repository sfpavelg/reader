enum PetStage { egg, baby, teen, hero }

PetStage petStageFromString(String raw) {
  switch (raw) {
    case 'egg':
      return PetStage.egg;
    case 'baby':
      return PetStage.baby;
    case 'teen':
      return PetStage.teen;
    case 'hero':
      return PetStage.hero;
    default:
      return PetStage.egg;
  }
}

String petStageToString(PetStage stage) => stage.name;

/// Состояние питомцев: активный + уровень каждого (за звёзды).
class PetState {
  const PetState({
    this.activePetId = 'poprygunchik',
    this.unlockedByPet = const {'poprygunchik': 1},
    // Устаревшие поля — миграция.
    this.unlockedLevel = 1,
    this.stage = PetStage.egg,
    this.xp = 0,
    this.trainingMinutesFed = 0,
    this.lastFedAtMs,
  });

  static const starCostPerLevel = 20;
  static const maxLevel = 6;
  static const knownPetIds = [
    'poprygunchik',
    'pyatochok',
    'sova',
    'oslik',
  ];

  final String activePetId;
  final Map<String, int> unlockedByPet;

  final int unlockedLevel;
  final PetStage stage;
  final int xp;
  final int trainingMinutesFed;
  final int? lastFedAtMs;

  int levelForId(String id) =>
      (unlockedByPet[id] ?? 1).clamp(1, maxLevel);

  int get displayLevel => levelForId(activePetId);

  bool canUnlockNextForId(String id) => levelForId(id) < maxLevel;

  bool get canUnlockNext => canUnlockNextForId(activePetId);

  PetState selectPetId(String id) {
    final map = Map<String, int>.from(unlockedByPet);
    map.putIfAbsent(id, () => 1);
    return PetState(
      activePetId: id,
      unlockedByPet: map,
      unlockedLevel: map[id] ?? 1,
      stage: stage,
      xp: xp,
      trainingMinutesFed: trainingMinutesFed,
      lastFedAtMs: lastFedAtMs,
    );
  }

  PetState unlockNextLevel({String? petId}) {
    final id = petId ?? activePetId;
    if (!canUnlockNextForId(id)) return this;
    final map = Map<String, int>.from(unlockedByPet);
    map[id] = levelForId(id) + 1;
    return PetState(
      activePetId: activePetId,
      unlockedByPet: map,
      unlockedLevel: map[activePetId] ?? 1,
      stage: stage,
      xp: xp,
      trainingMinutesFed: trainingMinutesFed + 1,
      lastFedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  PetState feedTrainingMinute() => this;

  factory PetState.fromMap(Map<dynamic, dynamic> map) {
    final rawLevels = map['unlockedByPet'];
    final levels = <String, int>{};
    if (rawLevels is Map) {
      for (final e in rawLevels.entries) {
        levels['${e.key}'] = (e.value as int? ?? 1).clamp(1, maxLevel);
      }
    }

    final legacyLevel = (map['unlockedLevel'] as int? ?? 1).clamp(1, maxLevel);
    if (levels.isEmpty) {
      levels['poprygunchik'] = legacyLevel;
    }
    for (final id in knownPetIds) {
      levels.putIfAbsent(id, () => 1);
    }

    final active = map['activePetId'] as String? ?? 'poprygunchik';

    return PetState(
      activePetId: active,
      unlockedByPet: levels,
      unlockedLevel: levels[active] ?? legacyLevel,
      stage: petStageFromString(map['stage'] as String? ?? 'egg'),
      xp: map['xp'] as int? ?? 0,
      trainingMinutesFed: map['trainingMinutesFed'] as int? ?? 0,
      lastFedAtMs: map['lastFedAtMs'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'activePetId': activePetId,
        'unlockedByPet': unlockedByPet,
        'unlockedLevel': levelForId(activePetId),
        'stage': petStageToString(stage),
        'xp': xp,
        'trainingMinutesFed': trainingMinutesFed,
        if (lastFedAtMs != null) 'lastFedAtMs': lastFedAtMs,
      };
}
