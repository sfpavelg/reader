import 'package:flutter_test/flutter_test.dart';
import 'package:reader/app/trainer_ids.dart';
import 'package:reader/gamification/sticker_catalog.dart';
import 'package:reader/gamification/world_map_catalog.dart';

void main() {
  test('each trainer has a world on the map', () {
    const trainerIds = [
      TrainerIds.schulte,
      TrainerIds.tachistoscope,
      TrainerIds.rsvp,
      TrainerIds.syllableBuilder,
      TrainerIds.bookmarkWindow,
    ];

    for (final id in trainerIds) {
      expect(WorldMapCatalog.worldForTrainer(id), isNotNull);
    }
  });

  test('sticker themes have unique ids', () {
    final ids = StickerCatalog.themes.map((t) => t.id).toSet();
    expect(ids.length, StickerCatalog.themes.length);
  });
}
