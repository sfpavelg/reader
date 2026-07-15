import 'dart:async';

import 'package:flutter/material.dart';

import '../../../mixins/trainer_stars_mixin.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/stars_balance_chip.dart';
import 'math_quiz_screen.dart';
import '../../../trainers/math/math_problem_kind.dart';

/// Интерактивная таблица умножения 1–10 с тренировкой по строкам.
class MultiplicationTableScreen extends StatefulWidget {
  const MultiplicationTableScreen({super.key});

  @override
  State<MultiplicationTableScreen> createState() =>
      _MultiplicationTableScreenState();
}

class _MultiplicationTableScreenState extends State<MultiplicationTableScreen>
    with TrainerStarsMixin {
  int _selectedRow = 2;
  int? _highlightA;
  int? _highlightB;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
  }

  Future<void> _openRowPractice(int row) async {
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MathQuizScreen(
          kind: MathProblemKind.multiplyRow,
          multiplyRow: row,
        ),
      ),
    );
    reloadTrainerStars();
  }

  Future<void> _openMixPractice() async {
    await AppFeedback.tap();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MathQuizScreen(kind: MathProblemKind.multiplyMix),
      ),
    );
    reloadTrainerStars();
  }

  void _onCellTap(int a, int b) {
    unawaited(AppFeedback.tap());
    setState(() {
      _highlightA = a;
      _highlightB = b;
      _selectedRow = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица умножения'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StarsBalanceChip(stars: trainerStars, compact: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Нажми на пример — подсветится строка. Потренируй строку или случайные примеры.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: _MultiplicationGrid(
                    selectedRow: _selectedRow,
                    highlightA: _highlightA,
                    highlightB: _highlightB,
                    onCellTap: _onCellTap,
                    onRowHeaderTap: (row) => setState(() => _selectedRow = row),
                  ),
                ),
              ),
              if (_highlightA != null && _highlightB != null) ...[
                const SizedBox(height: 8),
                Text(
                  '$_highlightA × $_highlightB = ${_highlightA! * _highlightB!}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => unawaited(_openRowPractice(_selectedRow)),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Тренировать ×$_selectedRow'),
                  ),
                  OutlinedButton(
                    onPressed: () => unawaited(_openMixPractice()),
                    child: const Text('Случайные примеры'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiplicationGrid extends StatelessWidget {
  const _MultiplicationGrid({
    required this.selectedRow,
    required this.highlightA,
    required this.highlightB,
    required this.onCellTap,
    required this.onRowHeaderTap,
  });

  final int selectedRow;
  final int? highlightA;
  final int? highlightB;
  final void Function(int a, int b) onCellTap;
  final void Function(int row) onRowHeaderTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const size = 10;

    Widget headerCell(String text, {bool rowHeader = false, VoidCallback? onTap}) {
      final bg = rowHeader && int.tryParse(text) == selectedRow
          ? colors.primaryContainer
          : colors.surfaceContainerHighest;
      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: rowHeader ? 36 : 34,
            height: 34,
            alignment: Alignment.center,
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      );
    }

    Widget bodyCell(int a, int b) {
      final product = a * b;
      final highlighted = highlightA == a && highlightB == b;
      final inRow = a == selectedRow;
      Color bg = colors.surface;
      if (highlighted) {
        bg = colors.primaryContainer;
      } else if (inRow) {
        bg = colors.primaryContainer.withValues(alpha: 0.35);
      }

      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onCellTap(a, b),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: highlighted ? colors.primary : colors.outlineVariant,
                width: highlighted ? 2 : 1,
              ),
            ),
            child: Text(
              '$product',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlighted
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
            ),
          ),
        ),
      );
    }

    return Table(
      defaultColumnWidth: const FixedColumnWidth(36),
      children: [
        TableRow(
          children: [
            const SizedBox(width: 36, height: 34),
            for (var b = 1; b <= size; b++) headerCell('$b'),
          ],
        ),
        for (var a = 1; a <= size; a++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: headerCell(
                  '$a',
                  rowHeader: true,
                  onTap: () => onRowHeaderTap(a),
                ),
              ),
              for (var b = 1; b <= size; b++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 2),
                  child: bodyCell(a, b),
                ),
            ],
          ),
      ],
    );
  }
}
