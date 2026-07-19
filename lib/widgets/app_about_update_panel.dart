import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/app_update_service.dart';

/// Версия, история релизов и проверка обновления (родительский контроль).
class AppAboutUpdatePanel extends StatefulWidget {
  const AppAboutUpdatePanel({super.key});

  @override
  State<AppAboutUpdatePanel> createState() => _AppAboutUpdatePanelState();
}

class _AppAboutUpdatePanelState extends State<AppAboutUpdatePanel> {
  PackageInfo? _packageInfo;
  List<AppChangelogEntry> _changelog = const [];
  AppRemoteRelease? _remote;
  String? _remoteMessage;
  String? _error;
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final info = await AppUpdateService.packageInfo();
    final changelog = await AppUpdateService.loadChangelog();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
      _changelog = changelog;
      _loading = false;
    });
  }

  int get _localCode {
    final build = int.tryParse(_packageInfo?.buildNumber ?? '') ?? 0;
    return build;
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _error = null;
      _remoteMessage = null;
      _remote = null;
    });
    try {
      final remote = await AppUpdateService.fetchRemoteRelease();
      if (!mounted) return;
      if (remote == null) {
        setState(() {
          _remoteMessage = 'Описание версии на Drive пустое.';
          _checking = false;
        });
        return;
      }
      final hasUpdate = remote.versionCode > _localCode;
      setState(() {
        _remote = remote;
        _remoteMessage = hasUpdate
            ? 'Доступна новая версия ${remote.fullVersion}.'
            : 'У вас актуальная версия.';
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppUpdateService.friendlyError(e);
        _checking = false;
      });
    }
  }

  Future<void> _download() async {
    final url = _remote?.apkUrl;
    if (url == null || url.isEmpty) return;
    final ok = await AppUpdateService.openApkUrl(url);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку на APK')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final versionLabel =
        '${_packageInfo?.version ?? '?'}+${_packageInfo?.buildNumber ?? '?'}';
    final hasUpdate =
        _remote != null && _remote!.versionCode > _localCode;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
      children: [
        Text(
          'Версия',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
              ),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Текущая версия'),
          subtitle: Text(
            versionLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _checking ? null : _checkUpdate,
          icon: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.system_update_alt_rounded),
          label: Text(_checking ? 'Проверяем…' : 'Проверить обновление'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: colors.error)),
        ],
        if (_remoteMessage != null) ...[
          const SizedBox(height: 8),
          Text(_remoteMessage!),
        ],
        if (_remote != null && _remote!.changes.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Что нового в ${_remote!.fullVersion}'),
            children: [
              for (final ch in _remote!.changes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('• $ch'),
                ),
            ],
          ),
        ],
        if (hasUpdate) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _download,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Скачать обновление'),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'История версий',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
              ),
        ),
        const SizedBox(height: 4),
        if (_changelog.isEmpty)
          const Text('Пока нет записей.')
        else
          for (final entry in _changelog)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(entry.fullVersion),
              subtitle: entry.date.isEmpty ? null : Text(entry.date),
              children: [
                if (entry.changes.isEmpty)
                  const ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Нет описания'),
                  )
                else
                  for (final ch in entry.changes)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('• $ch'),
                    ),
              ],
            ),
      ],
    );
  }
}
