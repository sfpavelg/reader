import 'package:flutter/material.dart';

import '../../widgets/syllable_tap_target.dart';

class UgadaykaGrid extends StatelessWidget {
  const UgadaykaGrid({
    super.key,
    required this.gridKey,
    required this.cols,
    required this.rows,
    required this.cells,
    required this.faceUp,
    required this.cellSide,
    required this.gap,
    required this.canInteract,
    required this.onCellTap,
    this.syllableFontScale = 0.34,
  });

  final GlobalKey gridKey;
  final int cols;
  final int rows;
  final List<String?> cells;
  final List<bool> faceUp;
  final double cellSide;
  final double gap;
  final bool canInteract;
  final ValueChanged<int> onCellTap;
  final double syllableFontScale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = cellSide * cols + gap * (cols - 1);
    final height = cellSide * rows + gap * (rows - 1);

    return SizedBox(
      key: gridKey,
      width: width,
      height: height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
        ),
        itemCount: cells.length,
        itemBuilder: (context, index) {
          final syllable = cells[index];
          if (syllable == null) {
            return _EmptyCell(colors: colors);
          }

          final revealed = faceUp[index];
          return SyllableTapTarget(
            enabled: canInteract && !revealed,
            onActivated: () => onCellTap(index),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: revealed
                  ? _SyllableFace(
                      key: ValueKey('open-$index-$syllable'),
                      syllable: syllable,
                      cellSide: cellSide,
                      colors: colors,
                      fontScale: syllableFontScale,
                    )
                  : _CardBack(
                      key: ValueKey('closed-$index'),
                      cellSide: cellSide,
                      colors: colors,
                      iconScale: syllableFontScale,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    super.key,
    required this.cellSide,
    required this.colors,
    this.iconScale = 0.34,
  });

  final double cellSide;
  final ColorScheme colors;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      elevation: 1,
      shadowColor: colors.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Icon(
          Icons.question_mark_rounded,
          size: cellSide * iconScale,
          color: colors.primary.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _SyllableFace extends StatelessWidget {
  const _SyllableFace({
    super.key,
    required this.syllable,
    required this.cellSide,
    required this.colors,
    this.fontScale = 0.34,
  });

  final String syllable;
  final double cellSide;
  final ColorScheme colors;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Center(
        child: Text(
          syllable,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: cellSide * fontScale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.15,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
