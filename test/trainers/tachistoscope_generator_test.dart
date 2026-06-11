import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/tachistoscope/tachistoscope_generator.dart';
import 'package:reader/trainers/tachistoscope/tachistoscope_session_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late TachistoscopeGenerator generator;

  setUp(() async {
    final random = Random(42);
    dictionary = DictionaryService(random: random);
    await dictionary.initialize();
    generator = TachistoscopeGenerator(
      dictionary: dictionary,
      random: random,
    );
  });

  test('generates 3 unique options with one correct answer', () {
    final session = const TachistoscopeSessionState();
    final task = generator.generate(levelId: 1, session: session);

    expect(task.options, hasLength(3));
    expect(task.correctIndex, greaterThanOrEqualTo(0));
    expect(task.correctIndex, lessThan(3));
    expect(
      task.options[task.correctIndex].entryId,
      task.target.id,
    );
    expect(
      task.options.map((o) => o.entryId).toSet(),
      hasLength(3),
    );
  });

  test('flash duration starts at 2 seconds', () {
    final task = generator.generate(
      levelId: 2,
      session: const TachistoscopeSessionState(),
    );
    expect(task.flashDuration.inMilliseconds, 2000);
  });

  test('adaptive session speeds up after 3 correct answers', () {
    var session = const TachistoscopeSessionState();
    session = session.registerAnswer(isCorrect: true);
    session = session.registerAnswer(isCorrect: true);
    session = session.registerAnswer(isCorrect: true);

    expect(session.flashDurationMs, 1800);
    expect(session.correctStreak, 0);
  });

  test('adaptive session slows down on mistake', () {
    var session = const TachistoscopeSessionState(flashDurationMs: 1200);
    session = session.registerAnswer(isCorrect: false);

    expect(session.flashDurationMs, 1400);
    expect(session.correctStreak, 0);
  });

  test('flash duration is clamped between 0.5s and 2s', () {
    var session = const TachistoscopeSessionState(flashDurationMs: 600);
    for (var i = 0; i < 5; i++) {
      session = session.registerAnswer(isCorrect: true);
      session = session.registerAnswer(isCorrect: true);
      session = session.registerAnswer(isCorrect: true);
    }
    expect(session.flashDurationMs, greaterThanOrEqualTo(500));

    session = const TachistoscopeSessionState(flashDurationMs: 1900);
    session = session.registerAnswer(isCorrect: false);
    expect(session.flashDurationMs, lessThanOrEqualTo(2000));
  });
}
