import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader/main.dart';
import 'package:reader/screens/home_screen.dart';
import 'package:reader/screens/reading_section_screen.dart';
import 'package:reader/services/dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen shows main sections', (tester) async {
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

    expect(find.text('Обучайка'), findsOneWidget);
    expect(find.text('Выбери раздел'), findsOneWidget);
    expect(find.text('Читайка'), findsOneWidget);
    expect(find.text('Считайка'), findsOneWidget);
    expect(find.text('Сказки'), findsWidgets);
    expect(find.text('Выбери упражнение'), findsNothing);
  });

  testWidgets('reading section shows trainer grid', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReadingSectionScreen()),
    );

    expect(find.text('Выбери упражнение'), findsOneWidget);
    expect(find.text('Собирайка'), findsOneWidget);
    expect(find.text('Вспышка'), findsOneWidget);
  });
}
