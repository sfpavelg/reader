import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/local_storage.dart';
import 'package:reader/gamification/trainer_attempts_reset.dart';
import 'package:reader/gamification/trainer_stencil_progress.dart';

void main() {
  test('resetAll clears attempts in stored trainer progress', () async {
    final testPath =
        'trainer_attempts_reset_${DateTime.now().microsecondsSinceEpoch}';
    await LocalStorage.initialize(testPath: testPath);

    await LocalStorage.writeTrainerExtra('schulte_shared', {
      'dateKey': '2026-01-01',
      'dailyAttemptLimit': 20,
      'attemptsUsed': 18,
      'stencilFilled': 2,
    });
    await LocalStorage.writeTrainerExtra('rsvp_shared', {
      'dateKey': TrainerStencilProgressStore.todayKey(),
      'dailyAttemptLimit': 20,
      'attemptsByLevel': {'1': 20, '2': 7},
      'stencilFilledByLevel': {'1': 1},
    });
    await LocalStorage.writeTrainerExtra('math_counting_shared', {
      'dateKey': TrainerStencilProgressStore.todayKey(),
      'dailyAttemptLimit': 20,
      'attemptsUsed': 20,
      'stencilFilled': 1,
    });

    await TrainerAttemptsReset.resetAll();

    final schulte = TrainerStencilProgress.fromMap(
      LocalStorage.readTrainerExtra('schulte_shared')!,
    );
    final rsvp = TrainerStencilProgress.fromMap(
      LocalStorage.readTrainerExtra('rsvp_shared')!,
    );
    final mathCounting = TrainerStencilProgress.fromMap(
      LocalStorage.readTrainerExtra('math_counting_shared')!,
    );

    expect(schulte.attemptsUsed, 0);
    expect(schulte.stencilFilled, 2);
    expect(rsvp.attemptsByLevel, isEmpty);
    expect(rsvp.stencilFilledByLevel, {'1': 1});
    expect(rsvp.hasAttemptsLeftForLevel(1), isTrue);
    expect(mathCounting.attemptsUsed, 0);
    expect(mathCounting.stencilFilled, 1);
    expect(mathCounting.hasAttemptsLeft, isTrue);
  });
}
