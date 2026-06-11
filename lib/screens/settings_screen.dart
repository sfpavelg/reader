import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive/local_storage.dart';
import '../widgets/app_feedback.dart';
import '../data/hive/models/app_settings.dart';
import 'for_moms_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = LocalStorage.readSettings();
  }

  Future<void> _save(AppSettings next) async {
    setState(() => _settings = next);
    await LocalStorage.writeSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Звук и отображение',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Звуковые эффекты'),
            value: _settings.soundEffectsEnabled,
            onChanged: (v) =>
                _save(_settings.copyWith(soundEffectsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Фоновая музыка'),
            subtitle: const Text('По умолчанию выключена'),
            value: _settings.backgroundMusicEnabled,
            onChanged: (v) =>
                _save(_settings.copyWith(backgroundMusicEnabled: v)),
          ),
          ListTile(
            title: const Text('Размер текста'),
            subtitle: Slider(
              value: _settings.baseFontScale,
              min: 0.9,
              max: 1.3,
              divisions: 4,
              label: '${(_settings.baseFontScale * 100).round()}%',
              onChanged: (v) => _save(_settings.copyWith(baseFontScale: v)),
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Родителям',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            title: const Text('Для мамочек'),
            subtitle: const Text('Чем занят ребёнок и зачем это нужно'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await AppFeedback.tap();
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ForMomsScreen(),
                ),
              );
            },
          ),
          const ListTile(
            title: Text('Версия'),
            subtitle: Text('1.0.0 MVP'),
          ),
        ],
      ),
    );
  }
}
