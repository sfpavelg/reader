import 'dart:math' as math;
import 'dart:ui';

/// Тематика раскрасок.
class ColoringTheme {
  const ColoringTheme({
    required this.id,
    required this.title,
    required this.emoji,
  });

  final String id;
  final String title;
  final String emoji;
}

/// Сегмент картинки (заливается целиком одним тапом).
class ColoringSegment {
  const ColoringSegment({
    required this.id,
    required this.path,
  });

  final String id;
  /// Нормализованный путь в координатах 0…1.
  final Path path;
}

class ColoringPage {
  const ColoringPage({
    required this.id,
    required this.themeId,
    required this.index,
    required this.title,
    this.segments = const [],
    this.imageAsset,
  });

  final String id;
  final String themeId;
  final int index;
  final String title;
  final List<ColoringSegment> segments;

  /// Если задан — заливка flood-fill по картинке.
  final String? imageAsset;

  bool get isImagePage => imageAsset != null && imageAsset!.isNotEmpty;
}

/// Каталог раскрасок: тематики × листы, по 10 ★ за лист.
abstract final class ColoringCatalog {
  static const starCost = 10;
  static const pagesPerTheme = 10;

  static const themes = <ColoringTheme>[
    ColoringTheme(id: 'animals', title: 'Животные', emoji: '🐾'),
    ColoringTheme(id: 'cars', title: 'Машины', emoji: '🚗'),
    ColoringTheme(id: 'dolls', title: 'Куклы', emoji: '🪆'),
    ColoringTheme(id: 'planes', title: 'Самолёты', emoji: '✈️'),
    ColoringTheme(id: 'birds', title: 'Птицы', emoji: '🐦'),
    ColoringTheme(id: 'mermaids', title: 'Русалки', emoji: '🧜'),
  ];

  static ColoringTheme themeById(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => themes.first);

  /// Готовые картинки для тематики (индекс листа → asset).
  static const imagePages = <String, Map<int, String>>{
    'mermaids': {
      1: 'assets/coloring/mermaids/mermaid_01.png',
      2: 'assets/coloring/mermaids/mermaid_02.png',
      3: 'assets/coloring/mermaids/mermaid_03.png',
      4: 'assets/coloring/mermaids/mermaid_04.png',
      5: 'assets/coloring/mermaids/mermaid_05.png',
      6: 'assets/coloring/mermaids/mermaid_06.png',
      7: 'assets/coloring/mermaids/mermaid_07.png',
      8: 'assets/coloring/mermaids/mermaid_08.png',
      9: 'assets/coloring/mermaids/mermaid_09.png',
      10: 'assets/coloring/mermaids/mermaid_10.png',
    },
  };

  static const mermaidTitles = <int, String>{
    1: 'Замок и русалка',
    2: 'Принцесса с короной',
    3: 'На коралле',
    4: 'С морским коньком',
    5: 'У зеркала',
    6: 'С дельфином',
    7: 'Подружки',
    8: 'На черепахе',
    9: 'Коралловые ворота',
    10: 'Сундук сокровищ',
  };

  static List<ColoringPage> pagesForTheme(String themeId) {
    final images = imagePages[themeId] ?? const {};
    return List.generate(pagesPerTheme, (i) {
      final n = i + 1;
      final asset = images[n];
      if (asset != null) {
        final title = themeId == 'mermaids'
            ? (mermaidTitles[n] ?? 'Лист $n')
            : 'Лист $n';
        return ColoringPage(
          id: '${themeId}_$n',
          themeId: themeId,
          index: n,
          title: title,
          imageAsset: asset,
        );
      }
      return ColoringPage(
        id: '${themeId}_$n',
        themeId: themeId,
        index: n,
        title: 'Лист $n',
        segments: _buildSegments(themeId, n),
      );
    });
  }

  static ColoringPage? pageById(String pageId) {
    final parts = pageId.split('_');
    if (parts.length < 2) return null;
    final themeId = parts.sublist(0, parts.length - 1).join('_');
    final index = int.tryParse(parts.last);
    if (index == null) return null;
    final pages = pagesForTheme(themeId);
    if (index < 1 || index > pages.length) return null;
    return pages[index - 1];
  }

  static List<ColoringSegment> _buildSegments(String themeId, int index) {
    final seed = themeId.hashCode ^ (index * 9973);
    final rnd = math.Random(seed);
    return switch (themeId) {
      'cars' => _car(rnd, index),
      'dolls' => _doll(rnd, index),
      'planes' => _plane(rnd, index),
      'birds' => _bird(rnd, index),
      'mermaids' => _mermaid(rnd, index),
      _ => _animal(rnd, index),
    };
  }

  static Path _oval(double cx, double cy, double w, double h) {
    return Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
  }

  static Path _roundRect(
    double cx,
    double cy,
    double w,
    double h, [
    double r = 0.04,
  ]) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
          Radius.circular(r),
        ),
      );
  }

  static List<ColoringSegment> _animal(math.Random rnd, int index) {
    final bodyY = 0.52 + rnd.nextDouble() * 0.04;
    final earSpread = 0.18 + rnd.nextDouble() * 0.06;
    return [
      ColoringSegment(
        id: 'ear_l',
        path: _oval(0.5 - earSpread, 0.28, 0.14, 0.16),
      ),
      ColoringSegment(
        id: 'ear_r',
        path: _oval(0.5 + earSpread, 0.28, 0.14, 0.16),
      ),
      ColoringSegment(id: 'head', path: _oval(0.5, 0.38, 0.36, 0.34)),
      ColoringSegment(id: 'body', path: _oval(0.5, bodyY + 0.18, 0.42, 0.36)),
      ColoringSegment(id: 'leg_l', path: _roundRect(0.38, 0.88, 0.1, 0.16, 0.05)),
      ColoringSegment(id: 'leg_r', path: _roundRect(0.62, 0.88, 0.1, 0.16, 0.05)),
      ColoringSegment(id: 'tail', path: _oval(0.78, bodyY + 0.12, 0.12, 0.08)),
      ColoringSegment(id: 'nose', path: _oval(0.5, 0.42, 0.08, 0.06)),
    ];
  }

  static List<ColoringSegment> _car(math.Random rnd, int index) {
    final roofH = 0.18 + rnd.nextDouble() * 0.04;
    return [
      ColoringSegment(id: 'cabin', path: _roundRect(0.5, 0.38, 0.42, roofH, 0.06)),
      ColoringSegment(id: 'body', path: _roundRect(0.5, 0.55, 0.72, 0.22, 0.06)),
      ColoringSegment(id: 'window_l', path: _roundRect(0.38, 0.38, 0.14, 0.1, 0.03)),
      ColoringSegment(id: 'window_r', path: _roundRect(0.58, 0.38, 0.14, 0.1, 0.03)),
      ColoringSegment(id: 'wheel_l', path: _oval(0.28, 0.72, 0.16, 0.16)),
      ColoringSegment(id: 'wheel_r', path: _oval(0.72, 0.72, 0.16, 0.16)),
      ColoringSegment(id: 'hub_l', path: _oval(0.28, 0.72, 0.06, 0.06)),
      ColoringSegment(id: 'hub_r', path: _oval(0.72, 0.72, 0.06, 0.06)),
      ColoringSegment(id: 'light', path: _oval(0.86, 0.55, 0.06, 0.08)),
    ];
  }

  static List<ColoringSegment> _doll(math.Random rnd, int index) {
    final dressW = 0.34 + rnd.nextDouble() * 0.08;
    return [
      ColoringSegment(id: 'hair', path: _oval(0.5, 0.26, 0.34, 0.2)),
      ColoringSegment(id: 'head', path: _oval(0.5, 0.34, 0.26, 0.26)),
      ColoringSegment(id: 'dress', path: _roundRect(0.5, 0.62, dressW, 0.36, 0.08)),
      ColoringSegment(id: 'arm_l', path: _roundRect(0.28, 0.55, 0.08, 0.22, 0.04)),
      ColoringSegment(id: 'arm_r', path: _roundRect(0.72, 0.55, 0.08, 0.22, 0.04)),
      ColoringSegment(id: 'leg_l', path: _roundRect(0.42, 0.88, 0.08, 0.14, 0.04)),
      ColoringSegment(id: 'leg_r', path: _roundRect(0.58, 0.88, 0.08, 0.14, 0.04)),
      ColoringSegment(id: 'bow', path: _oval(0.5, 0.18, 0.12, 0.08)),
    ];
  }

  static List<ColoringSegment> _plane(math.Random rnd, int index) {
    final wingY = 0.52 + rnd.nextDouble() * 0.04;
    return [
      ColoringSegment(id: 'fuselage', path: _roundRect(0.5, 0.5, 0.55, 0.16, 0.08)),
      ColoringSegment(id: 'nose', path: _oval(0.78, 0.5, 0.14, 0.14)),
      ColoringSegment(id: 'wing_l', path: _roundRect(0.42, wingY - 0.16, 0.18, 0.28, 0.05)),
      ColoringSegment(id: 'wing_r', path: _roundRect(0.42, wingY + 0.16, 0.18, 0.28, 0.05)),
      ColoringSegment(id: 'tail', path: _roundRect(0.22, 0.42, 0.1, 0.2, 0.04)),
      ColoringSegment(id: 'window_1', path: _oval(0.48, 0.48, 0.05, 0.05)),
      ColoringSegment(id: 'window_2', path: _oval(0.56, 0.48, 0.05, 0.05)),
      ColoringSegment(id: 'window_3', path: _oval(0.64, 0.48, 0.05, 0.05)),
    ];
  }

  static List<ColoringSegment> _bird(math.Random rnd, int index) {
    final wingTilt = rnd.nextDouble() * 0.04;
    return [
      ColoringSegment(id: 'body', path: _oval(0.48, 0.52, 0.34, 0.3)),
      ColoringSegment(id: 'head', path: _oval(0.66, 0.38, 0.2, 0.2)),
      ColoringSegment(id: 'beak', path: _oval(0.8, 0.4, 0.1, 0.06)),
      ColoringSegment(
        id: 'wing',
        path: _oval(0.42, 0.52 + wingTilt, 0.28, 0.16),
      ),
      ColoringSegment(id: 'tail', path: _roundRect(0.24, 0.55, 0.14, 0.12, 0.04)),
      ColoringSegment(id: 'leg_l', path: _roundRect(0.46, 0.78, 0.05, 0.14, 0.02)),
      ColoringSegment(id: 'leg_r', path: _roundRect(0.54, 0.78, 0.05, 0.14, 0.02)),
      ColoringSegment(id: 'eye', path: _oval(0.7, 0.36, 0.04, 0.04)),
    ];
  }

  static List<ColoringSegment> _mermaid(math.Random rnd, int index) {
    final tailBend = 0.02 + rnd.nextDouble() * 0.03;
    return [
      ColoringSegment(id: 'hair', path: _oval(0.62, 0.28, 0.28, 0.32)),
      ColoringSegment(id: 'head', path: _oval(0.62, 0.34, 0.18, 0.18)),
      ColoringSegment(id: 'torso', path: _roundRect(0.62, 0.5, 0.16, 0.18, 0.06)),
      ColoringSegment(id: 'shell_l', path: _oval(0.57, 0.48, 0.07, 0.06)),
      ColoringSegment(id: 'shell_r', path: _oval(0.67, 0.48, 0.07, 0.06)),
      ColoringSegment(id: 'tail', path: _oval(0.55, 0.7 + tailBend, 0.28, 0.34)),
      ColoringSegment(id: 'fin', path: _oval(0.42, 0.88, 0.22, 0.14)),
      ColoringSegment(id: 'castle', path: _roundRect(0.28, 0.55, 0.28, 0.4, 0.04)),
      ColoringSegment(id: 'tower', path: _roundRect(0.28, 0.32, 0.12, 0.2, 0.03)),
      ColoringSegment(id: 'bubble_1', path: _oval(0.2, 0.22, 0.06, 0.06)),
      ColoringSegment(id: 'bubble_2', path: _oval(0.78, 0.2, 0.05, 0.05)),
      ColoringSegment(id: 'fish', path: _oval(0.22, 0.78, 0.14, 0.08)),
    ];
  }
}
