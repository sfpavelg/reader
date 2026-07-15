import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/math/math_problem_generator.dart';
import 'package:reader/trainers/math/math_problem_kind.dart';

void main() {
  late MathProblemGenerator generator;

  setUp(() {
    generator = MathProblemGenerator(random: Random(1));
  });

  test('counting produces 1-10 dots', () {
    final p = generator.generate(kind: MathProblemKind.counting);
    expect(p.dotCount, inInclusiveRange(1, 10));
    expect(p.correctAnswer, p.dotCount);
    expect(p.choices, contains(p.correctAnswer));
    expect(p.choices.length, 4);
  });

  test('addition stays within limit', () {
    final p = generator.generate(kind: MathProblemKind.addition10);
    expect(p.correctAnswer, lessThanOrEqualTo(10));
    expect(p.choices, contains(p.correctAnswer));
  });

  test('doubles hint mentions multiplication', () {
    final p = generator.generate(kind: MathProblemKind.doubles);
    expect(p.hintText, contains('× 2'));
    expect(p.correctAnswer % 2, 0);
    expect(p.leftAddend, p.rightAddend);
  });

  test('addition includes addends for buddy visual', () {
    final p = generator.generate(kind: MathProblemKind.addition10);
    expect(p.leftAddend, isNotNull);
    expect(p.rightAddend, isNotNull);
    expect(p.leftAddend! + p.rightAddend!, p.correctAnswer);
    expect(p.promptWithAnswer(p.correctAnswer), isNot(contains('?')));
  });

  test('speed bonus on all math trainers', () {
    for (final kind in MathProblemKind.values) {
      expect(kind.usesSpeedBonus, isTrue, reason: '$kind');
    }
  });

  test('groups uses rows and cols', () {
    final p = generator.generate(kind: MathProblemKind.groups);
    expect(p.groupRows, isNotNull);
    expect(p.groupCols, isNotNull);
    expect(p.correctAnswer, p.groupRows! * p.groupCols!);
  });

  test('multiply row respects selected row', () {
    final p = generator.generate(
      kind: MathProblemKind.multiplyRow,
      multiplyRow: 3,
    );
    expect(p.promptText, startsWith('3 ×'));
    final parts = p.promptText.split('×');
    final col = int.parse(parts[1].trim().split('=').first.trim());
    expect(p.correctAnswer, 3 * col);
    expect(p.groupRows, 3);
    expect(p.groupCols, col);
    expect(p.correctAnswer, p.groupRows! * p.groupCols!);
  });

  test('addition rarely uses zero operands', () {
    final gen = MathProblemGenerator(
      random: Random(42),
      zeroProbability: 0.0,
    );
    for (var i = 0; i < 50; i++) {
      final p = gen.generate(kind: MathProblemKind.addition20);
      expect(p.leftAddend, greaterThan(0));
      expect(p.rightAddend, greaterThan(0));
    }
  });

  test('subtraction rarely uses zero operands', () {
    final gen = MathProblemGenerator(
      random: Random(42),
      zeroProbability: 0.0,
    );
    for (var i = 0; i < 50; i++) {
      final p = gen.generate(kind: MathProblemKind.subtraction10);
      final parts = p.promptText.split('−');
      final a = int.parse(parts[0].trim());
      final b = int.parse(parts[1].trim().split('=').first.trim());
      expect(a, greaterThan(1));
      expect(b, greaterThan(0));
    }
  });

  test('doubles avoids consecutive repeat', () {
    final gen = MathProblemGenerator(random: Random(7));
    var previous = gen.generate(kind: MathProblemKind.doubles);
    for (var i = 0; i < 30; i++) {
      final next = gen.generate(
        kind: MathProblemKind.doubles,
        avoidSameAs: previous,
      );
      expect(next.isSameTaskAs(previous), isFalse);
      previous = next;
    }
  });

  test('choices are non-negative', () {
    for (final kind in MathProblemKind.values) {
      final p = generator.generate(kind: kind);
      expect(p.choices.every((c) => c >= 0), isTrue, reason: '$kind');
    }
  });
}
