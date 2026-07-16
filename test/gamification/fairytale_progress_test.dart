import 'package:flutter_test/flutter_test.dart';
import 'package:reader/content/fairytale_catalog.dart';
import 'package:reader/data/hive/local_storage.dart';
import 'package:reader/data/hive/models/fairytale_progress.dart';
import 'package:reader/gamification/rewards_service.dart';
import 'package:reader/data/hive/models/user_profile.dart';

void main() {
  test('catalog has seven long fairytales', () {
    expect(FairytaleCatalog.tales.length, 7);
    expect(
      FairytaleCatalog.tales.map((t) => t.title),
      containsAll([
        'Волшебник изумрудного города',
        'Гензель и Гретель',
      ]),
    );
    for (final tale in FairytaleCatalog.tales) {
      expect(tale.chapters.length, greaterThanOrEqualTo(4));
    }
  });

  test('unlockFairytaleChapter spends stars', () async {
    final path = 'fairytale_progress_${DateTime.now().microsecondsSinceEpoch}';
    await LocalStorage.initialize(testPath: path);
    await LocalStorage.writeProfile(
      UserProfile.defaults().copyWith(totalStars: 50),
    );

    final chapterId = FairytaleCatalog.tales.first.chapters.first.id;
    final ok = await RewardsService.unlockFairytaleChapter(
      chapterId: chapterId,
      starCost: Fairytale.chapterStarCost,
    );
    expect(ok, isTrue);
    expect(RewardsService.availableStars(), 30);

    final progress = LocalStorage.readFairytaleProgress();
    expect(progress.isChapterUnlocked(chapterId), isTrue);
    expect(progress.totalStarsSpent, Fairytale.chapterStarCost);
  });

  test('FairytaleProgress roundtrip', () {
    const original = FairytaleProgress(
      unlockedChapterIds: {'oz_1', 'oz_2'},
      totalStarsSpent: 40,
    );
    final restored = FairytaleProgress.fromMap(original.toMap());
    expect(restored.unlockedChapterIds, {'oz_1', 'oz_2'});
    expect(restored.totalStarsSpent, 40);
  });
}
