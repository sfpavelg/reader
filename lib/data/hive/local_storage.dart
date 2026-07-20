import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'models/app_settings.dart';
import 'models/pet_state.dart';
import 'models/coloring_progress.dart';
import 'models/fairytale_progress.dart';
import 'models/sticker_album.dart';
import 'models/trainer_progress.dart';
import 'models/user_profile.dart';
import 'models/world_map_progress.dart';
import 'models/daily_session.dart';

/// Тонкая обёртка над Hive: Map JSON без codegen, быстро на слабых CPU.
class LocalStorage {
  LocalStorage._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize({String? testPath}) async {
    if (_ready) return;
    if (testPath != null) {
      Hive.init(testPath);
    } else {
      await Hive.initFlutter();
    }
    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.profile),
      Hive.openBox(HiveBoxes.trainers),
      Hive.openBox(HiveBoxes.pet),
      Hive.openBox(HiveBoxes.stickers),
      Hive.openBox(HiveBoxes.worldMap),
      Hive.openBox(HiveBoxes.sessions),
    ]);
    _ready = true;
  }

  static Box _box(String name) {
    if (!_ready) {
      throw StateError('LocalStorage.initialize() must be called first');
    }
    return Hive.box(name);
  }

  static AppSettings readSettings() {
    final raw = _box(HiveBoxes.settings).get(HiveKeys.appSettings);
    if (raw is Map) return AppSettings.fromMap(raw);
    return const AppSettings();
  }

  static Future<void> writeSettings(AppSettings settings) async {
    await _box(HiveBoxes.settings)
        .put(HiveKeys.appSettings, settings.toMap());
  }

  static UserProfile readProfile() {
    final raw = _box(HiveBoxes.profile).get(HiveKeys.userProfile);
    if (raw is Map) return UserProfile.fromMap(raw);
    return UserProfile.defaults();
  }

  static Future<void> writeProfile(UserProfile profile) async {
    await _box(HiveBoxes.profile).put(HiveKeys.userProfile, profile.toMap());
  }

  static PetState readPet() {
    final raw = _box(HiveBoxes.pet).get(HiveKeys.petState);
    if (raw is Map) return PetState.fromMap(raw);
    return const PetState();
  }

  static Future<void> writePet(PetState pet) async {
    await _box(HiveBoxes.pet).put(HiveKeys.petState, pet.toMap());
  }

  static StickerAlbumState readStickerAlbum() {
    final raw = _box(HiveBoxes.stickers).get(HiveKeys.stickerAlbum);
    if (raw is Map) return StickerAlbumState.fromMap(raw);
    return const StickerAlbumState();
  }

  static Future<void> writeStickerAlbum(StickerAlbumState album) async {
    await _box(HiveBoxes.stickers).put(HiveKeys.stickerAlbum, album.toMap());
  }

  static FairytaleProgress readFairytaleProgress() {
    final raw = _box(HiveBoxes.stickers).get(HiveKeys.fairytaleProgress);
    if (raw is Map) return FairytaleProgress.fromMap(raw);
    return const FairytaleProgress();
  }

  static Future<void> writeFairytaleProgress(FairytaleProgress progress) async {
    await _box(HiveBoxes.stickers)
        .put(HiveKeys.fairytaleProgress, progress.toMap());
  }

  static ColoringProgress readColoringProgress() {
    final raw = _box(HiveBoxes.stickers).get(HiveKeys.coloringProgress);
    if (raw is Map) return ColoringProgress.fromMap(raw);
    return const ColoringProgress();
  }

  static Future<void> writeColoringProgress(ColoringProgress progress) async {
    await _box(HiveBoxes.stickers)
        .put(HiveKeys.coloringProgress, progress.toMap());
  }

  static WorldMapProgress readWorldMap() {
    final raw = _box(HiveBoxes.worldMap).get(HiveKeys.worldMapProgress);
    if (raw is Map) return WorldMapProgress.fromMap(raw);
    return const WorldMapProgress();
  }

  static Future<void> writeWorldMap(WorldMapProgress progress) async {
    await _box(HiveBoxes.worldMap)
        .put(HiveKeys.worldMapProgress, progress.toMap());
  }

  static TrainerProgress? readTrainerProgress(String trainerId) {
    final raw =
        _box(HiveBoxes.trainers).get(HiveKeys.trainerProgress(trainerId));
    if (raw is Map) return TrainerProgress.fromMap(raw);
    return null;
  }

  static Future<void> writeTrainerProgress(TrainerProgress progress) async {
    await _box(HiveBoxes.trainers).put(
      HiveKeys.trainerProgress(progress.trainerId),
      progress.toMap(),
    );
  }

  static MicroSessionSnapshot? readMicroSession(String trainerId) {
    final raw = _box(HiveBoxes.sessions).get(HiveKeys.microSession(trainerId));
    if (raw is Map) return MicroSessionSnapshot.fromMap(raw);
    return null;
  }

  static Future<void> writeMicroSession(MicroSessionSnapshot snapshot) async {
    await _box(HiveBoxes.sessions).put(
      HiveKeys.microSession(snapshot.trainerId),
      snapshot.toMap(),
    );
  }

  static Future<void> clearMicroSession(String trainerId) async {
    await _box(HiveBoxes.sessions).delete(HiveKeys.microSession(trainerId));
  }

  static Map<String, dynamic>? readTrainerExtra(String key) {
    final raw = _box(HiveBoxes.sessions).get(HiveKeys.trainerExtra(key));
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<void> writeTrainerExtra(
    String key,
    Map<String, dynamic> payload,
  ) async {
    await _box(HiveBoxes.sessions).put(HiveKeys.trainerExtra(key), payload);
  }

  static DailySessionState readDailySession() {
    final raw = _box(HiveBoxes.settings).get(HiveKeys.dailySession);
    if (raw is Map) return DailySessionState.fromMap(raw);
    return const DailySessionState(dateKey: '', minutes: 0);
  }

  static Future<void> writeDailySession(DailySessionState state) async {
    await _box(HiveBoxes.settings).put(HiveKeys.dailySession, state.toMap());
  }
}
