import 'math_problem_kind.dart';

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

  String promptWithAnswer(int answer) {
    if (promptText.contains('?')) {
      return promptText.replaceFirst('?', '$answer');
    }
    return promptText;
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
        promptText,
      MathProblemKind.multiplyRow ||
      MathProblemKind.multiplyMix =>
        'g:$groupRows×$groupCols',
      MathProblemKind.groups => 'g:$groupRows×$groupCols',
    };
  }

  bool isSameTaskAs(MathProblem other) =>
      kind == other.kind && taskKey == other.taskKey;
}
