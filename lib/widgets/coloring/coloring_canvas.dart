import 'package:flutter/material.dart';

import '../../content/coloring_catalog.dart';

/// Холст раскраски: заливка сегментов + контур.
class ColoringCanvas extends StatelessWidget {
  const ColoringCanvas({
    super.key,
    required this.page,
    required this.fills,
    required this.onSegmentTap,
    this.enabled = true,
  });

  final ColoringPage page;
  final Map<String, int> fills;
  final ValueChanged<String> onSegmentTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled
                ? (details) {
                    final local = details.localPosition;
                    final nx = local.dx / size.width;
                    final ny = local.dy / size.height;
                    // Сверху вниз по списку — мелкие детали поверх крупных.
                    for (final segment in page.segments.reversed) {
                      if (segment.path.contains(Offset(nx, ny))) {
                        onSegmentTap(segment.id);
                        return;
                      }
                    }
                  }
                : null,
            child: CustomPaint(
              size: size,
              painter: _ColoringPainter(page: page, fills: fills),
            ),
          );
        },
      ),
    );
  }
}

class _ColoringPainter extends CustomPainter {
  _ColoringPainter({required this.page, required this.fills});

  final ColoringPage page;
  final Map<String, int> fills;

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = Matrix4.diagonal3Values(size.width, size.height, 1);

    // Бумага
    final paper = Paint()..color = const Color(0xFFFFFDF7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ),
      paper,
    );

    for (final segment in page.segments) {
      final transformed = segment.path.transform(matrix.storage);
      final fillArgb = fills[segment.id];
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = fillArgb != null
            ? Color(fillArgb)
            : const Color(0xFFFFFFFF);
      canvas.drawPath(transformed, fill);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF37474F)
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(transformed, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ColoringPainter oldDelegate) {
    return oldDelegate.page.id != page.id || oldDelegate.fills != fills;
  }
}
