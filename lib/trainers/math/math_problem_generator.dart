import 'dart:math';

import 'math_problem.dart';
import 'math_problem_kind.dart';
import 'math_missing_mode.dart';

/// Генерация заданий для тренажёров «Считайка».
class MathProblemGenerator {
  MathProblemGenerator({Random? random, this.zeroProbability = 0.08})
      : _random = random ?? Random();

  final Random _random;

  /// Как часто встречаются нули в слагаемых / вычитаемых (редко).
  final double zeroProbability;

  MathProblem generate({
    required MathProblemKind kind,
    int multiplyRow = 2,
    MathProblem? avoidSameAs,
    MathMissingMode missingMode = MathMissingMode.addition,
  }) {
    const maxAttempts = 24;
    MathProblem problem;
    var attempts = 0;
    do {
      problem = _generateOnce(
        kind: kind,
        multiplyRow: multiplyRow,
        missingMode: missingMode,
      );
      attempts++;
    } while (avoidSameAs != null &&
        problem.isSameTaskAs(avoidSameAs) &&
        attempts < maxAttempts);
    return problem;
  }

  MathProblem _generateOnce({
    required MathProblemKind kind,
    int multiplyRow = 2,
    MathMissingMode missingMode = MathMissingMode.addition,
  }) {
    return switch (kind) {
      MathProblemKind.counting => _counting(),
      MathProblemKind.addition10 => _addition(maxSum: 10, kind: kind),
      MathProblemKind.addition20 => _addition(maxSum: 20, kind: kind),
      MathProblemKind.subtraction10 => _subtraction(maxMinuend: 10),
      MathProblemKind.missingAddend => missingMode == MathMissingMode.subtraction
          ? _missingSubtrahend(maxMinuend: 10)
          : _missingAddend(maxSum: 10),
      MathProblemKind.doubles => _doubles(),
      MathProblemKind.groups => _groups(),
      MathProblemKind.multiplyRow => _multiplyFact(
          row: multiplyRow.clamp(1, 10),
        ),
      MathProblemKind.multiplyMix => _multiplyMix(),
    };
  }

  MathProblem _counting() {
    final n = _random.nextInt(10) + 1;
    return MathProblem(
      kind: MathProblemKind.counting,
      promptText: 'Сколько?',
      dotCount: n,
      correctAnswer: n,
      choices: _choices(n, min: 1, max: 10),
      hintText: 'Посчитай все предметы',
    );
  }

  MathProblem _addition({required int maxSum, required MathProblemKind kind}) {
    if (maxSum < 1) {
      return _buildAddition(kind: kind, a: 0, b: 0, sum: 0, maxSum: maxSum);
    }

    if (_allowsZeroOperand()) {
      final sum = _random.nextInt(maxSum + 1);
      final a = sum == 0 ? 0 : _random.nextInt(sum + 1);
      final b = sum - a;
      return _buildAddition(kind: kind, a: a, b: b, sum: sum, maxSum: maxSum);
    }

    final sum = maxSum == 1 ? 1 : _random.nextInt(maxSum - 1) + 2;
    final a = _random.nextInt(sum - 1) + 1;
    final b = sum - a;
    return _buildAddition(kind: kind, a: a, b: b, sum: sum, maxSum: maxSum);
  }

  MathProblem _buildAddition({
    required MathProblemKind kind,
    required int a,
    required int b,
    required int sum,
    required int maxSum,
  }) {
    return MathProblem(
      kind: kind,
      promptText: '$a + $b = ?',
      leftAddend: a,
      rightAddend: b,
      correctAnswer: sum,
      choices: _choices(
        sum,
        min: sum == 0 ? 0 : 1,
        max: maxSum,
      ),
    );
  }

  MathProblem _subtraction({required int maxMinuend}) {
    if (maxMinuend <= 0) {
      return MathProblem(
        kind: MathProblemKind.subtraction10,
        promptText: '0 − 0 = ?',
        leftAddend: 0,
        rightAddend: 0,
        correctAnswer: 0,
        choices: _choices(0, min: 0, max: maxMinuend),
      );
    }

    if (_allowsZeroOperand()) {
      final a = _random.nextInt(maxMinuend + 1);
      final b = a == 0 ? 0 : _random.nextInt(a + 1);
      final result = a - b;
      return _buildSubtraction(a: a, b: b, result: result, maxMinuend: maxMinuend);
    }

    if (maxMinuend == 1) {
      return _buildSubtraction(a: 1, b: 1, result: 0, maxMinuend: maxMinuend);
    }

    final a = _random.nextInt(maxMinuend - 1) + 2;
    final b = _random.nextInt(a - 1) + 1;
    final result = a - b;
    return _buildSubtraction(a: a, b: b, result: result, maxMinuend: maxMinuend);
  }

  MathProblem _buildSubtraction({
    required int a,
    required int b,
    required int result,
    required int maxMinuend,
  }) {
    return MathProblem(
      kind: MathProblemKind.subtraction10,
      promptText: '$a − $b = ?',
      leftAddend: a,
      rightAddend: b,
      correctAnswer: result,
      choices: _choices(
        result,
        min: result == 0 ? 0 : 1,
        max: maxMinuend,
      ),
    );
  }

  bool _allowsZeroOperand() => _random.nextDouble() < zeroProbability;

  MathProblem _missingAddend({required int maxSum}) {
    final sum = _random.nextInt(maxSum - 1) + 2;
    final a = _allowsZeroOperand()
        ? _random.nextInt(sum)
        : _random.nextInt(sum - 1) + 1;
    final missing = sum - a;
    return MathProblem(
      kind: MathProblemKind.missingAddend,
      promptText: '$a + ? = $sum',
      leftAddend: a,
      rightAddend: sum,
      missingMode: MathMissingMode.addition,
      correctAnswer: missing,
      choices: _choices(
        missing,
        min: missing == 0 ? 0 : 1,
        max: maxSum,
      ),
      hintText: 'Какое число нужно прибавить?',
    );
  }

  MathProblem _missingSubtrahend({required int maxMinuend}) {
    final minuend = _random.nextInt(maxMinuend - 1) + 2;
    final missing = _random.nextInt(minuend - 1) + 1;
    final result = minuend - missing;
    return MathProblem(
      kind: MathProblemKind.missingAddend,
      promptText: '$minuend − ? = $result',
      leftAddend: result,
      rightAddend: missing,
      missingMode: MathMissingMode.subtraction,
      correctAnswer: missing,
      choices: _choices(
        missing,
        min: 1,
        max: maxMinuend,
      ),
      hintText: 'Сколько нужно вычесть?',
    );
  }

  MathProblem _doubles() {
    final n = _random.nextInt(9) + 1;
    final sum = n + n;
    return MathProblem(
      kind: MathProblemKind.doubles,
      promptText: '$n + $n = ?',
      leftAddend: n,
      rightAddend: n,
      correctAnswer: sum,
      choices: _choices(sum, min: 2, max: 18),
      hintText: 'Это то же, что $n × 2',
    );
  }

  MathProblem _groups() {
    final rows = _random.nextInt(4) + 2;
    final cols = _random.nextInt(4) + 2;
    final product = rows * cols;
    return MathProblem(
      kind: MathProblemKind.groups,
      promptText: 'Сколько всего?',
      groupRows: rows,
      groupCols: cols,
      correctAnswer: product,
      choices: _choices(product, min: 4, max: 25),
      hintText: '$rows ряда по $cols',
    );
  }

  MathProblem _multiplyFact({required int row}) {
    final col = _random.nextInt(10) + 1;
    final product = row * col;
    return MathProblem(
      kind: MathProblemKind.multiplyRow,
      promptText: '$row × $col = ?',
      groupRows: row,
      groupCols: col,
      correctAnswer: product,
      choices: _choices(product, min: 1, max: 100),
      hintText: 'Строка ×$row таблицы умножения',
    );
  }

  MathProblem _multiplyMix() {
    final row = _random.nextInt(10) + 1;
    return _multiplyFact(row: row);
  }

  List<int> _choices(int correct, {required int min, required int max}) {
    final set = <int>{correct};
    var guard = 0;
    while (set.length < 4 && guard < 40) {
      guard++;
      final delta = _random.nextInt(7) - 3;
      var candidate = correct + delta;
      if (candidate < min) candidate = min + _random.nextInt(3);
      if (candidate > max) candidate = max - _random.nextInt(3);
      if (candidate < min || candidate > max) continue;
      set.add(candidate);
    }
    while (set.length < 4) {
      set.add(min + _random.nextInt(max - min + 1));
    }
    final list = set.toList()..shuffle(_random);
    return list;
  }
}
