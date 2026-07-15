import 'package:flutter_test/flutter_test.dart';
import 'package:reader/gamification/trainer_stencil_progress.dart';

void main() {
  test('syllable builder progress supports 40 daily attempts', () {
    const state = TrainerStencilProgress(
      dateKey: '2026-06-30',
      dailyAttemptLimit: 40,
      attemptsUsed: 12,
      stencilFilled: 2,
    );

    expect(state.attemptsRemaining, 28);
    expect(state.hasAttemptsLeft, isTrue);

    final next = state.registerAttempt();
    expect(next.attemptsUsed, 13);
  });

  test('per-level attempts are independent', () {
    const state = TrainerStencilProgress(
      dateKey: '2026-06-30',
      dailyAttemptLimit: 20,
    );

    final afterSyllables = state.registerAttemptForLevel(1);
    expect(afterSyllables.attemptsUsedForLevel(1), 1);
    expect(afterSyllables.hasAttemptsLeftForLevel(1), isTrue);
    expect(afterSyllables.hasAttemptsLeftForLevel(2), isTrue);

    var exhausted = afterSyllables;
    for (var i = 0; i < 19; i++) {
      exhausted = exhausted.registerAttemptForLevel(1);
    }
    expect(exhausted.attemptsUsedForLevel(1), 20);
    expect(exhausted.hasAttemptsLeftForLevel(1), isFalse);
    expect(exhausted.hasAttemptsLeftForLevel(2), isTrue);
  });

  test('per-level attempts roundtrip through map', () {
    final original = TrainerStencilProgress(
      dateKey: '2026-06-30',
      dailyAttemptLimit: 20,
      attemptsByLevel: const {'1': 20, '2': 5},
      stencilFilled: 3,
    );

    final restored = TrainerStencilProgress.fromMap(original.toMap());
    expect(restored.attemptsUsedForLevel(1), 20);
    expect(restored.attemptsUsedForLevel(2), 5);
    expect(restored.hasAttemptsLeftForLevel(1), isFalse);
    expect(restored.hasAttemptsLeftForLevel(2), isTrue);
    expect(restored.stencilFilled, 3);
  });

  test('resetAttempts clears counters but keeps stencil', () {
    const state = TrainerStencilProgress(
      dateKey: '2026-06-30',
      dailyAttemptLimit: 40,
      attemptsUsed: 40,
      attemptsByLevel: {'1': 20, '2': 5},
      stencilFilled: 4,
      stencilFilledByLevel: {'1': 3, '2': 1},
      freeHintUsed: true,
    );

    final reset = state.resetAttempts(dateKey: '2026-07-01');

    expect(reset.dateKey, '2026-07-01');
    expect(reset.attemptsUsed, 0);
    expect(reset.attemptsByLevel, isEmpty);
    expect(reset.freeHintUsed, isFalse);
    expect(reset.stencilFilled, 4);
    expect(reset.stencilFilledByLevel, {'1': 3, '2': 1});
    expect(reset.hasAttemptsLeft, isTrue);
  });
}
