/// Падающий блок со слогом на экране конструктора.
class FallingSyllableBlock {
  FallingSyllableBlock({
    required this.blockId,
    required this.text,
    required this.sequenceIndex,
    required this.xFactor,
    required this.startY,
  });

  final String blockId;
  final String text;
  final int sequenceIndex;
  final double xFactor;
  final double startY;

  double y = 0;
  bool collected = false;
}

/// Задание: собрать слово из падающих слогов по порядку.
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
}
