import '../../models/dictionary/dictionary_entry.dart';

enum TachistoscopeOptionKind { text, image }

class TachistoscopeOption {
  const TachistoscopeOption({
    required this.entryId,
    required this.label,
    required this.kind,
    this.imageAsset,
  });

  final String entryId;
  final String label;
  final TachistoscopeOptionKind kind;
  final String? imageAsset;

  bool get isImage => kind == TachistoscopeOptionKind.image;
}

/// Одно задание тахистоскопа: вспышка + три варианта ответа.
class TachistoscopeTask {
  const TachistoscopeTask({
    required this.taskId,
    required this.levelId,
    required this.target,
    required this.options,
    required this.correctIndex,
    required this.flashDuration,
  });

  final String taskId;
  final int levelId;
  final DictionaryEntry target;
  final List<TachistoscopeOption> options;
  final int correctIndex;
  final Duration flashDuration;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}
