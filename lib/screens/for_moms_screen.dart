import 'package:flutter/material.dart';

import '../content/for_moms_sections.dart';

const _readingIcons = ['⚡', '🔢', '❓', '🖐️', '👁️', '🐍'];
const _mathIcons = ['1️⃣', '➕', '➕', '➖', '❔', '✖️', '▦', '📊'];
const _extraIcons = ['⭐', '🔒'];

/// Раздел «Для мамочек» — доступ через родительский шлюз.
class ForMomsScreen extends StatelessWidget {
  const ForMomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Для мамочек'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
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
                  Text(
                    forMomsIntro,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GroupTitle(title: 'Читайка', color: colors.primary),
          const SizedBox(height: 8),
          for (var i = 0; i < forMomsReadingSections.length; i++)
            _SectionCard(
              section: forMomsReadingSections[i],
              icon: _readingIcons[i % _readingIcons.length],
            ),
          const SizedBox(height: 12),
          _GroupTitle(title: 'Считайка', color: colors.primary),
          const SizedBox(height: 8),
          for (var i = 0; i < forMomsMathSections.length; i++)
            _SectionCard(
              section: forMomsMathSections[i],
              icon: _mathIcons[i % _mathIcons.length],
            ),
          const SizedBox(height: 12),
          _GroupTitle(title: 'Ещё полезно знать', color: colors.primary),
          const SizedBox(height: 8),
          for (var i = 0; i < forMomsExtrasSections.length; i++)
            _SectionCard(
              section: forMomsExtrasSections[i],
              icon: _extraIcons[i % _extraIcons.length],
            ),
          const SizedBox(height: 8),
          Text(
            'Главное — спокойный ритм без спешки. '
            'Звёзды и питомец помогают, но не заменяют ваше участие.',
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

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
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
