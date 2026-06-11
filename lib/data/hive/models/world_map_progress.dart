class LevelNodeProgress {
  const LevelNodeProgress({
    required this.nodeId,
    this.stars = 0,
    this.completed = false,
  });

  final String nodeId;
  final int stars;
  final bool completed;

  factory LevelNodeProgress.fromMap(Map<dynamic, dynamic> map) {
    return LevelNodeProgress(
      nodeId: map['nodeId'] as String,
      stars: map['stars'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'nodeId': nodeId,
        'stars': stars,
        'completed': completed,
      };
}

/// Линейная карта миров: мир → узлы-уровни.
class WorldMapProgress {
  const WorldMapProgress({
    this.currentWorldId = 'forest_syllables',
    this.nodesByWorld = const {},
  });

  final String currentWorldId;
  final Map<String, List<LevelNodeProgress>> nodesByWorld;

  LevelNodeProgress? node(String worldId, String nodeId) {
    final nodes = nodesByWorld[worldId];
    if (nodes == null) return null;
    for (final n in nodes) {
      if (n.nodeId == nodeId) return n;
    }
    return null;
  }

  factory WorldMapProgress.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['nodesByWorld'] as Map<dynamic, dynamic>? ?? {};
    final worlds = <String, List<LevelNodeProgress>>{};
    raw.forEach((worldId, nodes) {
      worlds[worldId.toString()] = (nodes as List<dynamic>)
          .map((e) => LevelNodeProgress.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    });
    return WorldMapProgress(
      currentWorldId: map['currentWorldId'] as String? ?? 'forest_syllables',
      nodesByWorld: worlds,
    );
  }

  Map<String, dynamic> toMap() => {
        'currentWorldId': currentWorldId,
        'nodesByWorld': nodesByWorld.map(
          (worldId, nodes) => MapEntry(
            worldId,
            nodes.map((n) => n.toMap()).toList(),
          ),
        ),
      };
}
