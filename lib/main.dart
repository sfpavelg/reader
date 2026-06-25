import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app_theme.dart';
import 'data/hive/local_storage.dart';
import 'screens/splash_screen.dart';
import 'services/dictionary_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await LocalStorage.initialize();

  final dictionary = DictionaryService();
  await dictionary.initialize();

  runApp(
    ProviderScope(
      overrides: [
        dictionaryServiceProvider.overrideWithValue(dictionary),
      ],
      child: const ReaderApp(),
    ),
  );
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  throw UnimplementedError('DictionaryService must be overridden at startup');
});

class ReaderApp extends StatefulWidget {
  const ReaderApp({super.key});

  @override
  State<ReaderApp> createState() => _ReaderAppState();
}

class _ReaderAppState extends State<ReaderApp> {
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    if (!LocalStorage.isReady) return;
    setState(() {
      _fontScale = LocalStorage.readSettings().baseFontScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reader',
      theme: AppTheme.light(fontScale: _fontScale),
      home: SplashScreen(onThemeChanged: _loadThemeSettings),
    );
  }
}
