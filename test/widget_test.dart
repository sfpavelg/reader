import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/local_storage.dart';
import 'package:reader/main.dart';
import 'package:reader/screens/home_screen.dart';
import 'package:reader/services/dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen shows trainer grid', (tester) async {
    final dictionary = DictionaryService();
    await dictionary.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryServiceProvider.overrideWithValue(dictionary),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Выбери упражнение'), findsOneWidget);
    expect(find.text('Шульте'), findsOneWidget);
    expect(find.text('Вспышки'), findsOneWidget);
  });
}
