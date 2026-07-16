import 'math_problem_kind.dart';
import 'math_missing_mode.dart';

/// Одно задание в математическом тренажёре.
class MathProblem {
  const MathProblem({
    required this.kind,
    required this.promptText,
    required this.correctAnswer,
    required this.choices,
    this.groupRows,
    this.groupCols,
    this.dotCount,
    this.hintText,
    this.leftAddend,
    this.rightAddend,
    this.missingMode,
  });

  final MathProblemKind kind;
  final String promptText;
  final int correctAnswer;
  final List<int> choices;

  /// Для «Группами»: ряды × столбцы.
  final int? groupRows;
  final int? groupCols;

  /// Для «Считаем»: сколько точек показать.
  final int? dotCount;

  /// Подсказка под задачей.
  final String? hintText;

  /// Слагаемые для визуала «человечки + человечки».
  final int? leftAddend;
  final int? rightAddend;

  /// Режим «Найди число» (сложение / вычитание).
  final MathMissingMode? missingMode;

  String promptWithAnswer(int answer) {
    final index = promptText.indexOf('?');
    if (index < 0) return promptText;

    final needsSpace = index > 0 &&
        !RegExp(r'[\s=+\-−×·]').hasMatch(promptText[index - 1]);
    final replacement = needsSpace ? ' $answer' : '$answer';
    return promptText.replaceFirst('?', replacement);
  }

  /// Ключ задания для сравнения «то же самое, что в прошлый раз».
  String get taskKey {
    return switch (kind) {
      MathProblemKind.counting => 'c:$dotCount',
      MathProblemKind.addition10 ||
      MathProblemKind.addition20 ||
      MathProblemKind.doubles ||
      MathProblemKind.subtraction10 =>
        'a:$leftAddend:$rightAddend',
      MathProblemKind.missingAddend =>
        '${missingMode?.name ?? 'add'}:$promptText',
      MathProblemKind.multiplyRow ||
      MathProblemKind.multiplyMix =>
        'g:$groupRows×$groupCols',
      MathProblemKind.groups => 'g:$groupRows×$groupCols',
    };
  }

  bool isSameTaskAs(MathProblem other) =>
      kind == other.kind && taskKey == other.taskKey;
}
