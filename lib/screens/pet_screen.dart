import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../characters/kolobok/kolobok_stage.dart';
import '../characters/pets/pet_catalog.dart';
import '../characters/pets/pet_character.dart';
import '../data/hive/local_storage.dart';
import '../data/hive/models/pet_state.dart';
import '../gamification/rewards_service.dart';
import '../mixins/trainer_stars_mixin.dart';
import '../theme/star_colors.dart';
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
    final available =
        PetCatalog.pets.any((p) => p.id.name == _pet.activePetId);
    if (!available) {
      final fixed = _pet.selectPetId(PetId.kotenok.name);
      LocalStorage.writePet(fixed);
      _pet = fixed;
    }
    _selectedLevel = _pet.displayLevel;
  }

  void _reloadPet({bool selectNewest = false}) {
    _pet = LocalStorage.readPet();
    final maxLevel = _pet.displayLevel;
    if (selectNewest || _selectedLevel > maxLevel) {
      _selectedLevel = maxLevel;
    }
  }

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
          '${_activeDef.name} вырастет до «${PetCatalog.stageTitle(_activePetId, next)}» за $cost ★.\n'
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final next = _nextStage;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CircleNavButton(
                  tooltip: 'Назад',
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: StarColors.currency,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: PopupMenuButton<PetId>(
                tooltip: 'Выбрать питомца',
                initialValue: _activePetId,
                onSelected: _selectPet,
                offset: const Offset(0, 8),
                itemBuilder: (ctx) => [
                  for (final pet in PetCatalog.pets)
                    PopupMenuItem(
                      value: pet.id,
                      child: Row(
                        children: [
                          _PetFaceAvatar(petId: pet.id, size: 28),
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
                child: const _OrangePillLabel(
                  label: 'Питомцы',
                  chevronDown: true,
                  compact: true,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: StarsBalanceChip(stars: trainerStars, compact: true),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      children: [
                        _GrowthStagesButton(
                          petId: _activePetId,
                          unlockedLevel: _pet.displayLevel,
                          selectedLevel: _selectedLevel,
                          onSelected: (level) {
                            setState(() => _selectedLevel = level);
                          },
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final def = _activeDef;
                              if (def.hasStageImages) {
                                return PetCharacter(
                                  petId: _activePetId,
                                  level: _selectedLevel,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  fit: BoxFit.cover,
                                );
                              }
                              final side = constraints.biggest.shortestSide;
                              final petSize = side.clamp(220.0, 520.0);
                              return Center(
                                child: PetCharacter(
                                  petId: _activePetId,
                                  level: _selectedLevel,
                                  size: petSize,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _FeedCard(
                petId: _activePetId,
                petName: _activeDef.name,
                nextStage: next,
                cost: PetState.starCostPerLevel,
                onTap: next == null ? null : _feedPet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthStagesButton extends StatelessWidget {
  const _GrowthStagesButton({
    required this.petId,
    required this.unlockedLevel,
    required this.selectedLevel,
    required this.onSelected,
  });

  final PetId petId;
  final int unlockedLevel;
  final int selectedLevel;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: PopupMenuButton<int>(
        tooltip: 'Этапы роста',
        initialValue: selectedLevel,
        onSelected: onSelected,
        offset: const Offset(0, 8),
        itemBuilder: (ctx) => [
          for (final stage in KolobokStage.values)
            PopupMenuItem(
              value: stage.level,
              enabled: stage.level <= unlockedLevel,
              child: Opacity(
                opacity: stage.level <= unlockedLevel ? 1 : 0.55,
                child: Row(
                  children: [
                    _PetFaceAvatar(
                      petId: petId,
                      level: stage.level,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(PetCatalog.stageTitle(petId, stage)),
                    ),
                    if (stage.level == selectedLevel)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: StarColors.currency,
                      )
                    else if (stage.level > unlockedLevel)
                      Icon(Icons.lock_outline, size: 18, color: onVariant),
                  ],
                ),
              ),
            ),
        ],
        child: const _OrangePillLabel(
          label: 'Посмотри как я расту!',
          chevronDown: false,
        ),
      ),
    );
  }
}

class _OrangePillLabel extends StatelessWidget {
  const _OrangePillLabel({
    required this.label,
    required this.chevronDown,
    this.compact = false,
  });

  final String label;
  final bool chevronDown;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chevron = const Icon(
      Icons.chevron_right,
      color: StarColors.currency,
    );
    return SizedBox(
      width: double.infinity,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: StarColors.currency.withValues(alpha: 0.35),
            width: 2,
          ),
          color: StarColors.currencySoft.withValues(alpha: 0.28),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (chevronDown)
                Transform.rotate(angle: math.pi / 2, child: chevron)
              else
                chevron,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.petId,
    required this.petName,
    required this.nextStage,
    required this.cost,
    required this.onTap,
  });

  final PetId petId;
  final String petName;
  final KolobokStage? nextStage;
  final int cost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = nextStage == null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: StarColors.currency.withValues(alpha: 0.35),
              width: 2,
            ),
            color: StarColors.currencySoft.withValues(alpha: 0.28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: StarColors.currency.withValues(alpha: 0.14),
                  child: locked
                      ? const Icon(
                          Icons.star_rounded,
                          color: StarColors.currency,
                          size: 28,
                        )
                      : const Text('🍎', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locked ? 'Максимальный рост' : 'Покормить питомца',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked
                            ? '$petName уже на последнем этапе.'
                            : 'Вырастит до «${PetCatalog.stageTitle(petId, nextStage!)}».',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (!locked) ...[
                        const SizedBox(height: 6),
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
                  const Icon(Icons.chevron_right, color: StarColors.currency),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetFaceAvatar extends StatelessWidget {
  const _PetFaceAvatar({
    required this.petId,
    required this.size,
    this.level = 6,
  });

  final PetId petId;
  final double size;
  final int level;

  @override
  Widget build(BuildContext context) {
    final asset = PetCatalog.stageImageAsset(petId, level);
    final def = PetCatalog.byId(petId);
    if (asset == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(def.emoji, style: TextStyle(fontSize: size * 0.7)),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.35),
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({
    required this.child,
    this.tooltip,
    this.onPressed,
  });

  final Widget child;
  final String? tooltip;
  final VoidCallback? onPressed;

  static const _outline = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = SizedBox(
      width: 36,
      height: 36,
      child: Center(child: child),
    );
    final button = Material(
      color: colors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: _outline, width: 1.5),
      ),
      child: onPressed == null
          ? content
          : InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: content,
            ),
    );
    if (tooltip == null || onPressed == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

