import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/tachistoscope/tachistoscope_shared_store.dart';

void main() {
  test('shared state roundtrips through map', () {
    const original = TachistoscopeSharedState(
      dateKey: '2026-06-30',
      attemptsUsed: 7,
      stencilFilled: 3,
    );

    final restored = TachistoscopeSharedState.fromMap(original.toMap());

    expect(restored.dateKey, '2026-06-30');
    expect(restored.attemptsUsed, 7);
    expect(restored.stencilFilled, 3);
    expect(restored.attemptsRemaining, 13);
    expect(restored.hasAttemptsLeft, isTrue);
  });

  test('registerAttempt stops at daily limit', () {
    const state = TachistoscopeSharedState(
      dateKey: '2026-06-30',
      attemptsUsed: 19,
    );

    final next = state.registerAttempt();

    expect(next.attemptsUsed, 20);
    expect(next.hasAttemptsLeft, isFalse);
  });
}
