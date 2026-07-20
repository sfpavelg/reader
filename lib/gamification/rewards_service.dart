import '../characters/pets/pet_catalog.dart';
import '../data/hive/local_storage.dart';
import '../data/hive/models/app_settings.dart';
import '../data/hive/models/daily_session.dart';
import '../data/hive/models/pet_state.dart';
import '../data/hive/models/world_map_progress.dart';
import 'sticker_catalog.dart';
import 'world_map_catalog.dart';

class RewardGrantResult {
  const RewardGrantResult({
    required this.starsEarned,
    required this.totalStars,
    required this.pet,
    required this.petStageChanged,
    required this.worldNodeUnlocked,
    required this.dailyLimitReached,
  });

  final int starsEarned;
  final int totalStars;
  final PetState pet;
  final bool petStageChanged;
  final bool worldNodeUnlocked;
  final bool dailyLimitReached;
}

class RewardPenaltyResult {
  const RewardPenaltyResult({
    required this.starsLost,
    required this.totalStars,
  });

  final int starsLost;
  final int totalStars;
}

/// Звёзды, питомец и карта миров после успешного раунда.
class RewardsService {
  RewardsService._();

  static const defaultDailyMinuteLimit = AppSettings.defaultDailyTrainingMinuteLimit;
  /// Временно отключено — карта миров дорабатывается отдельно.
  static const enableWorldMapSteps = false;
  /// Рост питомца не привязан к тренировкам — звёзды ребёнок тратит сам.
  static const enableAutomaticPetGrowth = false;

  static int dailyMinuteLimit() {
    if (!LocalStorage.isReady) return defaultDailyMinuteLimit;
    return LocalStorage.readSettings().clampedDailyTrainingMinuteLimit;
  }

  static bool isDailyTrainingLimitEnabled() {
    if (!LocalStorage.isReady) return true;
    return LocalStorage.readSettings().dailyTrainingLimitEnabled;
  }

  static bool isDailyLimitReached(int playedToday) {
    if (!isDailyTrainingLimitEnabled()) return false;
    return playedToday >= dailyMinuteLimit();
  }

  static String dailyMinutesStatus(int playedToday) {
    if (!isDailyTrainingLimitEnabled()) {
      return 'Сегодня: $playedToday мин (без лимита)';
    }
    return 'Сегодня: $playedToday / ${dailyMinuteLimit()} мин';
  }

  static Future<RewardGrantResult> grantTrainerSuccess({
    required String trainerId,
    int stars = 1,
  }) async {
    final starsClamped = stars.clamp(1, 3);

    var profile = LocalStorage.readProfile();
    final todayKey = _todayKey();
    final playedToday = _minutesPlayedToday(todayKey);

    if (RewardsService.isDailyLimitReached(playedToday)) {
      return RewardGrantResult(
        starsEarned: 0,
        totalStars: profile.totalStars,
        pet: LocalStorage.readPet(),
        petStageChanged: false,
        worldNodeUnlocked: false,
        dailyLimitReached: true,
      );
    }

    var pet = LocalStorage.readPet();
    final petBefore = pet.stage;
    if (enableAutomaticPetGrowth) {
      pet = pet.feedTrainingMinute();
    }

    profile = profile.copyWith(
      totalStars: profile.totalStars + starsClamped,
      totalTrainingMinutes: profile.totalTrainingMinutes + 1,
    );

    final map = enableWorldMapSteps
        ? _advanceWorldMap(
            LocalStorage.readWorldMap(),
            trainerId: trainerId,
            stars: starsClamped,
          )
        : LocalStorage.readWorldMap();

    await LocalStorage.writeProfile(profile);
    if (enableAutomaticPetGrowth) {
      await LocalStorage.writePet(pet);
    }
    if (enableWorldMapSteps) {
      await LocalStorage.writeWorldMap(map);
    }
    await LocalStorage.writeDailySession(
      DailySessionState(dateKey: todayKey, minutes: playedToday + 1),
    );

    return RewardGrantResult(
      starsEarned: starsClamped,
      totalStars: profile.totalStars,
      pet: pet,
      petStageChanged: enableAutomaticPetGrowth && pet.stage != petBefore,
      worldNodeUnlocked: enableWorldMapSteps,
      dailyLimitReached: false,
    );
  }

  static Future<RewardPenaltyResult> penalizeTrainerFailure({
    int stars = 1,
  }) async {
    final starsClamped = stars.clamp(1, 3);
    final profile = LocalStorage.readProfile();
    final starsLost = starsClamped.clamp(0, profile.totalStars);
    final updated = profile.copyWith(
      totalStars: profile.totalStars - starsLost,
    );

    await LocalStorage.writeProfile(updated);

    return RewardPenaltyResult(
      starsLost: starsLost,
      totalStars: updated.totalStars,
    );
  }

  static Future<bool> unlockPetLevel({
    int starCost = PetState.starCostPerLevel,
    PetId? petId,
  }) async {
    if (!LocalStorage.isReady) return false;
    final pet = LocalStorage.readPet();
    final id = (petId ?? petIdFromString(pet.activePetId)).name;
    if (!pet.canUnlockNextForId(id)) return false;

    final profile = LocalStorage.readProfile();
    if (profile.totalStars < starCost) return false;

    await LocalStorage.writeProfile(
      profile.copyWith(totalStars: profile.totalStars - starCost),
    );
    await LocalStorage.writePet(pet.unlockNextLevel(petId: id));
    return true;
  }

  static Future<bool> unlockColoringPage({
    required String pageId,
    int starCost = 10,
  }) async {
    if (!LocalStorage.isReady) return false;
    final progress = LocalStorage.readColoringProgress();
    if (progress.isUnlocked(pageId)) return true;

    final profile = LocalStorage.readProfile();
    if (profile.totalStars < starCost) return false;

    await LocalStorage.writeProfile(
      profile.copyWith(totalStars: profile.totalStars - starCost),
    );
    await LocalStorage.writeColoringProgress(progress.unlock(pageId));
    return true;
  }

  static Future<bool> unlockSticker({
    required String themeId,
    required String stickerId,
    required int starCost,
  }) async {
    final profile = LocalStorage.readProfile();
    if (profile.totalStars < starCost) return false;

    final album = LocalStorage.readStickerAlbum();
    if (album.isUnlocked(themeId, stickerId)) return true;

    await LocalStorage.writeProfile(
      profile.copyWith(totalStars: profile.totalStars - starCost),
    );
    await LocalStorage.writeStickerAlbum(
      album.unlock(themeId: themeId, stickerId: stickerId, starCost: starCost),
    );
    return true;
  }

  static Future<bool> unlockFairytaleChapter({
    required String chapterId,
    required int starCost,
  }) async {
    final profile = LocalStorage.readProfile();
    if (profile.totalStars < starCost) return false;

    final progress = LocalStorage.readFairytaleProgress();
    if (progress.isChapterUnlocked(chapterId)) return true;

    await LocalStorage.writeProfile(
      profile.copyWith(totalStars: profile.totalStars - starCost),
    );
    await LocalStorage.writeFairytaleProgress(
      progress.unlockChapter(chapterId: chapterId, starCost: starCost),
    );
    return true;
  }

  static int availableStars() => LocalStorage.readProfile().totalStars;

  static int minutesPlayedToday() {
    return _minutesPlayedToday(_todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static int _minutesPlayedToday(String todayKey) {
    final box = LocalStorage.readDailySession();
    if (box.dateKey != todayKey) return 0;
    return box.minutes;
  }

  static WorldMapProgress _advanceWorldMap(
    WorldMapProgress map, {
    required String trainerId,
    required int stars,
  }) {
    final world = WorldMapCatalog.worldForTrainer(trainerId);
    if (world == null) return map;

    final existing = List<LevelNodeProgress>.from(
      map.nodesByWorld[world.id] ?? _defaultNodes(world),
    );

    final nextIndex = existing.indexWhere((n) => !n.completed);
    if (nextIndex >= 0) {
      existing[nextIndex] = LevelNodeProgress(
        nodeId: 'node_$nextIndex',
        stars: stars,
        completed: true,
      );
    }

    return WorldMapProgress(
      currentWorldId: world.id,
      nodesByWorld: {...map.nodesByWorld, world.id: existing},
    );
  }

  static List<LevelNodeProgress> _defaultNodes(WorldInfo world) {
    return List.generate(
      world.nodeCount,
      (i) => LevelNodeProgress(nodeId: 'node_$i'),
    );
  }

  static StickerDef? findSticker(String themeId, String stickerId) {
    for (final theme in StickerCatalog.themes) {
      if (theme.id != themeId) continue;
      for (final s in theme.stickers) {
        if (s.id == stickerId) return s;
      }
    }
    return null;
  }
}
