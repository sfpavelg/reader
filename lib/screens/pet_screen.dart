import 'package:flutter/material.dart';

import '../characters/kolobok/kolobok_stage.dart';
import '../characters/pets/pet_catalog.dart';
import '../characters/pets/pet_character.dart';
import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/rewards_service.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stars_balance_chip.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> with TrainerStarsMixin {
  late PetState _pet;
  late int _selectedLevel;

  PetDef get _activeDef => PetCatalog.byIdName(_pet.activePetId);

  PetId get _activePetId => petIdFromString(_pet.activePetId);

  @override
  void initState() {
    super.initState();
    initTrainerStars();
    _pet = LocalStorage.readPet();
    _selectedLevel = _pet.displayLevel;
  }

  void _reloadPet({bool selectNewest = false}) {
    _pet = LocalStorage.readPet();
    final maxLevel = _pet.displayLevel;
    if (selectNewest || _selectedLevel > maxLevel) {
      _selectedLevel = maxLevel;
    }
  }

  List<KolobokStage> get _selectableStages {
    return KolobokStage.values
        .where((s) => s.level <= _pet.displayLevel)
        .toList();
  }

  KolobokStage get _selectedStage => PetCatalog.stageForLevel(_selectedLevel);

  KolobokStage? get _nextStage {
    if (!_pet.canUnlockNext) return null;
    return PetCatalog.stageForLevel(_pet.displayLevel + 1);
  }

  Future<void> _selectPet(PetId id) async {
    if (id.name == _pet.activePetId) return;
    await AppFeedback.tap();
    final updated = _pet.selectPetId(id.name);
    await LocalStorage.writePet(updated);
    if (!mounted) return;
    setState(() {
      _pet = updated;
      _selectedLevel = updated.displayLevel;
    });
  }

  Future<void> _feedPet() async {
    final next = _nextStage;
    if (next == null) return;

    final cost = PetState.starCostPerLevel;
    if (trainerStars < cost) {
      await AppFeedback.softHint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нужно $cost ★. Сейчас у тебя $trainerStars.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Покормить питомца?'),
        content: Text(
          '${_activeDef.name} вырастет до «${next.title}» за $cost ★.\n'
          'У тебя сейчас: $trainerStars ★.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Покормить'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await RewardsService.unlockPetLevel(
      starCost: cost,
      petId: _activePetId,
    );
    if (!mounted) return;
    if (!ok) {
      await AppFeedback.softHint();
      return;
    }

    await AppFeedback.success();
    reloadTrainerStars();
    setState(() => _reloadPet(selectNewest: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Теперь это «${next.title}»!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stages = _selectableStages;
    final showStagePicker = stages.length > 1;
    final next = _nextStage;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                _activeDef.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<PetId>(
              tooltip: 'Выбрать питомца',
              initialValue: _activePetId,
              onSelected: _selectPet,
              itemBuilder: (ctx) => [
                for (final pet in PetCatalog.pets)
                  PopupMenuItem(
                    value: pet.id,
                    child: Row(
                      children: [
                        Text(pet.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(pet.name),
                        if (pet.id == _activePetId) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 18, color: colors.primary),
                        ],
                      ],
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StarsBalanceChip(stars: trainerStars, compact: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                'Этап ${_selectedStage.level} из '
                                '${PetState.maxLevel}: '
                                '${_selectedStage.subtitle}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (showStagePicker)
                          DropdownButton<int>(
                            value: _selectedLevel,
                            onChanged: (level) {
                              if (level == null) return;
                              setState(() => _selectedLevel = level);
                            },
                            items: [
                              for (final stage in stages)
                                DropdownMenuItem(
                                  value: stage.level,
                                  child: Text(stage.title),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PetCharacter(
                      petId: _activePetId,
                      level: _selectedLevel,
                      size: 260,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FeedCard(
              petName: _activeDef.name,
              nextStage: next,
              cost: PetState.starCostPerLevel,
              onTap: next == null ? null : _feedPet,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.petName,
    required this.nextStage,
    required this.cost,
    required this.onTap,
  });

  final String petName;
  final KolobokStage? nextStage;
  final int cost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locked = nextStage == null;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            color: colors.primaryContainer.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    locked ? '⭐' : '🍎',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locked ? 'Максимальный рост' : 'Покормить питомца',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locked
                            ? '$petName уже на последнем этапе.'
                            : 'Вырастит до «${nextStage!.title}».',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      if (!locked) ...[
                        const SizedBox(height: 8),
                        StarPriceLabel(
                          amount: cost,
                          suffix: ' / этап',
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!locked)
                  Icon(Icons.chevron_right, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

