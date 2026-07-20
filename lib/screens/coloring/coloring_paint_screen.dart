import 'package:flutter/material.dart';

import '../../content/coloring_catalog.dart';
import '../../data/hive/local_storage.dart';
import '../../mixins/trainer_stars_mixin.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/coloring/coloring_canvas.dart';
import '../../widgets/coloring/image_flood_fill_canvas.dart';
import '../../widgets/stars_balance_chip.dart';

/// Палитра (без белого — стирание отдельной кнопкой-ластиком).
const _paletteColors = <Color>[
  Color(0xFFE53935), // красный
  Color(0xFFFF9800), // оранжевый
  Color(0xFFFFEB3B), // жёлтый
  Color(0xFF43A047), // зелёный
  Color(0xFF1E88E5), // синий
  Color(0xFF8E24AA), // фиолетовый
  Color(0xFF6D4C41), // коричневый
  Color(0xFF212121), // чёрный
  Color(0xFFFF80AB), // розовый
  Color(0xFF00BCD4), // бирюзовый
  Color(0xFF8BC34A), // салатовый
  Color(0xFFFFCC80), // телесный / персиковый
];

const _eraseColor = Color(0xFFFFFFFF);

class ColoringPaintScreen extends StatefulWidget {
  const ColoringPaintScreen({super.key, required this.pageId});

  final String pageId;

  @override
  State<ColoringPaintScreen> createState() => _ColoringPaintScreenState();
}

class _ColoringPaintScreenState extends State<ColoringPaintScreen>
    with TrainerStarsMixin {
  late ColoringPage _page;
  late Map<String, int> _fills;
  String? _paintedPng;

  /// Выбранный цвет кисточки.
  Color _tipColor = _paletteColors.first;

  /// Режим ластика.
  bool _eraseMode = false;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    final page = ColoringCatalog.pageById(widget.pageId);
    if (page == null) {
      _page = ColoringCatalog.pagesForTheme('animals').first;
      _fills = {};
      return;
    }
    _page = page;
    final progress = LocalStorage.readColoringProgress();
    _fills = progress.fillsFor(page.id);
    _paintedPng = progress.paintedPngFor(page.id);
  }

  Color get _activeFillColor => _eraseMode ? _eraseColor : _tipColor;

  Future<void> _persistFills() async {
    var progress = LocalStorage.readColoringProgress();
    for (final e in _fills.entries) {
      progress = progress.paintSegment(
        pageId: _page.id,
        segmentId: e.key,
        argb: e.value,
      );
    }
    await LocalStorage.writeColoringProgress(progress);
  }

  Future<void> _persistPaintedPng(String base64Png) async {
    _paintedPng = base64Png;
    final progress = LocalStorage.readColoringProgress().savePaintedPng(
      pageId: _page.id,
      base64Png: base64Png,
    );
    await LocalStorage.writeColoringProgress(progress);
  }

  Future<void> _onPaletteTap(Color color) async {
    await AppFeedback.tap();
    setState(() {
      _eraseMode = false;
      _tipColor = color;
    });
  }

  Future<void> _onEraserTap() async {
    await AppFeedback.tap();
    setState(() => _eraseMode = true);
  }

  Future<void> _onSegmentTap(String segmentId) async {
    await AppFeedback.tap();
    setState(() {
      if (_eraseMode) {
        final next = Map<String, int>.from(_fills)..remove(segmentId);
        _fills = next;
      } else {
        _fills = {..._fills, segmentId: _tipColor.toARGB32()};
      }
    });
    await _persistFills();
  }

  Future<void> _onImagePainted(String base64Png) async {
    await AppFeedback.tap();
    await _persistPaintedPng(base64Png);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = ColoringCatalog.themeById(_page.themeId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${theme.title}: ${_page.title}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StarsBalanceChip(stars: trainerStars, compact: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: _page.isImagePage
                    ? ImageFloodFillCanvas(
                        assetPath: _page.imageAsset!,
                        initialPngBase64: _paintedPng,
                        enabled: true,
                        fillColor: _activeFillColor,
                        onPainted: _onImagePainted,
                      )
                    : ColoringCanvas(
                        page: _page,
                        fills: _fills,
                        onSegmentTap: _onSegmentTap,
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _eraseMode
                        ? 'Ластик: кликни, чтобы стереть цвет'
                        : 'Выбери цвет и кликни по области',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PrettyBrush(tipColor: _eraseMode ? null : _tipColor),
                      const SizedBox(width: 10),
                      _EraserButton(
                        selected: _eraseMode,
                        onTap: _onEraserTap,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaletteStrip(
                          colors: _paletteColors,
                          selected: _eraseMode ? null : _tipColor,
                          onSelect: _onPaletteTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Красивая кисточка: кончик окрашивается выбранным цветом.
class _PrettyBrush extends StatelessWidget {
  const _PrettyBrush({required this.tipColor});

  final Color? tipColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 72,
      child: CustomPaint(
        painter: _BrushPainter(tipColor: tipColor ?? const Color(0xFFF5F5F5)),
      ),
    );
  }
}

class _BrushPainter extends CustomPainter {
  _BrushPainter({required this.tipColor});

  final Color tipColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Ручка
    final handle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.28),
        width: size.width * 0.28,
        height: size.height * 0.42,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      handle,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
        ).createShader(handle.outerRect),
    );

    // Ободок (металл)
    final ferrule = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.52),
        width: size.width * 0.38,
        height: size.height * 0.12,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      ferrule,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
        ).createShader(ferrule.outerRect),
    );

    // Ворс / кончик
    final tipPath = Path()
      ..moveTo(cx - size.width * 0.2, size.height * 0.58)
      ..lineTo(cx + size.width * 0.2, size.height * 0.58)
      ..quadraticBezierTo(
        cx + size.width * 0.22,
        size.height * 0.78,
        cx,
        size.height * 0.96,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.22,
        size.height * 0.78,
        cx - size.width * 0.2,
        size.height * 0.58,
      )
      ..close();
    canvas.drawPath(tipPath, Paint()..color = tipColor);
    canvas.drawPath(
      tipPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF37474F),
    );

    // Блик на кончике
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.06, size.height * 0.7),
        width: size.width * 0.08,
        height: size.height * 0.1,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _BrushPainter oldDelegate) =>
      oldDelegate.tipColor != tipColor;
}

class _EraserButton extends StatelessWidget {
  const _EraserButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: selected
              ? colors.primaryContainer
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: CustomPaint(
                size: const Size(30, 30),
                painter: _EraserPainter(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Ластик', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EraserPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.28,
        size.width * 0.76,
        size.height * 0.48,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFFAB91));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFBF360C),
    );

    // Синяя «шапка» ластика
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.76,
        size.height * 0.22,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(cap, Paint()..color = const Color(0xFF64B5F6));
    canvas.drawRRect(
      cap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF1565C0),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  final List<Color> colors;
  final Color? selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    // Два полных ряда по 6 кружков.
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 6;
        const spacing = 8.0;
        final cell = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final size = cell.clamp(28.0, 40.0);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final color in colors)
              GestureDetector(
                onTap: () => onSelect(color),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == color
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF455A64),
                      width: selected == color ? 3 : 1.5,
                    ),
                    boxShadow: [
                      if (selected == color)
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
