import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/models/app_settings.dart';

void main() {
  const overnight = AppSettings(
    playTimeRestrictionEnabled: true,
    playBlockedFromMinutes: 21 * 60,
    playBlockedToMinutes: 8 * 60,
  );

  test('overnight block rejects late evening and early morning', () {
    expect(
      overnight.isPlayBlockedAt(DateTime(2026, 7, 7, 22, 0)),
      isTrue,
    );
    expect(
      overnight.isPlayBlockedAt(DateTime(2026, 7, 7, 7, 30)),
      isTrue,
    );
    expect(
      overnight.isPlayBlockedAt(DateTime(2026, 7, 7, 12, 0)),
      isFalse,
    );
  });

  test('same-day block rejects only inside the window', () {
    const nap = AppSettings(
      playTimeRestrictionEnabled: true,
      playBlockedFromMinutes: 13 * 60,
      playBlockedToMinutes: 15 * 60,
    );

    expect(nap.isPlayBlockedAt(DateTime(2026, 7, 7, 13, 30)), isTrue);
    expect(nap.isPlayBlockedAt(DateTime(2026, 7, 7, 15, 0)), isFalse);
    expect(nap.isPlayBlockedAt(DateTime(2026, 7, 7, 10, 0)), isFalse);
  });

  test('disabled restriction never blocks', () {
    expect(
      const AppSettings(playTimeRestrictionEnabled: false)
          .isPlayBlockedAt(DateTime(2026, 7, 7, 23, 0)),
      isFalse,
    );
  });
}
