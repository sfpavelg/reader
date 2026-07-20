/// Прогресс раскрасок: открытые листы, заливки сегментов и PNG картинок.
class ColoringProgress {
  const ColoringProgress({
    this.unlockedPageIds = const {},
    this.fillsByPage = const {},
    this.paintedPngByPage = const {},
  });

  final Set<String> unlockedPageIds;

  /// pageId → (segmentId → ARGB)
  final Map<String, Map<String, int>> fillsByPage;

  /// pageId → base64 PNG (для flood-fill картинок).
  final Map<String, String> paintedPngByPage;

  bool isUnlocked(String pageId) => unlockedPageIds.contains(pageId);

  Map<String, int> fillsFor(String pageId) =>
      Map<String, int>.from(fillsByPage[pageId] ?? const {});

  String? paintedPngFor(String pageId) => paintedPngByPage[pageId];

  ColoringProgress unlock(String pageId) {
    if (unlockedPageIds.contains(pageId)) return this;
    return ColoringProgress(
      unlockedPageIds: {...unlockedPageIds, pageId},
      fillsByPage: fillsByPage,
      paintedPngByPage: paintedPngByPage,
    );
  }

  ColoringProgress paintSegment({
    required String pageId,
    required String segmentId,
    required int argb,
  }) {
    final pageFills = Map<String, int>.from(fillsByPage[pageId] ?? const {});
    pageFills[segmentId] = argb;
    return ColoringProgress(
      unlockedPageIds: unlockedPageIds,
      fillsByPage: {
        ...fillsByPage,
        pageId: pageFills,
      },
      paintedPngByPage: paintedPngByPage,
    );
  }

  ColoringProgress savePaintedPng({
    required String pageId,
    required String base64Png,
  }) {
    return ColoringProgress(
      unlockedPageIds: unlockedPageIds,
      fillsByPage: fillsByPage,
      paintedPngByPage: {
        ...paintedPngByPage,
        pageId: base64Png,
      },
    );
  }

  factory ColoringProgress.fromMap(Map<dynamic, dynamic> map) {
    final unlocked = <String>{};
    final rawUnlocked = map['unlockedPageIds'];
    if (rawUnlocked is List) {
      for (final id in rawUnlocked) {
        unlocked.add('$id');
      }
    }

    final fills = <String, Map<String, int>>{};
    final rawFills = map['fillsByPage'];
    if (rawFills is Map) {
      for (final e in rawFills.entries) {
        final pageId = '${e.key}';
        final segments = <String, int>{};
        if (e.value is Map) {
          for (final s in (e.value as Map).entries) {
            segments['${s.key}'] = s.value as int? ?? 0;
          }
        }
        fills[pageId] = segments;
      }
    }

    final pngs = <String, String>{};
    final rawPngs = map['paintedPngByPage'];
    if (rawPngs is Map) {
      for (final e in rawPngs.entries) {
        pngs['${e.key}'] = '${e.value}';
      }
    }

    return ColoringProgress(
      unlockedPageIds: unlocked,
      fillsByPage: fills,
      paintedPngByPage: pngs,
    );
  }

  Map<String, dynamic> toMap() => {
        'unlockedPageIds': unlockedPageIds.toList(),
        'fillsByPage': {
          for (final e in fillsByPage.entries) e.key: e.value,
        },
        'paintedPngByPage': paintedPngByPage,
      };
}
