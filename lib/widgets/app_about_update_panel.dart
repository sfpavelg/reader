import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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
  bool _downloading = false;

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

  /// Как в Библии: окно «обработка» ~1.5 с, затем передача установщику ОС.
  Future<void> _handoffToInstaller(File apkFile) async {
    const installerHandoffPause = Duration(milliseconds: 1500);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await WidgetsBinding.instance.endOfFrame;
            await Future<void>.delayed(installerHandoffPause);
            if (!dialogContext.mounted) return;
            final result = await AppUpdateService.installLocalApk(apkFile);
            if (!dialogContext.mounted) return;
            if (result.type != ResultType.done) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    result.message.isEmpty
                        ? 'Не удалось открыть установщик'
                        : result.message,
                  ),
                ),
              );
            }
            Navigator.of(dialogContext, rootNavigator: true).pop();
          } catch (_) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Не удалось открыть установщик'),
                ),
              );
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          }
        });
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Работает менеджер установки устройства, следуйте командам.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _download() async {
    final remote = _remote;
    if (remote == null || remote.apkUrl.isEmpty || _downloading) return;

    setState(() => _downloading = true);

    var progress = 0.0;
    final progressNotifier = ValueNotifier<double>(0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Скачиваем обновление'),
            content: ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (_, value, __) {
                final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Загрузка APK ${remote.fullVersion}… $pct%'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: value <= 0 ? null : value,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Не открывайте старый файл из «Загрузок» — '
                      'ждём новый APK здесь.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    try {
      final file = await AppUpdateService.downloadApkFile(
        apkUrl: remote.apkUrl,
        versionName: remote.versionName,
        versionCode: remote.versionCode,
        onProgress: (v) {
          progress = v;
          progressNotifier.value = progress;
        },
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // progress dialog
      progressNotifier.dispose();
      await _handoffToInstaller(file);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // progress dialog
      }
      progressNotifier.dispose();
      if (!mounted) return;

      final fallback = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Не удалось скачать внутри приложения'),
          content: Text(
            '${AppUpdateService.friendlyError(e)}\n\n'
            'Открыть ссылку в браузере? Если сразу «Установлено / Открыть» — '
            'это старый кэш. Удалите старый APK из загрузок и скачайте снова.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Открыть ссылку'),
            ),
          ],
        ),
      );
      if (fallback == true && mounted) {
        await AppUpdateService.openApkUrl(
          remote.apkUrl,
          cacheBust: remote.versionCode,
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
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
            onPressed: _downloading ? null : _download,
            icon: _downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _downloading ? 'Скачиваем…' : 'Скачать обновление',
            ),
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
