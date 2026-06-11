import '../app/trainer_ids.dart';

class WorldInfo {
  const WorldInfo({
    required this.id,
    required this.title,
    required this.trainerId,
    required this.nodeCount,
    required this.icon,
  });

  final String id;
  final String title;
  final String trainerId;
  final int nodeCount;
  final String icon;
}

abstract final class WorldMapCatalog {
  static const nodeCount = 5;

  static const worlds = <WorldInfo>[
    WorldInfo(
      id: 'forest_syllables',
      title: 'Лес слогов',
      trainerId: TrainerIds.schulte,
      nodeCount: nodeCount,
      icon: '🌲',
    ),
    WorldInfo(
      id: 'city_words',
      title: 'Город слов',
      trainerId: TrainerIds.tachistoscope,
      nodeCount: nodeCount,
      icon: '🏙',
    ),
    WorldInfo(
      id: 'city_flow',
      title: 'Ритм чтения',
      trainerId: TrainerIds.rsvp,
      nodeCount: nodeCount,
      icon: '📖',
    ),
    WorldInfo(
      id: 'syllable_park',
      title: 'Парк слогов',
      trainerId: TrainerIds.syllableBuilder,
      nodeCount: nodeCount,
      icon: '🧩',
    ),
    WorldInfo(
      id: 'space_sentences',
      title: 'Космос фраз',
      trainerId: TrainerIds.bookmarkWindow,
      nodeCount: nodeCount,
      icon: '🚀',
    ),
  ];

  static WorldInfo? worldForTrainer(String trainerId) {
    for (final w in worlds) {
      if (w.trainerId == trainerId) return w;
    }
    return null;
  }

  static WorldInfo? worldById(String id) {
    for (final w in worlds) {
      if (w.id == id) return w;
    }
    return null;
  }
}
