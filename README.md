# Reader

Офлайн-тренажёр чтения для детей 6–7 лет (Flutter). Слоги → слова → короткие фразы; упражнения без тяжёлой анимации — для слабых планшетов.
Горячие клавиши: Ctrl + L - вернуть строку чат-бота
Горячие клавиши: Ctrl + Shift + N - восстановить настройки Cursor 

## 🚀 Быстрый старт
1.
```bash
# Проверь путь:
cd "c:\Project\Reader"
```
2. 
```bash
# Сборка и деплой APK:
# Готовый файл будет здесь: build/app/outputs/flutter-apk/app-release.apk
flutter build apk --release
```
```bash
# Обновление зависимостей
# Не обязателен, если зависимости не менялись
flutter pub get
```
3.
```bash
# Если нужен эмулятор, запустить(запускается 5-30 секунд), запустится emulator-5554:
flutter emulators --launch Pixel_XL_API_34
```
4.
```bash
# Проверить подключенные устройства:
flutter emulators
```
5.
```bash
# Установка (или переустановка) приложения на эмулчтор emulator-5554:
flutter install -d emulator-5554
```
```bash
# Команда полного сброса эмулятора в случае исключения:
& "C:\Users\Papa\AppData\Local\Android\sdk\platform-tools\adb.exe" -s emulator-5554 emu kill; & "C:\Users\Papa\AppData\Local\Android\sdk\emulator\emulator.exe" -avd Pixel_XL_API_34 -wipe-data
```
6.
```bash
# Запуск приложения на эмулятор:
flutter run -d emulator-5554
```
7.
```bash
# Запуск приложения на маленьком телефоне:
flutter install -d U10HFCPN228AD
# Запуск приложения на README:
flutter install -d 2e2c089
# Запустить во вкладке Chrome:
flutter run -d chrome
flutter run -d chrome --web-port 5000
```

## 📦 Сборка для Windows
```bash
# build\windows\x64\runner\Release\bible_app.exe
flutter build windows --release
```

## 📦 Пуш на ГитХаб
```bash
cd C:\Project\Bible
git push origin main
```

## Для мамочек

Подробные тексты: **[docs/for_moms/](docs/for_moms/README.md)** — чем занят ребёнок, зачем каждое упражнение, советы дома.

В приложении: иконка семьи → родительский шлюз → **«Для мамочек»**.

## Порядок упражнений (MVP)

1. **Собери слово** — слоги в сетке 3×3, составь заданное слово
2. **Тахистоскоп (вспышки)** — реализовано
3. **Бегущая строка (RSVP)** — реализовано
4. **Слоговый конструктор** — реализовано
5. **Закладка-окно** — реализовано

## Геймификация

- **Питомец-читатель** — растёт от тренировок (иконки по стадиям, без тяжёлой анимации)
- **Звёзды** — за успешные раунды; тратятся на наклейки в альбоме
- **Карта миров** — 5 узлов на каждый тренажёр
- **Лимит 15 мин/день** — мягкое напоминание об отдыхе

На главном экране: питомец, звёзды, карта, альбом.

## Полировка UI

- **Шрифт Nunito** — встроен в приложение (`assets/fonts/`), кириллица, без загрузки из сети
- **Звуковые эффекты** — клик, успех, мягкая подсказка (`assets/sounds/`), отключаются в настройках
- **Тактильный отклик** — через `AppFeedback` (тапы, успех, подсказка без «наказания»)
- **Размер текста** — слайдер в настройках (90–130%), применяется ко всему приложению
- **Тема** — мягкие цвета, крупные кнопки, карточки с обводкой

## Быстрый старт

```bash
cd "c:\Project\Reader"
flutter pub get
flutter run
```

```bash
# APK
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

```bash
# Тесты
flutter test
```

## GitHub

https://github.com/sfpavelg/reader

```bash
git push origin main
```

## Структура

```
lib/
  trainers/          # логика упражнений
  screens/           # UI
  data/hive/         # офлайн-прогресс
  content/           # тексты «Для мамочек» в приложении
assets/dictionary/   # JSON-словарь (общий для всех тренажёров)
assets/fonts/        # Nunito (офлайн)
assets/sounds/       # звуковые эффекты
docs/for_moms/       # полные тексты для родителей
```
