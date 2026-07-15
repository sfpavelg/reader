import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/models/app_settings.dart';

void main() {
  test('parent password verification is case-insensitive', () {
    const settings = AppSettings(
      parentPasswordPrimary: 'mama1234',
      parentPasswordBackup: 'papa5678',
      parentRecoveryQuestion: 'Какая река течёт в Москве?',
      parentRecoveryAnswer: 'москва',
    );

    expect(settings.verifyParentPassword('Mama1234'), isTrue);
    expect(settings.verifyParentBackupPassword('PAPA5678'), isTrue);
    expect(settings.verifyParentRecoveryAnswer('  Москва '), isTrue);
    expect(settings.verifyParentPassword('wrong'), isFalse);
  });

  test('hasParentPassword requires primary password', () {
    expect(const AppSettings().hasParentPassword, isFalse);
    expect(
      const AppSettings(parentPasswordPrimary: 'abcd').hasParentPassword,
      isTrue,
    );
  });
}
