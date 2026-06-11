class StickerAlbumState {
  const StickerAlbumState({
    this.unlockedByTheme = const {},
    this.totalStarsSpent = 0,
  });

  /// themeId -> список id наклеек
  final Map<String, List<String>> unlockedByTheme;
  final int totalStarsSpent;

  bool isUnlocked(String themeId, String stickerId) {
    return unlockedByTheme[themeId]?.contains(stickerId) ?? false;
  }

  StickerAlbumState unlock({
    required String themeId,
    required String stickerId,
    required int starCost,
  }) {
    final current = List<String>.from(unlockedByTheme[themeId] ?? const []);
    if (current.contains(stickerId)) return this;
    current.add(stickerId);
    return StickerAlbumState(
      unlockedByTheme: {...unlockedByTheme, themeId: current},
      totalStarsSpent: totalStarsSpent + starCost,
    );
  }

  factory StickerAlbumState.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['unlockedByTheme'] as Map<dynamic, dynamic>? ?? {};
    final themes = <String, List<String>>{};
    raw.forEach((key, value) {
      themes[key.toString()] =
          (value as List<dynamic>).map((e) => e.toString()).toList();
    });
    return StickerAlbumState(
      unlockedByTheme: themes,
      totalStarsSpent: map['totalStarsSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'unlockedByTheme': unlockedByTheme,
        'totalStarsSpent': totalStarsSpent,
      };
}
