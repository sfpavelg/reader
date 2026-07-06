import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/world_map_progress.dart';
import '../gamification/world_map_catalog.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/stars_balance_chip.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TrainerStarsMixin {
  late WorldMapProgress _map;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    _map = LocalStorage.readWorldMap();
  }

  List<LevelNodeProgress> _nodesFor(WorldInfo world) {
    return _map.nodesByWorld[world.id] ??
        List.generate(
          world.nodeCount,
          (i) => LevelNodeProgress(nodeId: 'node_$i'),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Карта миров')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TrainerStarsBar(stars: trainerStars),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: WorldMapCatalog.worlds.length,
              itemBuilder: (context, index) {
                final world = WorldMapCatalog.worlds[index];
                final nodes = _nodesFor(world);
                final done = nodes.where((n) => n.completed).length;
                final allDone = done == world.nodeCount;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              world.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                world.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (allDone)
                              Icon(Icons.check_circle, color: colors.primary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Пройдено: $done / ${world.nodeCount}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (var i = 0; i < nodes.length; i++) ...[
                              if (i > 0)
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: nodes[i - 1].completed
                                          ? colors.primary
                                          : colors.outlineVariant,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: nodes[i].completed
                                    ? colors.primaryContainer
                                    : colors.surfaceContainerHighest,
                                child: Text(
                                  nodes[i].completed ? '⭐' : '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: nodes[i].completed
                                        ? colors.onPrimaryContainer
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
