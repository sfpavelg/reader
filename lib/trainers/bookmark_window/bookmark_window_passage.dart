/// Текст, разбитый на фрагменты для «закладки-окна».
class BookmarkWindowPassage {
  const BookmarkWindowPassage({
    required this.passageId,
    required this.levelId,
    required this.fullText,
    required this.fragments,
    required this.sourceEntryIds,
  });

  final String passageId;
  final int levelId;
  final String fullText;
  final List<String> fragments;
  final List<String> sourceEntryIds;

  int get length => fragments.length;
}
