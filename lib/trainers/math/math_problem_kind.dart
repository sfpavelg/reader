/// Тип упражнения в разделе «Считайка».
enum MathProblemKind {
  /// Сколько предметов на картинке? (1–10)
  counting,

  /// Сложение в пределах 10.
  addition10,

  /// Сложение в пределах 20.
  addition20,

  /// Вычитание в пределах 10.
  subtraction10,

  /// Найди пропущенное слагаемое: 2 + ? = 7.
  missingAddend,

  /// Удвоение: 4 + 4.
  doubles,

  /// Группами: несколько рядов одинаковых точек (основа умножения).
  groups,

  /// Примеры одной строки таблицы: ×2, ×3 …
  multiplyRow,

  /// Случайный пример из таблицы 1–10.
  multiplyMix,
}

extension MathProblemKindX on MathProblemKind {
  String get title => switch (this) {
        MathProblemKind.counting => 'Считаем',
        MathProblemKind.addition10 => 'Сложение до 10',
        MathProblemKind.addition20 => 'Сложение до 20',
        MathProblemKind.subtraction10 => 'Вычитание до 10',
        MathProblemKind.missingAddend => 'Найди число',
        MathProblemKind.doubles => 'Удвоим',
        MathProblemKind.groups => 'Группами',
        MathProblemKind.multiplyRow => 'Строка таблицы',
        MathProblemKind.multiplyMix => 'Таблица',
      };

  String get subtitle => switch (this) {
        MathProblemKind.counting => 'Считаем предметы от 1 до 10',
        MathProblemKind.addition10 => 'Складываем маленькие числа',
        MathProblemKind.addition20 => 'Чуть сложнее, до 20',
        MathProblemKind.subtraction10 => 'Убираем и считаем остаток',
        MathProblemKind.missingAddend => 'Какое число подставить?',
        MathProblemKind.doubles => 'Тот же число два раза — это ×2',
        MathProblemKind.groups => 'Сколько всего в рядах?',
        MathProblemKind.multiplyRow => 'Отработать одну строку',
        MathProblemKind.multiplyMix => 'Случайные примеры 1–10',
      };

  /// Бонус ×2 звезды, если ответить за 3 секунды.
  bool get usesSpeedBonus => true;

  String get trainerId => switch (this) {
        MathProblemKind.counting => 'math_counting',
        MathProblemKind.addition10 => 'math_addition10',
        MathProblemKind.addition20 => 'math_addition20',
        MathProblemKind.subtraction10 => 'math_subtraction10',
        MathProblemKind.missingAddend => 'math_missing',
        MathProblemKind.doubles => 'math_doubles',
        MathProblemKind.groups => 'math_groups',
        MathProblemKind.multiplyRow => 'math_multiply_row',
        MathProblemKind.multiplyMix => 'math_multiply_mix',
      };
}
