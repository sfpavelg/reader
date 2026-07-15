import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/tetris_dictionary_service.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/syllable_tap_target.dart';
import '../../trainers/tetris/tetris_board.dart';

class TetrisSyllableScreen extends ConsumerStatefulWidget {
  const TetrisSyllableScreen({super.key});

  @override
  ConsumerState<TetrisSyllableScreen> createState() => _TetrisSyllableScreenState();
}

class _TetrisSyllableScreenState extends ConsumerState<TetrisSyllableScreen> {
  static const _cols = 6;
  static const _rows = 10;
  static const _gap = 4.0;

  final _service = TetrisDictionaryService();

  bool _loading = true;
  bool _gameOver = false;
  late TetrisBoard _board;
  TetrisBlockEntry? _current;
  String _lastWord = '—';
  int _score = 0;
  int _selectedCol = 2;

  @override
  void initState() {
    super.initState();
    _board = TetrisBoard(cols: _cols, rows: _rows);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.initialize();
    setState(() {
      _current = _service.pickWeightedBlock();
      _loading = false;
    });
  }

  Future<void> _dropCurrent() async {
    if (_loading || _gameOver || _current == null) return;
    final placed = _board.placeInColumn(_selectedCol, _current!.text);
    if (placed < 0) {
      await AppFeedback.softHint();
      return;
    }
    await AppFeedback.tap();

    var anyWord = false;
    while (true) {
      final matches = _board.findAllMatches(_service.wordsIndex);
      if (matches.isEmpty) break;
      anyWord = true;
      _lastWord = matches.first.word.text;
      _score += matches.length;
      _board.clearMatches(matches);
      _board.applyGravity();
      await AppFeedback.success();
    }

    if (!anyWord) {
      await AppFeedback.tap();
    }

    setState(() {
      _current = _service.pickWeightedBlock();
      _gameOver = _board.isFull;
    });
  }

  void _restart() {
    setState(() {
      _board = TetrisBoard(cols: _cols, rows: _rows);
      _current = _service.pickWeightedBlock();
      _lastWord = '—';
      _score = 0;
      _selectedCol = 2;
      _gameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Слог-тетрис (MVP)'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _restart,
            tooltip: 'Заново',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  children: [
                    _TopHud(
                      current: _current?.text ?? '--',
                      lastWord: _lastWord,
                      score: _score,
                      gameOver: _gameOver,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: Row(
                        children: [
                          for (var c = 0; c < _cols; c++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: OutlinedButton(
                                  onPressed: _gameOver
                                      ? null
                                      : () => setState(() => _selectedCol = c),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedCol == c
                                        ? colors.primaryContainer
                                        : null,
                                  ),
                                  child: Text('${c + 1}'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSide = _cellSide(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return Center(
                            child: SizedBox(
                              width: cellSide * _cols + _gap * (_cols - 1),
                              height: cellSide * _rows + _gap * (_rows - 1),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _cols,
                                  mainAxisSpacing: _gap,
                                  crossAxisSpacing: _gap,
                                ),
                                itemCount: _cols * _rows,
                                itemBuilder: (context, index) {
                                  final value = _board.cellAt(index);
                                  final fill = value == null;
                                  return Material(
                                    color: fill
                                        ? colors.surfaceContainerLowest
                                        : colors.surfaceContainerHigh,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                    child: SyllableTapTarget(
                                      enabled: false,
                                      onActivated: () {},
                                      borderRadius: BorderRadius.circular(8),
                                      child: Center(
                                        child: Text(
                                          value ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: cellSide * 0.42,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _gameOver ? null : () => unawaited(_dropCurrent()),
                      icon: const Icon(Icons.arrow_downward),
                      label: Text(
                        _gameOver ? 'Поле заполнено' : 'Бросить в колонку ${_selectedCol + 1}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  double _cellSide(double width, double height) {
    final byWidth = (width - _gap * (_cols - 1)) / _cols;
    final byHeight = (height - _gap * (_rows - 1)) / _rows;
    return byWidth < byHeight ? byWidth : byHeight;
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.current,
    required this.lastWord,
    required this.score,
    required this.gameOver,
  });

  final String current;
  final String lastWord;
  final int score;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Текущий блок: $current')),
          Expanded(child: Text('Слово: $lastWord')),
          Text('Счёт: $score${gameOver ? " • Конец" : ""}'),
        ],
      ),
    );
  }
}
