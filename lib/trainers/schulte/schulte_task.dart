enum SchulteOrderMode { alphabetical, difficulty }

class SchulteCell {
  const SchulteCell({
    required this.gridIndex,
    required this.entryId,
    required this.text,
    required this.orderRank,
  });

  final int gridIndex;
  final String entryId;
  final String text;
  final int orderRank;
}

/// Таблица Шульте, сгенерированная из словаря (без картинок).
class SchulteTask {
  const SchulteTask({
    required this.taskId,
    required this.levelId,
    required this.gridSize,
    required this.orderMode,
    required this.cells,
  });

  final String taskId;
  final int levelId;
  final int gridSize;
  final SchulteOrderMode orderMode;
  final List<SchulteCell> cells;

  int get cellCount => gridSize * gridSize;

  SchulteCell? cellAt(int gridIndex) {
    for (final c in cells) {
      if (c.gridIndex == gridIndex) return c;
    }
    return null;
  }

  SchulteCell cellWithOrderRank(int rank) {
    return cells.firstWhere((c) => c.orderRank == rank);
  }
}
