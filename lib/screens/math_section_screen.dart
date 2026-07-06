import 'package:flutter/material.dart';

import '../mixins/trainer_stars_mixin.dart';
import '../widgets/stars_balance_chip.dart';

/// Заглушка раздела «Считайка» — математика появится позже.
class MathSectionScreen extends StatefulWidget {
  const MathSectionScreen({super.key});

  @override
  State<MathSectionScreen> createState() => _MathSectionScreenState();
}

class _MathSectionScreenState extends State<MathSectionScreen>
    with TrainerStarsMixin {
  @override
  void initState() {
    super.initState();
    initTrainerStars();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Считайка')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TrainerStarsBar(stars: trainerStars),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 72,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Скоро здесь',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Раздел с математикой появится в следующих обновлениях.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
