import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Flood-fill раскраска по PNG: тап заливает замкнутую область.
class ImageFloodFillCanvas extends StatefulWidget {
  const ImageFloodFillCanvas({
    super.key,
    required this.assetPath,
    required this.initialPngBase64,
    required this.enabled,
    required this.fillColor,
    required this.onPainted,
  });

  final String assetPath;
  final String? initialPngBase64;
  final bool enabled;
  final Color? fillColor;
  final ValueChanged<String> onPainted;

  @override
  State<ImageFloodFillCanvas> createState() => _ImageFloodFillCanvasState();
}

class _ImageFloodFillCanvasState extends State<ImageFloodFillCanvas> {
  img.Image? _bitmap;
  ui.Image? _display;
  var _loading = true;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ImageFloodFillCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      late img.Image decoded;
      final data = await rootBundle.load(widget.assetPath);
      var fromAsset = img.decodeImage(data.buffer.asUint8List())!;
      fromAsset = _cropWhiteMargins(fromAsset);

      final saved = widget.initialPngBase64;
      if (saved != null && saved.isNotEmpty) {
        final fromSaved = img.decodeImage(base64Decode(saved));
        if (fromSaved != null &&
            fromSaved.width == fromAsset.width &&
            fromSaved.height == fromAsset.height) {
          decoded = fromSaved;
        } else {
          decoded = fromAsset;
        }
      } else {
        decoded = fromAsset;
      }

      // Крупнее на экране: до 1200 по длинной стороне.
      final longSide = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
      if (longSide > 1200) {
        final scale = 1200 / longSide;
        decoded = img.copyResize(
          decoded,
          width: (decoded.width * scale).round(),
          height: (decoded.height * scale).round(),
          interpolation: img.Interpolation.average,
        );
      }

      final display = await _toUiImage(decoded);
      if (!mounted) return;
      setState(() {
        _bitmap = decoded;
        _display = display;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить картинку';
      });
    }
  }

  /// Обрезает пустые белые поля вокруг рисунка.
  img.Image _cropWhiteMargins(img.Image src, {int pad = 6}) {
    var minX = src.width;
    var minY = src.height;
    var maxX = 0;
    var maxY = 0;
    var found = false;

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        if (p.r < 245 || p.g < 245 || p.b < 245) {
          found = true;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (!found) return src;

    minX = (minX - pad).clamp(0, src.width - 1);
    minY = (minY - pad).clamp(0, src.height - 1);
    maxX = (maxX + pad).clamp(0, src.width - 1);
    maxY = (maxY + pad).clamp(0, src.height - 1);

    return img.copyCrop(
      src,
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }

  Future<ui.Image> _toUiImage(img.Image src) async {
    final rgba = src.convert(format: img.Format.uint8, numChannels: 4);
    final bytes = Uint8List.fromList(rgba.toUint8List());
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      rgba.width,
      rgba.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> _onTapDown(TapDownDetails details, BoxConstraints box) async {
    if (!widget.enabled ||
        widget.fillColor == null ||
        _bitmap == null ||
        _busy) {
      return;
    }
    final bitmap = _bitmap!;
    final size = Size(box.maxWidth, box.maxHeight);
    final fitted = _fittedRect(
      Size(bitmap.width.toDouble(), bitmap.height.toDouble()),
      size,
    );
    final local = details.localPosition;
    if (!fitted.contains(local)) return;

    final bx = ((local.dx - fitted.left) / fitted.width * bitmap.width)
        .floor()
        .clamp(0, bitmap.width - 1);
    final by = ((local.dy - fitted.top) / fitted.height * bitmap.height)
        .floor()
        .clamp(0, bitmap.height - 1);

    final color = widget.fillColor!;
    final fill = img.ColorRgba8(
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
      255,
    );

    _busy = true;
    final changed = _floodFill(bitmap, bx, by, fill);
    if (!changed) {
      _busy = false;
      return;
    }

    final png = img.encodePng(bitmap);
    final display = await _toUiImage(bitmap);
    if (!mounted) return;
    setState(() => _display = display);
    widget.onPainted(base64Encode(png));
    _busy = false;
  }

  bool _floodFill(img.Image image, int sx, int sy, img.ColorRgba8 fill) {
    final start = image.getPixel(sx, sy);
    if (_isInk(start)) return false;
    if (_sameColor(start, fill)) return false;

    final w = image.width;
    final h = image.height;
    final visited = List<bool>.filled(w * h, false);
    final stack = <int>[sx + sy * w];
    var painted = 0;

    final sr = start.r.toInt();
    final sg = start.g.toInt();
    final sb = start.b.toInt();

    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      if (visited[i]) continue;
      visited[i] = true;
      final x = i % w;
      final y = i ~/ w;
      final p = image.getPixel(x, y);
      if (_isInk(p)) continue;
      if (!_matchesSeed(p, sr, sg, sb)) continue;

      image.setPixelRgba(x, y, fill.r, fill.g, fill.b, 255);
      painted++;

      if (x > 0) stack.add(i - 1);
      if (x + 1 < w) stack.add(i + 1);
      if (y > 0) stack.add(i - w);
      if (y + 1 < h) stack.add(i + w);
    }
    return painted > 0;
  }

  /// Контур = тёмный и почти серый. Цветные заливки (даже тёмные) — не контур.
  bool _isInk(img.Pixel p) {
    final r = p.r.toDouble();
    final g = p.g.toDouble();
    final b = p.b.toDouble();
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    final chroma = [r, g, b].reduce((a, b) => a > b ? a : b) -
        [r, g, b].reduce((a, b) => a < b ? a : b);
    return lum < 95 && chroma < 45;
  }

  bool _sameColor(img.Pixel a, img.ColorRgba8 b) {
    return (a.r - b.r).abs() < 8 &&
        (a.g - b.g).abs() < 8 &&
        (a.b - b.b).abs() < 8;
  }

  /// Перекрашиваем ту же область (белый или уже залитый цвет).
  bool _matchesSeed(img.Pixel p, int sr, int sg, int sb) {
    return (p.r - sr).abs() < 32 &&
        (p.g - sg).abs() < 32 &&
        (p.b - sb).abs() < 32;
  }

  Rect _fittedRect(Size image, Size box) {
    final scale = (box.width / image.width < box.height / image.height)
        ? box.width / image.width
        : box.height / image.height;
    final w = image.width * scale;
    final h = image.height * scale;
    return Rect.fromLTWH(
      (box.width - w) / 2,
      (box.height - h) / 2,
      w,
      h,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _display == null) {
      return Center(child: Text(_error ?? 'Ошибка'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => unawaited(_onTapDown(d, constraints)),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _UiImagePainter(_display!),
          ),
        );
      },
    );
  }
}

class _UiImagePainter extends CustomPainter {
  _UiImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final scale = (size.width / src.width < size.height / src.height)
        ? size.width / src.width
        : size.height / src.height;
    final w = src.width * scale;
    final h = src.height * scale;
    final dst = Rect.fromLTWH(
      (size.width - w) / 2,
      (size.height - h) / 2,
      w,
      h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(dst.inflate(2), const Radius.circular(12)),
      Paint()..color = const Color(0xFFFFFDF7),
    );
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _UiImagePainter oldDelegate) =>
      oldDelegate.image != image;
}
