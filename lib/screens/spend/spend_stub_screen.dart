import 'package:flutter/material.dart';

import '../../widgets/app_feedback.dart';

/// Заглушка раздела траты звёзд — функционал появится позже.
class SpendStubScreen extends StatelessWidget {
  const SpendStubScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.description,
    this.comingSoonHint = 'Скоро здесь можно будет тратить звёзды!',
  });

  final String title;
  final String emoji;
  final String description;
  final String comingSoonHint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: colors.primaryContainer,
                shape: const CircleBorder(),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () async {
                  await AppFeedback.tap();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(comingSoonHint)),
                  );
                },
                child: const Text('Скоро откроется'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
