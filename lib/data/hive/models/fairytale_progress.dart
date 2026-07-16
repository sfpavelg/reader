/// Какие главы сказок уже открыты за звёзды.
class FairytaleProgress {
  const FairytaleProgress({
    this.unlockedChapterIds = const {},
    this.totalStarsSpent = 0,
  });

  final Set<String> unlockedChapterIds;
  final int totalStarsSpent;

  bool isChapterUnlocked(String chapterId) =>
      unlockedChapterIds.contains(chapterId);

  FairytaleProgress unlockChapter({
    required String chapterId,
    required int starCost,
  }) {
    if (unlockedChapterIds.contains(chapterId)) return this;
    return FairytaleProgress(
      unlockedChapterIds: {...unlockedChapterIds, chapterId},
      totalStarsSpent: totalStarsSpent + starCost,
    );
  }

  factory FairytaleProgress.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['unlockedChapterIds'];
    final ids = <String>{};
    if (raw is List) {
      for (final item in raw) {
        ids.add(item.toString());
      }
    }
    return FairytaleProgress(
      unlockedChapterIds: ids,
      totalStarsSpent: map['totalStarsSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'unlockedChapterIds': unlockedChapterIds.toList(),
        'totalStarsSpent': totalStarsSpent,
      };
}
