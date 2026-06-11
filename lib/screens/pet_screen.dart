import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/rewards_service.dart';
import '../widgets/pet_avatar.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late PetState _pet;

  @override
  void initState() {
    super.initState();
    _pet = LocalStorage.readPet();
  }

  int get _nextThreshold {
    switch (_pet.stage) {
      case PetStage.egg:
        return PetState.xpBaby;
      case PetStage.baby:
        return PetState.xpTeen;
      case PetStage.teen:
        return PetState.xpHero;
      case PetStage.hero:
        return PetState.xpHero;
    }
  }

  String get _stageLabel {
    switch (_pet.stage) {
      case PetStage.egg:
        return 'Яйцо';
      case PetStage.baby:
        return 'Малыш';
      case PetStage.teen:
        return 'Подросток';
      case PetStage.hero:
        return 'Герой чтения';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = _pet.stage == PetStage.hero
        ? 1.0
        : (_pet.xp / _nextThreshold).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Питомец-читатель')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      PetAvatar(pet: _pet, size: 120),
                      const SizedBox(height: 16),
                      Text(
                        _stageLabel,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Опыт: ${_pet.xp} XP',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Рост',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _pet.stage == PetStage.hero
                            ? 'Максимальный рост!'
                            : 'До следующей стадии: ${_nextThreshold - _pet.xp} XP',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Каждая успешная тренировка кормит питомца. '
                'Сегодня занятий: ${RewardsService.minutesPlayedToday()} '
                'из ${RewardsService.dailyMinuteLimit} мин.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
