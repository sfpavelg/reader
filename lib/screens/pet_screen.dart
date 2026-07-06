import 'package:flutter/material.dart';

import '../characters/kolobok/kolobok_character.dart';
import '../characters/kolobok/kolobok_stage.dart';
import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/rewards_service.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/stars_balance_chip.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> with TrainerStarsMixin {
  late PetState _pet;
  KolobokStage _selectedStage = KolobokStage.adult;
  KolobokAction _lastAction = KolobokAction.idle;

  @override
  void initState() {
    super.initState();
    initTrainerStars();
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

  String get _actionHint {
    switch (_lastAction) {
      case KolobokAction.idle:
        return 'Тапни по глазам, телу или сбоку от Колобка';
      case KolobokAction.jump:
        return 'Прыжок!';
      case KolobokAction.spin:
        return 'Колобок покрутился';
      case KolobokAction.wink:
        return 'Подмигнул';
      case KolobokAction.joy:
        return 'Радость: звезда летит вокруг';
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TrainerStarsBar(stars: trainerStars),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStage.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                'Этап ${_selectedStage.level} из 6: '
                                '${_selectedStage.subtitle}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<KolobokStage>(
                          value: _selectedStage,
                          onChanged: (stage) {
                            if (stage == null) return;
                            setState(() {
                              _selectedStage = stage;
                              _lastAction = KolobokAction.idle;
                            });
                          },
                          items: [
                            for (final stage in KolobokStage.values)
                              DropdownMenuItem(
                                value: stage,
                                child: Text('${stage.level}. ${stage.title}'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    KolobokCharacter(
                      stage: _selectedStage,
                      size: 260,
                      onAction: (action) {
                        setState(() => _lastAction = action);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _actionHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _InteractionChip(text: 'глаза = подмигнуть'),
                        _InteractionChip(text: 'тело = прыжок'),
                        _InteractionChip(text: 'слева = покрутиться'),
                        _InteractionChip(text: 'справа = радость'),
                      ],
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
                    const SizedBox(height: 6),
                    Text(
                      'Опыт: ${_pet.xp} XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }
}

class _InteractionChip extends StatelessWidget {
  const _InteractionChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
        ),
      ),
    );
  }
}
