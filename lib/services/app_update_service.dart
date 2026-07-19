import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Публичный JSON последней версии на Google Drive.
///
/// После первой загрузки `latest.json` в папку
/// https://drive.google.com/drive/folders/1DHnZfTUSJGHg-NGdwLfV6JMwNFMRUqai
/// замените FILE_ID_JSON на ID файла из ссылки вида
/// https://drive.google.com/file/d/FILE_ID_JSON/view
const String kReleaseManifestUrl =
    'https://drive.google.com/uc?export=download&id=1MJWaddvPsSubCPEB4AcRIX_qmvTyFp_A';

class AppChangelogEntry {
  const AppChangelogEntry({
    required this.versionName,
    required this.versionCode,
    required this.date,
    required this.changes,
  });

  final String versionName;
  final int versionCode;
  final String date;
  final List<String> changes;

  String get fullVersion => '$versionName+$versionCode';
}

class AppRemoteRelease {
  const AppRemoteRelease({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.changes,
  });

  final String versionName;
  final int versionCode;
  final String apkUrl;
  final List<String> changes;

  String get fullVersion => '$versionName+$versionCode';
}

abstract final class AppUpdateService {
  static Future<PackageInfo> packageInfo() => PackageInfo.fromPlatform();

  static Future<List<AppChangelogEntry>> loadChangelog() async {
    try {
      final raw = await rootBundle.loadString('assets/version/changelog.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['versions'] as List<dynamic>? ?? const []);
      final out = <AppChangelogEntry>[];
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final versionName = (m['version_name'] ?? '').toString().trim();
        final versionCode = (m['version_code'] as num?)?.toInt() ?? 0;
        final date = (m['date'] ?? '').toString().trim();
        final changes = (m['changes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (versionName.isEmpty || versionCode <= 0) continue;
        out.add(
          AppChangelogEntry(
            versionName: versionName,
            versionCode: versionCode,
            date: date,
            changes: changes,
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static List<String> _manifestChanges(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      return raw
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static Future<AppRemoteRelease?> fetchRemoteRelease() async {
    final manifestUrl = kReleaseManifestUrl.trim();
    if (manifestUrl.isEmpty || manifestUrl.contains('FILE_ID_JSON')) {
      throw StateError(
        'Сначала загрузите latest.json на Google Drive и пропишите '
        'FILE_ID_JSON в kReleaseManifestUrl '
        '(lib/services/app_update_service.dart).',
      );
    }

    final response = await http
        .get(
          Uri.parse(manifestUrl),
          headers: const {
            'User-Agent': 'Mozilla/5.0 (compatible; ReaderUpdate/1.0)',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }

    final body = utf8.decode(response.bodyBytes);
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!') ||
        trimmed.toLowerCase().startsWith('<html') ||
        body.contains('accounts.google.com') ||
        body.contains('Sign in')) {
      throw StateError('DRIVE_ACCESS_DENIED');
    }

    late final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('Неверный формат latest.json');
    }

    final versionName =
        (decoded['version_name'] ?? decoded['versionName'] ?? '')
            .toString()
            .trim();
    final rawCode = decoded['version_code'] ?? decoded['versionCode'];
    final versionCode = rawCode is num ? rawCode.toInt() : 0;
    final apkUrl =
        (decoded['apk_url'] ?? decoded['apkUrl'] ?? '').toString().trim();
    final changes = _manifestChanges(decoded['changes']);

    if (versionName.isEmpty || versionCode <= 0 || apkUrl.isEmpty) {
      throw StateError('Неверный формат latest.json');
    }
    if (apkUrl.contains('FILE_ID_APK')) {
      throw StateError('В latest.json ещё заглушка FILE_ID_APK');
    }

    return AppRemoteRelease(
      versionName: versionName,
      versionCode: versionCode,
      apkUrl: apkUrl,
      changes: changes,
    );
  }

  static String friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('FILE_ID_JSON')) {
      return 'Обновления ещё не настроены: нет FILE_ID_JSON на Drive.';
    }
    if (raw.contains('FILE_ID_APK')) {
      return 'В latest.json на Drive не прописан ID APK.';
    }
    if (raw.contains('DRIVE_ACCESS_DENIED')) {
      return 'Drive закрыл файл. Откройте доступ к latest.json: '
          '«Все, у кого есть ссылка» → Читатель.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('TimeoutException') ||
        raw.contains('ClientException')) {
      return 'Нет сети или Drive недоступен. Проверьте интернет.';
    }
    if (raw.contains('HTTP')) {
      return 'Не удалось скачать описание версии с Drive.';
    }
    if (raw.contains('Неверный формат') || raw.contains('FormatException')) {
      return 'Файл latest.json на Drive повреждён или неполный.';
    }
    return 'Ошибка проверки обновления.';
  }

  static Future<bool> openApkUrl(String apkUrl) async {
    final uri = Uri.parse(apkUrl);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
