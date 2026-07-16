import 'package:flutter/material.dart';

class _AssemblyDragData {
  const _AssemblyDragData({required this.index, required this.text});

  final int index;
  final String text;
}

/// Сборочная строка слогов: перестановка и выброс перетаскиванием.
class SyllableAssemblyLine extends StatelessWidget {
  const SyllableAssemblyLine({
    super.key,
    required this.lineKey,
    required this.pickedSyllables,
    required this.panelHeight,
    this.enabled = true,
    this.onReorder,
    this.onRemoveAt,
  });

  final Key lineKey;
  final List<String> pickedSyllables;
  final double panelHeight;
  final bool enabled;
  final void Function(int from, int to)? onReorder;
  final ValueChanged<int>? onRemoveAt;

  int _targetIndexForOffset({
    required double localX,
    required double width,
    required int from,
    required int count,
  }) {
    if (count < 2) return from;
    final x = localX.clamp(0.0, width);
    var to = ((x / width) * count).floor().clamp(0, count - 1);
    if (to == from) {
      // Пустая зона «своего» слота — меняем с ближайшим соседом.
      to = from == 0 ? 1 : from - 1;
    }
    return to;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canDrag = enabled && onReorder != null && onRemoveAt != null;

    return KeyedSubtree(
      key: lineKey,
      child: DragTarget<_AssemblyDragData>(
        onWillAcceptWithDetails: (_) => canDrag,
        onAcceptWithDetails: (details) {
          if (!canDrag || onReorder == null) return;
          if (pickedSyllables.length < 2) return;

          final box = context.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return;

          final local = box.globalToLocal(details.offset);
          final from = details.data.index;
          final to = _targetIndexForOffset(
            localX: local.dx + 24,
            width: box.size.width,
            from: from,
            count: pickedSyllables.length,
          );
          if (from != to) onReorder!(from, to);
        },
        builder: (context, candidate, rejected) {
          final highlighted = candidate.isNotEmpty;
          return Container(
            width: double.infinity,
            height: panelHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: highlighted
                  ? colors.primaryContainer.withValues(alpha: 0.55)
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted ? colors.primary : colors.outline,
                width: highlighted ? 2.5 : 2,
              ),
            ),
            alignment: Alignment.center,
            child: pickedSyllables.isEmpty
                ? Text(
                    'Слоги появятся здесь',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pickedSyllables.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _AssemblyChip(
                            index: i,
                            text: pickedSyllables[i],
                            enabled: canDrag,
                            onReorder: onReorder,
                            onRemoveAt: onRemoveAt,
                          ),
                        ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _AssemblyChip extends StatelessWidget {
  const _AssemblyChip({
    required this.index,
    required this.text,
    required this.enabled,
    this.onReorder,
    this.onRemoveAt,
  });

  final int index;
  final String text;
  final bool enabled;
  final void Function(int from, int to)? onReorder;
  final ValueChanged<int>? onRemoveAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chip = _chipBody(context, colors);

    if (!enabled) return chip;

    return DragTarget<_AssemblyDragData>(
      onWillAcceptWithDetails: (details) => details.data.index != index,
      onAcceptWithDetails: (details) {
        onReorder?.call(details.data.index, index);
      },
      builder: (context, candidate, rejected) {
        final swapHighlight = candidate.isNotEmpty;
        return Draggable<_AssemblyDragData>(
          data: _AssemblyDragData(index: index, text: text),
          feedback: Material(
            color: Colors.transparent,
            elevation: 6,
            child: Transform.scale(
              scale: 1.08,
              child: _chipBody(context, colors, dragging: true),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: chip),
          onDragEnd: (details) {
            if (!details.wasAccepted) {
              onRemoveAt?.call(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: swapHighlight
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: chip,
          ),
        );
      },
    );
  }

  Widget _chipBody(
    BuildContext context,
    ColorScheme colors, {
    bool dragging = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dragging ? colors.primary : colors.outline,
          width: dragging ? 2.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
