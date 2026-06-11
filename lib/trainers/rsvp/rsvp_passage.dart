/// Серия слов для одного прохода RSVP.
class RsvpPassage {
  const RsvpPassage({
    required this.passageId,
    required this.levelId,
    required this.words,
    required this.sourceEntryIds,
  });

  final String passageId;
  final int levelId;
  final List<String> words;
  final List<String> sourceEntryIds;

  int get length => words.length;
}
