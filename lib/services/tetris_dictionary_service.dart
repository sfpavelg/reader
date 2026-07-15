import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class TetrisBlockEntry {
  const TetrisBlockEntry({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.weight,
    required this.tags,
  });

  final String id;
  final String text;
  final int difficulty;
  final int weight;
  final List<String> tags;

  factory TetrisBlockEntry.fromJson(Map<String, dynamic> json) {
    return TetrisBlockEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      tags: ((json['tags'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class TetrisWordEntry {
  const TetrisWordEntry({
    required this.id,
    required this.text,
    required this.parts,
    required this.difficulty,
    required this.category,
  });

  final String id;
  final String text;
  final List<String> parts;
  final int difficulty;
  final String category;

  factory TetrisWordEntry.fromJson(Map<String, dynamic> json) {
    return TetrisWordEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      parts: ((json['parts'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      category: (json['category'] as String?) ?? 'other',
    );
  }
}

class TetrisDictionaryService {
  TetrisDictionaryService({Random? random}) : _random = random ?? Random();

  static const _manifestPath = 'assets/tetris_dictionary/manifest.json';
  static const _prefix = 'assets/tetris_dictionary/';

  final Random _random;

  bool _initialized = false;
  List<TetrisBlockEntry> _blocks = const [];
  List<TetrisWordEntry> _words = const [];
  List<_WeightedBlock> _weighted = const [];
  int _totalWeight = 0;
  Map<int, Map<String, List<TetrisWordEntry>>> _wordsByLengthAndKey = const {};

  Future<void> initialize() async {
    if (_initialized) return;

    final manifestRaw = await rootBundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final files = manifest['files'] as Map<String, dynamic>;

    final blocksRaw = await rootBundle.loadString('$_prefix${files['blocks']}');
    final wordsRaw = await rootBundle.loadString('$_prefix${files['words']}');

    final blocksJson = jsonDecode(blocksRaw) as Map<String, dynamic>;
    final wordsJson = jsonDecode(wordsRaw) as Map<String, dynamic>;

    _blocks = ((blocksJson['entries'] as List<dynamic>?) ?? const [])
        .map((e) => TetrisBlockEntry.fromJson(e as Map<String, dynamic>))
        .where((b) => b.text.length == 2)
        .toList();
    _words = ((wordsJson['entries'] as List<dynamic>?) ?? const [])
        .map((e) => TetrisWordEntry.fromJson(e as Map<String, dynamic>))
        .where((w) => w.parts.isNotEmpty && w.parts.every((p) => p.length == 2))
        .toList();

    _weighted = _blocks
        .map((b) => _WeightedBlock(block: b, cumulativeWeight: 0))
        .toList();
    var acc = 0;
    for (var i = 0; i < _weighted.length; i++) {
      acc += _weighted[i].block.weight <= 0 ? 1 : _weighted[i].block.weight;
      _weighted[i] = _WeightedBlock(block: _weighted[i].block, cumulativeWeight: acc);
    }
    _totalWeight = acc;

    final byLength = <int, Map<String, List<TetrisWordEntry>>>{};
    for (final word in _words) {
      final key = word.parts.join('|');
      final bucket = byLength.putIfAbsent(word.parts.length, () => {});
      bucket.putIfAbsent(key, () => []).add(word);
    }
    _wordsByLengthAndKey = byLength;

    _initialized = true;
  }

  List<TetrisBlockEntry> get blocks => List.unmodifiable(_blocks);
  List<TetrisWordEntry> get words => List.unmodifiable(_words);
  Map<int, Map<String, List<TetrisWordEntry>>> get wordsIndex => _wordsByLengthAndKey;

  TetrisBlockEntry pickWeightedBlock() {
    if (_weighted.isEmpty || _totalWeight <= 0) {
      throw StateError('TetrisDictionaryService.initialize() must be called first');
    }
    final target = _random.nextInt(_totalWeight) + 1;
    for (final item in _weighted) {
      if (target <= item.cumulativeWeight) return item.block;
    }
    return _weighted.last.block;
  }
}

class _WeightedBlock {
  const _WeightedBlock({
    required this.block,
    required this.cumulativeWeight,
  });

  final TetrisBlockEntry block;
  final int cumulativeWeight;
}
