import '../../app/trainer_ids.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';
import 'rsvp_generator.dart';
import 'rsvp_passage.dart';

class RsvpTrainerProgress {
  const RsvpTrainerProgress({
    required this.wpm,
    required this.levelId,
    required this.words,
    required this.wordIndex,
    required this.sourceEntryIds,
    this.passageId,
  });

  final int wpm;
  final int levelId;
  final List<String> words;
  final int wordIndex;
  final List<String> sourceEntryIds;
  final String? passageId;

  bool get hasPassage => words.isNotEmpty;
  bool get isComplete => hasPassage && wordIndex >= words.length;

  Map<String, dynamic> toMap() => {
        'wpm': wpm,
        'levelId': levelId,
        'words': words,
        'wordIndex': wordIndex,
        'sourceEntryIds': sourceEntryIds,
        if (passageId != null) 'passageId': passageId,
      };

  factory RsvpTrainerProgress.fromMap(Map<String, dynamic> map) {
    return RsvpTrainerProgress(
      wpm: map['wpm'] as int? ?? 60,
      levelId: map['levelId'] as int? ?? 1,
      words: (map['words'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      wordIndex: map['wordIndex'] as int? ?? 0,
      sourceEntryIds: (map['sourceEntryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      passageId: map['passageId'] as String?,
    );
  }

  RsvpTrainerProgress copyWith({
    int? wpm,
    int? levelId,
    List<String>? words,
    int? wordIndex,
    List<String>? sourceEntryIds,
    String? passageId,
  }) {
    return RsvpTrainerProgress(
      wpm: wpm ?? this.wpm,
      levelId: levelId ?? this.levelId,
      words: words ?? this.words,
      wordIndex: wordIndex ?? this.wordIndex,
      sourceEntryIds: sourceEntryIds ?? this.sourceEntryIds,
      passageId: passageId ?? this.passageId,
    );
  }
}

class RsvpSessionStore {
  RsvpSessionStore._();

  static const _trainerId = TrainerIds.rsvp;

  static RsvpTrainerProgress load(int levelId) {
    final snap = LocalStorage.readMicroSession(_trainerId);
    if (snap == null) {
      return _empty(levelId);
    }

    final p = RsvpTrainerProgress.fromMap(snap.payload);
    if (p.levelId != levelId) {
      return _empty(levelId);
    }
    return p;
  }

  static RsvpTrainerProgress _empty(int levelId) {
    return RsvpTrainerProgress(
      wpm: RsvpGenerator.defaultWpmForLevel(levelId),
      levelId: levelId,
      words: const [],
      wordIndex: 0,
      sourceEntryIds: const [],
    );
  }

  static Future<void> save(RsvpTrainerProgress progress) async {
    await LocalStorage.writeMicroSession(
      MicroSessionSnapshot(
        trainerId: _trainerId,
        levelId: progress.levelId,
        payload: progress.toMap(),
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final existing = LocalStorage.readTrainerProgress(_trainerId);
    await LocalStorage.writeTrainerProgress(
      (existing ?? const TrainerProgress(trainerId: _trainerId)).copyWith(
        lastPlayedAtMs: DateTime.now().millisecondsSinceEpoch,
        totalTasks: progress.wordIndex,
      ),
    );
  }

  static RsvpTrainerProgress applyPassage(
    RsvpTrainerProgress current,
    RsvpPassage passage,
  ) {
    return current.copyWith(
      words: passage.words,
      wordIndex: 0,
      sourceEntryIds: passage.sourceEntryIds,
      passageId: passage.passageId,
    );
  }
}
