/// Падающий блок со слогом на экране конструктора.
class FallingSyllableBlock {
  FallingSyllableBlock({
    required this.blockId,
    required this.text,
    required this.targetSequenceIndex,
    required this.spawnWave,
    required this.xFactor,
    required this.startY,
    required this.driftSpeed,
    this.xPhase = 0,
  });

  final String blockId;
  final String text;

  /// Индекс слога в целевом слове; `null` — лишний слог-помеха.
  final int? targetSequenceIndex;
  /// Очередь появления: меньше — раньше входит на экран.
  final int spawnWave;
  final double xFactor;
  final double startY;
  final double driftSpeed;

  double y = 0;
  double xPhase;
  bool collected = false;

  bool get isDistractor => targetSequenceIndex == null;
}

/// Задание: поймать падающие слоги и собрать слово по порядку.
class SyllableBuilderTask {
  const SyllableBuilderTask({
    required this.taskId,
    required this.entryId,
    required this.word,
    required this.syllables,
    required this.blocks,
  });

  final String taskId;
  final String entryId;
  final String word;
  final List<String> syllables;
  final List<FallingSyllableBlock> blocks;

  int get syllableCount => syllables.length;

  Iterable<FallingSyllableBlock> get targetBlocks =>
      blocks.where((b) => !b.isDistractor);
}
