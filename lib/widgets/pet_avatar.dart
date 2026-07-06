import 'package:flutter/material.dart';

import '../characters/kolobok/kolobok_adult_portrait.dart';
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
              child: KolobokAdultPortrait(size: size),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            _labelForStage(pet.stage),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ],
    );
  }

  static String _labelForStage(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return 'Яйцо';
      case PetStage.baby:
        return 'Малыш';
      case PetStage.teen:
        return 'Подросток';
      case PetStage.hero:
        return 'Герой';
    }
  }
}
