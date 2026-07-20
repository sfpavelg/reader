import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    if (raw.contains('NOT_APK') || raw.contains('DRIVE_HTML')) {
      return 'Drive отдал страницу вместо APK. Проверьте ссылку и доступ к файлу.';
    }
    return 'Ошибка проверки обновления.';
  }

  /// Прямая ссылка Drive для больших APK: без confirm часто открывается
  /// страница предупреждения / кэш, а не скачивание файла.
  static String normalizeDriveDownloadUrl(
    String apkUrl, {
    int? cacheBust,
  }) {
    final uri = Uri.tryParse(apkUrl.trim());
    if (uri == null) return apkUrl.trim();
    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com') &&
        !host.contains('docs.google.com')) {
      if (cacheBust == null) return apkUrl.trim();
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        't': '$cacheBust',
      }).toString();
    }

    final id = uri.queryParameters['id'] ??
        () {
          final parts = uri.pathSegments;
          final fileIdx = parts.indexOf('d');
          if (fileIdx >= 0 && fileIdx + 1 < parts.length) {
            return parts[fileIdx + 1];
          }
          return null;
        }();
    if (id == null || id.isEmpty || id == 'FILE_ID_APK') {
      return apkUrl.trim();
    }

    return Uri.https('drive.google.com', '/uc', {
      'export': 'download',
      'confirm': 't',
      'id': id,
      if (cacheBust != null) 't': '$cacheBust',
    }).toString();
  }

  static Future<bool> openApkUrl(String apkUrl, {int? cacheBust}) async {
    final uri = Uri.parse(
      normalizeDriveDownloadUrl(apkUrl, cacheBust: cacheBust),
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Скачивает APK во внутренний кэш приложения (не в «Загрузки» с кэшем Drive).
  static Future<File> downloadApkFile({
    required String apkUrl,
    required String versionName,
    required int versionCode,
    void Function(double progress)? onProgress,
  }) async {
    final url = normalizeDriveDownloadUrl(
      apkUrl,
      cacheBust: versionCode,
    );
    final dir = await getTemporaryDirectory();
    final fileName =
        'obuchaika_${versionName}_$versionCode.apk'.replaceAll(' ', '_');
    final outFile = File(p.join(dir.path, fileName));
    if (await outFile.exists()) {
      await outFile.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (compatible; ReaderUpdate/1.0)';
      final response = await client.send(request).timeout(
            const Duration(minutes: 5),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }

      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('text/html')) {
        throw StateError('DRIVE_HTML');
      }

      final total = response.contentLength ?? 0;
      final sink = outFile.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.close();

      if (received < 1024 * 100) {
        // слишком маленький файл — скорее HTML/ошибка
        final head = await outFile.openRead(0, 64).fold<List<int>>(
          <int>[],
          (prev, el) => prev..addAll(el),
        );
        final text = utf8.decode(head, allowMalformed: true).trimLeft();
        if (text.startsWith('<!') || text.toLowerCase().startsWith('<html')) {
          await outFile.delete();
          throw StateError('DRIVE_HTML');
        }
        throw StateError('NOT_APK');
      }

      // ZIP/APK magic: PK
      final magic = await outFile.openRead(0, 2).first;
      if (magic.length < 2 || magic[0] != 0x50 || magic[1] != 0x4B) {
        await outFile.delete();
        throw StateError('NOT_APK');
      }

      onProgress?.call(1);
      return outFile;
    } finally {
      client.close();
    }
  }

  static Future<OpenResult> installLocalApk(File apkFile) {
    return OpenFilex.open(
      apkFile.path,
      type: 'application/vnd.android.package-archive',
    );
  }
}
