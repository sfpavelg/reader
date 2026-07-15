import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/schulte/schulte_spellable_words.dart';
import 'package:reader/trainers/schulte/schulte_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    dictionary = DictionaryService(random: Random(1));
    await dictionary.initialize();
  });

  test('canSpell respects syllable order and cell reuse', () {
    const grid = ['РЕ', 'КА', 'ДА', 'МА', 'ДО'];
    expect(SchulteSpellableWords.canSpell(grid, ['РЕ', 'КА']), isTrue);
    expect(SchulteSpellableWords.canSpell(grid, ['ДА', 'МА']), isTrue);
    expect(SchulteSpellableWords.canSpell(grid, ['МА', 'МА']), isFalse);
  });

  test('findForGrid includes all dictionary words spellable from grid', () {
    const grid = ['КА', 'ДА', 'ДО', 'РЕ', 'МО', 'БА', 'ПА', 'НО', 'МА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    final texts = words.map((w) => w.text).toSet();

    expect(texts, contains('РЕКА'));
    expect(texts, contains('ДАМА'));
    expect(SchulteSpellableWords.matchPicked(words, ['ДА', 'МА'])?.text, 'ДАМА');
    expect(SchulteSpellableWords.matchPicked(words, ['РЕ', 'КА'])?.text, 'РЕКА');
  });

  test('matchPicked requires exact syllable sequence', () {
    const grid = ['РЕ', 'КА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    expect(SchulteSpellableWords.matchPicked(words, ['РЕ', 'КА'])?.text, 'РЕКА');
    expect(SchulteSpellableWords.matchPicked(words, ['КА', 'РЕ']), isNull);
  });

  test('single syllable picks are not accepted', () {
    const grid = ['ПА', 'ША', 'ДА', 'НО', 'БО', 'ЧА', 'ДО', 'ЩА', 'ПА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );

    expect(words.every((w) => w.syllables.length >= 2), isTrue);
    expect(SchulteSpellableWords.matchPicked(words, ['ПА']), isNull);
    expect(SchulteSpellableWords.matchPicked(words, ['ША']), isNull);
    expect(
      SchulteSpellableWords.matchPicked(words, ['ДА', 'ША'])?.text,
      'ДАША',
    );
  });

  test('golova grid accepts zhalo and golova', () {
    const grid = ['ВА', 'МА', 'ЩА', 'ЖА', 'ЛА', 'ЛО', 'ПА', 'ГО', 'БА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    final texts = words.map((w) => w.text).toSet();

    expect(texts, contains('ГОЛОВА'));
    expect(texts, contains('ЖАЛО'));
    expect(texts, contains('ЛАПА'));
    expect(texts, contains('ЖАБА'));
    expect(SchulteSpellableWords.matchPicked(words, ['ЖА', 'ЛО'])?.text, 'ЖАЛО');
    expect(
      SchulteSpellableWords.matchPicked(words, ['ГО', 'ЛО', 'ВА'])?.text,
      'ГОЛОВА',
    );
  });

  test('panama grid accepts panama from supplemental index', () {
    const grid = ['ПА', 'НА', 'МА', 'ДА', 'РО', 'КО', 'ЛА', 'БА', 'ЖА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    final texts = words.map((w) => w.text).toSet();

    expect(texts, contains('ПАНАМА'));
    expect(
      SchulteSpellableWords.matchPicked(words, ['ПА', 'НА', 'МА'])?.text,
      'ПАНАМА',
    );
  });

  test('more grid accepts more from supplemental index', () {
    const grid = ['МО', 'РЕ', 'ДА', 'КО', 'ЛА', 'БА', 'НА', 'ГО', 'ВА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );

    expect(
      SchulteSpellableWords.matchPicked(words, ['МО', 'РЕ'])?.text,
      'МОРЕ',
    );
  });

  test('remainingSpellableCount excludes collected words', () {
    const grid = ['ПА', 'БА', 'РЕ', 'ВО', 'МО', 'ЩА', 'РА', 'РО', 'ВА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    final task = SchulteTask(
      taskId: 'test',
      entryId: 'roba',
      word: 'РОБА',
      syllables: const ['РО', 'БА'],
      gridSize: 3,
      cells: [
        for (var i = 0; i < grid.length; i++)
          SchulteCell(gridIndex: i, text: grid[i]),
      ],
      spellableWords: words,
    );

    expect(task.remainingSpellableCount({}), greaterThan(0));
    final discoverableWords = words
        .where((w) => w.syllables.length >= 2)
        .where((w) => w.text != task.word)
        .length;
    expect(task.remainingSpellableCount({}), discoverableWords);
    expect(task.remainingSpellableCount({'РОБА'}), discoverableWords);
    expect(
      task.remainingSpellableCount({'МОРЕ'}),
      discoverableWords - 1,
    );
    expect(
      task.remainingSpellableCount({'РОБА', 'МОРЕ'}),
      discoverableWords - 1,
    );
  });

  test('remainingSpellableCount excludes hint word even if not collected', () {
    const grid = ['БА', 'БА', 'ЖА', 'ЗА', 'НА', 'ЛО', 'РО', 'РЕ', 'ГА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );
    const hint = 'РОБА';
    final task = SchulteTask(
      taskId: 'test',
      entryId: 'roba',
      word: hint,
      syllables: const ['РО', 'БА'],
      gridSize: 3,
      cells: [
        for (var i = 0; i < grid.length; i++)
          SchulteCell(gridIndex: i, text: grid[i]),
      ],
      spellableWords: words,
    );

    final withoutHint =
        words.where((w) => w.syllables.length >= 2 && w.text != hint).length;

    expect(withoutHint, 8);
    expect(task.remainingSpellableCount({}), withoutHint);
    expect(
      task.remainingSpellableCount({
        'БАБА',
        'БАЗА',
        'ЖАБА',
        'ЖАЛО',
        'ЛОЖА',
        'ЛОЗА',
        'РОГА',
        'РОЗА',
      }),
      0,
    );
    expect(task.remainingSpellableCount({hint}), withoutHint);
  });
}
