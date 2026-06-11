import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/models/pet_state.dart';
import 'package:reader/data/hive/models/trainer_progress.dart';

void main() {
  test('pet evolves through sprite stages by xp', () {
    var pet = const PetState();
    for (var i = 0; i < 5; i++) {
      pet = pet.feedTrainingMinute();
    }
    expect(pet.xp, 50);
    expect(pet.stage, PetStage.baby);
  });

  test('tachistoscope progress roundtrips through map', () {
    const original = TachistoscopeTrainerProgress(
      flashDurationMs: 1600,
      correctStreak: 2,
      tasksCompleted: 7,
      correctAnswers: 5,
      recentTargetIds: ['s_ma', 's_pa'],
    );

    final restored =
        TachistoscopeTrainerProgress.fromMap(original.toMap());

    expect(restored.flashDurationMs, 1600);
    expect(restored.recentTargetIds, ['s_ma', 's_pa']);
  });
}
