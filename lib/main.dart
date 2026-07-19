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
      overrides: [dictionaryServiceProvider.overrideWithValue(dictionary)],
      child: const ReaderApp(),
    ),
  );
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  throw UnimplementedError('DictionaryService must be overridden at startup');
});

class ReaderApp extends StatelessWidget {
  const ReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Обучайка',
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
