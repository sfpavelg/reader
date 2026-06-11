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

/// Питомец-читатель: лёгкая тамагочи без тяжёлой анимации.
class PetState {
  const PetState({
    this.stage = PetStage.egg,
    this.xp = 0,
    this.trainingMinutesFed = 0,
    this.lastFedAtMs,
  });

  static const xpPerTrainingMinute = 10;
  static const xpBaby = 50;
  static const xpTeen = 150;
  static const xpHero = 300;

  final PetStage stage;
  final int xp;
  final int trainingMinutesFed;
  final int? lastFedAtMs;

  PetStage stageForXp(int value) {
    if (value >= xpHero) return PetStage.hero;
    if (value >= xpTeen) return PetStage.teen;
    if (value >= xpBaby) return PetStage.baby;
    return PetStage.egg;
  }

  PetState feedTrainingMinute() {
    final nextXp = xp + xpPerTrainingMinute;
    return PetState(
      stage: stageForXp(nextXp),
      xp: nextXp,
      trainingMinutesFed: trainingMinutesFed + 1,
      lastFedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory PetState.fromMap(Map<dynamic, dynamic> map) {
    return PetState(
      stage: petStageFromString(map['stage'] as String? ?? 'egg'),
      xp: map['xp'] as int? ?? 0,
      trainingMinutesFed: map['trainingMinutesFed'] as int? ?? 0,
      lastFedAtMs: map['lastFedAtMs'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'stage': petStageToString(stage),
        'xp': xp,
        'trainingMinutesFed': trainingMinutesFed,
        if (lastFedAtMs != null) 'lastFedAtMs': lastFedAtMs,
      };
}
