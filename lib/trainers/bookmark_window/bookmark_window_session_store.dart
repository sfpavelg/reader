import '../../app/trainer_ids.dart';
import '../../data/hive/local_storage.dart';
import '../../data/hive/models/trainer_progress.dart';
import 'bookmark_window_generator.dart';
import 'bookmark_window_passage.dart';

class BookmarkWindowProgress {
  const BookmarkWindowProgress({
    required this.msPerFragment,
    required this.levelId,
    required this.fragments,
    required this.fullText,
    required this.fragmentIndex,
    required this.sourceEntryIds,
    this.passageId,
  });

  final int msPerFragment;
  final int levelId;
  final List<String> fragments;
  final String fullText;
  final int fragmentIndex;
  final List<String> sourceEntryIds;
  final String? passageId;

  bool get hasPassage => fragments.isNotEmpty;
  bool get isComplete => hasPassage && fragmentIndex >= fragments.length;

  Map<String, dynamic> toMap() => {
        'msPerFragment': msPerFragment,
        'levelId': levelId,
        'fragments': fragments,
        'fullText': fullText,
        'fragmentIndex': fragmentIndex,
        'sourceEntryIds': sourceEntryIds,
        if (passageId != null) 'passageId': passageId,
      };

  factory BookmarkWindowProgress.fromMap(Map<String, dynamic> map) {
    return BookmarkWindowProgress(
      msPerFragment: map['msPerFragment'] as int? ?? 1400,
      levelId: map['levelId'] as int? ?? 3,
      fragments: (map['fragments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      fullText: map['fullText'] as String? ?? '',
      fragmentIndex: map['fragmentIndex'] as int? ?? 0,
      sourceEntryIds: (map['sourceEntryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      passageId: map['passageId'] as String?,
    );
  }

  BookmarkWindowProgress copyWith({
    int? msPerFragment,
    int? levelId,
    List<String>? fragments,
    String? fullText,
    int? fragmentIndex,
    List<String>? sourceEntryIds,
    String? passageId,
  }) {
    return BookmarkWindowProgress(
      msPerFragment: msPerFragment ?? this.msPerFragment,
      levelId: levelId ?? this.levelId,
      fragments: fragments ?? this.fragments,
      fullText: fullText ?? this.fullText,
      fragmentIndex: fragmentIndex ?? this.fragmentIndex,
      sourceEntryIds: sourceEntryIds ?? this.sourceEntryIds,
      passageId: passageId ?? this.passageId,
    );
  }
}

class BookmarkWindowSessionStore {
  BookmarkWindowSessionStore._();

  static const _trainerId = TrainerIds.bookmarkWindow;

  static BookmarkWindowProgress load(int levelId) {
    final snap = LocalStorage.readMicroSession(_trainerId);
    if (snap == null) return _empty(levelId);
    final p = BookmarkWindowProgress.fromMap(snap.payload);
    if (p.levelId != levelId) return _empty(levelId);
    return p;
  }

  static BookmarkWindowProgress _empty(int levelId) {
    return BookmarkWindowProgress(
      msPerFragment: BookmarkWindowGenerator.defaultMsPerFragment(levelId),
      levelId: levelId,
      fragments: const [],
      fullText: '',
      fragmentIndex: 0,
      sourceEntryIds: const [],
    );
  }

  static Future<void> save(BookmarkWindowProgress progress) async {
    await LocalStorage.writeMicroSession(
      MicroSessionSnapshot(
        trainerId: _trainerId,
        levelId: progress.levelId,
        payload: progress.toMap(),
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static BookmarkWindowProgress applyPassage(
    BookmarkWindowProgress current,
    BookmarkWindowPassage passage,
  ) {
    return current.copyWith(
      fragments: passage.fragments,
      fullText: passage.fullText,
      fragmentIndex: 0,
      sourceEntryIds: passage.sourceEntryIds,
      passageId: passage.passageId,
    );
  }
}
