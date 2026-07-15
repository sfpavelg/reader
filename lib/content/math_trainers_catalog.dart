import 'package:flutter/material.dart';

import '../screens/trainers/math/math_quiz_screen.dart';
import '../screens/trainers/math/multiplication_table_screen.dart';
import '../trainers/math/math_problem_kind.dart';

/// Пункт меню раздела «Считайка».
class MathTrainerEntry {
  const MathTrainerEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.builder,
    this.isTable = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget Function() builder;
  final bool isTable;
}

/// Упражнения от простого счёта к таблице умножения.
abstract final class MathTrainersCatalog {
  static const entries = <MathTrainerEntry>[
    MathTrainerEntry(
      icon: Icons.looks_one_outlined,
      label: 'Считаем',
      subtitle: '1, 2, 3 … до 10',
      builder: _counting,
    ),
    MathTrainerEntry(
      icon: Icons.add_circle_outline,
      label: 'Сложение',
      subtitle: 'До 10',
      builder: _addition10,
    ),
    MathTrainerEntry(
      icon: Icons.addchart_outlined,
      label: 'Сложение +',
      subtitle: 'До 20',
      builder: _addition20,
    ),
    MathTrainerEntry(
      icon: Icons.remove_circle_outline,
      label: 'Вычитание',
      subtitle: 'В пределах 10',
      builder: _subtraction10,
    ),
    MathTrainerEntry(
      icon: Icons.help_outline,
      label: 'Найди число',
      subtitle: '2 + ? = 7',
      builder: _missing,
    ),
    MathTrainerEntry(
      icon: Icons.sync,
      label: 'Удвоим',
      subtitle: 'Мостик к ×2',
      builder: _doubles,
    ),
    MathTrainerEntry(
      icon: Icons.grid_view,
      label: 'Группами',
      subtitle: 'Ряды и столбцы',
      builder: _groups,
    ),
    MathTrainerEntry(
      icon: Icons.table_chart_outlined,
      label: 'Таблица',
      subtitle: 'Умножение 1–10',
      builder: _table,
      isTable: true,
    ),
  ];

  static Widget _counting() =>
      const MathQuizScreen(kind: MathProblemKind.counting);

  static Widget _addition10() =>
      const MathQuizScreen(kind: MathProblemKind.addition10);

  static Widget _addition20() =>
      const MathQuizScreen(kind: MathProblemKind.addition20);

  static Widget _subtraction10() =>
      const MathQuizScreen(kind: MathProblemKind.subtraction10);

  static Widget _missing() =>
      const MathQuizScreen(kind: MathProblemKind.missingAddend);

  static Widget _doubles() => const MathQuizScreen(kind: MathProblemKind.doubles);

  static Widget _groups() => const MathQuizScreen(kind: MathProblemKind.groups);

  static Widget _table() => const MultiplicationTableScreen();
}
