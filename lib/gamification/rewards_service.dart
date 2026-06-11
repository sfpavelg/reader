import '../data/hive/local_storage.dart';
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

/// Звёзды, питомец и карта миров после успешного раунда.
class RewardsService {
  RewardsService._();

  static const dailyMinuteLimit = 15;

  static Future<RewardGrantResult> grantTrainerSuccess({
    required String trainerId,
    int stars = 1,
  }) async {
    final starsClamped = stars.clamp(1, 3);

    var profile = LocalStorage.readProfile();
    final todayKey = _todayKey();
    final playedToday = _minutesPlayedToday(todayKey);

    if (playedToday >= dailyMinuteLimit) {
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
    pet = pet.feedTrainingMinute();

    profile = profile.copyWith(
      totalStars: profile.totalStars + starsClamped,
      totalTrainingMinutes: profile.totalTrainingMinutes + 1,
    );

    final map = _advanceWorldMap(
      LocalStorage.readWorldMap(),
      trainerId: trainerId,
      stars: starsClamped,
    );

    await LocalStorage.writeProfile(profile);
    await LocalStorage.writePet(pet);
    await LocalStorage.writeWorldMap(map);
    await LocalStorage.writeDailySession(
      DailySessionState(dateKey: todayKey, minutes: playedToday + 1),
    );

    return RewardGrantResult(
      starsEarned: starsClamped,
      totalStars: profile.totalStars,
      pet: pet,
      petStageChanged: pet.stage != petBefore,
      worldNodeUnlocked: true,
      dailyLimitReached: false,
    );
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
      album.unlock(
        themeId: themeId,
        stickerId: stickerId,
        starCost: starCost,
      ),
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
