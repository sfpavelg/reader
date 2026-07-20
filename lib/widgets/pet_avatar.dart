import 'package:flutter/material.dart';

import '../characters/pets/pet_catalog.dart';
import '../characters/pets/pet_character.dart';
import '../data/hive/models/pet_state.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.pet,
    this.size = 72,
    this.showLabel = true,
  });

  final PetState pet;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final def = PetCatalog.byIdName(pet.activePetId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: colors.primaryContainer,
          shape: const CircleBorder(),
          child: ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: IgnorePointer(
                child: PetCharacter(
                  petId: petIdFromString(pet.activePetId),
                  level: pet.displayLevel,
                  size: size,
                ),
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            def.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ],
    );
  }
}
