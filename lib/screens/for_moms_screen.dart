import 'package:flutter/material.dart';

import '../content/for_moms_sections.dart';

const _sectionIcons = ['🔢', '⚡', '📖', '🧩', '👁️'];

/// Раздел «Для мамочек» — доступ через родительский шлюз.
class ForMomsScreen extends StatelessWidget {
  const ForMomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Для мамочек'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Почему это приложение важно',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(forMomsIntro, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < forMomsSections.length; i++)
            _SectionCard(
              section: forMomsSections[i],
              icon: _sectionIcons[i % _sectionIcons.length],
            ),
          const SizedBox(height: 8),
          Text(
            'Рекомендуем 10–15 минут в день. Звёзды и питомец мотивируют, '
            'но главное — спокойный ритм без спешки.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.icon});

  final ForMomsSection section;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LabelValue(label: 'Чем занят ребёнок', value: section.whatChildDoes),
            const SizedBox(height: 8),
            _LabelValue(label: 'Зачем это', value: section.whyItMatters),
            const SizedBox(height: 8),
            _LabelValue(label: 'Совет дома', value: section.homeTip),
          ],
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
