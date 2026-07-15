import 'package:flutter/material.dart';

class BookmarkWindowVisualTile {
  BookmarkWindowVisualTile({
    required this.id,
    required this.syllable,
    required this.col,
    required this.row,
    this.gridIndex,
  });

  final int id;
  String syllable;
  double col;
  double row;
  int? gridIndex;
  bool highlighted = false;
}

class BookmarkWindowAnimatedGrid extends StatelessWidget {
  const BookmarkWindowAnimatedGrid({
    super.key,
    required this.gridKey,
    required this.tiles,
    required this.cols,
    required this.rows,
    required this.cellSide,
    required this.gap,
    required this.canInteract,
    required this.selectedGridIndex,
    required this.highlightPulse,
    required this.onCellTap,
  });

  final GlobalKey gridKey;
  final List<BookmarkWindowVisualTile> tiles;
  final int cols;
  final int rows;
  final double cellSide;
  final double gap;
  final bool canInteract;
  final int? selectedGridIndex;
  final double highlightPulse;
  final ValueChanged<int> onCellTap;

  double get _stride => cellSide + gap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = cellSide * cols + gap * (cols - 1);
    final height = cellSide * rows + gap * (rows - 1);

    return SizedBox(
      key: gridKey,
      width: width,
      height: height,
      child: ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: canInteract ? _handleTap : null,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final tile in tiles) _buildTile(context, colors, tile),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final local = details.localPosition;
    final col = (local.dx / _stride).floor().clamp(0, cols - 1);
    final row = (local.dy / _stride).floor().clamp(0, rows - 1);
    onCellTap(row * cols + col);
  }

  Widget _buildTile(
    BuildContext context,
    ColorScheme colors,
    BookmarkWindowVisualTile tile,
  ) {
    final selected =
        tile.gridIndex != null && tile.gridIndex == selectedGridIndex;
    final pulse = tile.highlighted ? highlightPulse : 0.0;
    final baseColor = selected
        ? colors.primaryContainer
        : colors.surfaceContainerHigh;
    final fillColor = tile.highlighted
        ? Color.lerp(baseColor, colors.tertiaryContainer, pulse) ?? baseColor
        : baseColor;
    final borderColor = tile.highlighted
        ? Color.lerp(
              selected ? colors.primary : colors.outlineVariant,
              colors.tertiary,
              pulse,
            ) ??
            colors.tertiary
        : selected
            ? colors.primary
            : colors.outlineVariant;
    final syllableStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: cellSide * 0.30,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.15,
      color: tile.highlighted
          ? Color.lerp(
                colors.onSurface,
                colors.tertiary,
                pulse * 0.5,
              )
          : colors.onSurface,
    );

    return Positioned(
      key: ValueKey(tile.id),
      left: tile.col * _stride,
      top: tile.row * _stride,
      width: cellSide,
      height: cellSide,
      child: Material(
        color: fillColor,
        elevation: tile.highlighted ? 2 + pulse * 4 : 0,
        shadowColor: colors.tertiary.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor,
            width: tile.highlighted ? 2 + pulse * 2 : (selected ? 2.5 : 1),
          ),
        ),
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Center(
            child: Text(
              tile.syllable,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              style: syllableStyle,
            ),
          ),
        ),
      ),
    );
  }
}
