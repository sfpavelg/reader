import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/app_settings.dart';
import '../gamification/trainer_attempts_reset.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_about_update_panel.dart';
import '../widgets/obscured_text_field.dart';
import 'for_moms_screen.dart';

class ParentControlScreen extends ConsumerStatefulWidget {
  const ParentControlScreen({super.key});

  @override
  ConsumerState<ParentControlScreen> createState() =>
      _ParentControlScreenState();
}

class _ParentControlScreenState extends ConsumerState<ParentControlScreen> {
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

  Future<void> _confirmResetAttempts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить попытки?'),
        content: const Text(
          'Счётчики попыток во всех тренажёрах обнулятся на сегодня. '
          'Звёзды и прогресс тренировки сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await TrainerAttemptsReset.resetAll();
    if (!mounted) return;
    await AppFeedback.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Попытки сброшены', textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Временно для отладки: +100 ★ за каждое нажатие.
  Future<void> _addDebugStars() async {
    final profile = LocalStorage.readProfile();
    final next = profile.copyWith(totalStars: profile.totalStars + 100);
    await LocalStorage.writeProfile(next);
    if (!mounted) return;
    await AppFeedback.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Звёзды: ${next.totalStars} (+100)',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickBlockedTime({required bool isFrom}) async {
    final initial = TimeOfDay(
      hour: (isFrom
              ? _settings.clampedPlayBlockedFromMinutes
              : _settings.clampedPlayBlockedToMinutes) ~/
          60,
      minute: (isFrom
              ? _settings.clampedPlayBlockedFromMinutes
              : _settings.clampedPlayBlockedToMinutes) %
          60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isFrom
          ? 'С какого времени нельзя играть'
          : 'До какого времени нельзя играть',
    );
    if (picked == null) return;

    final minutes = picked.hour * 60 + picked.minute;
    await _save(
      isFrom
          ? _settings.copyWith(playBlockedFromMinutes: minutes)
          : _settings.copyWith(playBlockedToMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Родительский контроль'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ограничения'),
              Tab(text: 'Пароли'),
              Tab(text: 'О приложении'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RestrictionsTab(
              settings: _settings,
              onSave: _save,
              onPickBlockedTime: _pickBlockedTime,
              onResetAttempts: _confirmResetAttempts,
              onAddDebugStars: _addDebugStars,
            ),
            _PasswordsTab(
              settings: _settings,
              onSave: _save,
            ),
            const AppAboutUpdatePanel(),
          ],
        ),
      ),
    );
  }
}

class _RestrictionsTab extends StatelessWidget {
  const _RestrictionsTab({
    required this.settings,
    required this.onSave,
    required this.onPickBlockedTime,
    required this.onResetAttempts,
    required this.onAddDebugStars,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;
  final Future<void> Function({required bool isFrom}) onPickBlockedTime;
  final Future<void> Function() onResetAttempts;
  final Future<void> Function() onAddDebugStars;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8).copyWith(
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        SwitchListTile(
          title: const Text('Лимит тренировки в день'),
          subtitle: Text(
            settings.dailyTrainingLimitEnabled
                ? 'После ${settings.clampedDailyTrainingMinuteLimit} мин. '
                    'появится «Тренировка окончена»'
                : 'Лимит отключён — можно тренироваться сколько угодно',
          ),
          value: settings.dailyTrainingLimitEnabled,
          onChanged: (value) =>
              onSave(settings.copyWith(dailyTrainingLimitEnabled: value)),
        ),
        if (settings.dailyTrainingLimitEnabled)
          ListTile(
            title: const Text('Минут в день'),
            subtitle: Slider(
              value: settings.clampedDailyTrainingMinuteLimit.toDouble(),
              min: AppSettings.minDailyTrainingMinuteLimit.toDouble(),
              max: AppSettings.maxDailyTrainingMinuteLimit.toDouble(),
              divisions: (AppSettings.maxDailyTrainingMinuteLimit -
                      AppSettings.minDailyTrainingMinuteLimit) ~/
                  AppSettings.dailyTrainingMinuteLimitStep,
              label: '${settings.clampedDailyTrainingMinuteLimit} мин',
              onChanged: (value) {
                final snapped = (value / AppSettings.dailyTrainingMinuteLimitStep)
                    .round()
                    .clamp(
                      AppSettings.minDailyTrainingMinuteLimit ~/
                          AppSettings.dailyTrainingMinuteLimitStep,
                      AppSettings.maxDailyTrainingMinuteLimit ~/
                          AppSettings.dailyTrainingMinuteLimitStep,
                    ) *
                    AppSettings.dailyTrainingMinuteLimitStep;
                onSave(settings.copyWith(dailyTrainingMinuteLimit: snapped));
              },
            ),
          ),
        SwitchListTile(
          title: const Text('Ограничение по времени'),
          subtitle: Text(
            settings.playTimeRestrictionEnabled
                ? 'Игра недоступна с ${settings.playBlockedFromLabel} '
                    'до ${settings.playBlockedToLabel}'
                : 'Можно играть в любое время',
          ),
          value: settings.playTimeRestrictionEnabled,
          onChanged: (value) =>
              onSave(settings.copyWith(playTimeRestrictionEnabled: value)),
        ),
        if (settings.playTimeRestrictionEnabled) ...[
          ListTile(
            title: const Text('Нельзя играть с'),
            trailing: Text(
              settings.playBlockedFromLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => onPickBlockedTime(isFrom: true),
          ),
          ListTile(
            title: const Text('Нельзя играть до'),
            trailing: Text(
              settings.playBlockedToLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => onPickBlockedTime(isFrom: false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              settings.allowedPlayWindowDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
        SwitchListTile(
          title: const Text('Порядок упражнений'),
          subtitle: Text(
            settings.hardTrainerProgressGateEnabled
                ? 'Таблица и Слогоменяйка открываются после попыток '
                    'в простых упражнениях'
                : 'Все упражнения доступны сразу',
          ),
          value: settings.hardTrainerProgressGateEnabled,
          onChanged: (value) => onSave(
            settings.copyWith(hardTrainerProgressGateEnabled: value),
          ),
        ),
        const Divider(height: 24),
        ListTile(
          title: const Text('Сброс попыток'),
          subtitle: const Text(
            'Вернуть дневные попытки во всех тренажёрах, если ребёнок '
            'использовал их все',
          ),
          trailing: const Icon(Icons.restart_alt),
          onTap: () async {
            await AppFeedback.tap();
            await onResetAttempts();
          },
        ),
        ListTile(
          title: const Text('+100 звёзд'),
          subtitle: const Text('Временно для отладки — каждое нажатие +100 ★'),
          trailing: const Icon(Icons.star_rounded, color: Color(0xFF8E24AA)),
          onTap: () async {
            await AppFeedback.tap();
            await onAddDebugStars();
          },
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
      ],
    );
  }
}

class _PasswordsTab extends StatefulWidget {
  const _PasswordsTab({
    required this.settings,
    required this.onSave,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;

  @override
  State<_PasswordsTab> createState() => _PasswordsTabState();
}

class _PasswordsTabState extends State<_PasswordsTab> {
  static const _minPasswordLength = 4;

  final _primaryController = TextEditingController();
  final _primaryConfirmController = TextEditingController();
  final _backupController = TextEditingController();
  final _backupConfirmController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _questionController.text =
        widget.settings.parentRecoveryQuestion ??
        AppSettings.defaultParentRecoveryQuestion;
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _primaryConfirmController.dispose();
    _backupController.dispose();
    _backupConfirmController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _savePasswords() async {
    final primary = _primaryController.text;
    final primaryConfirm = _primaryConfirmController.text;
    final backup = _backupController.text;
    final backupConfirm = _backupConfirmController.text;
    final question = _questionController.text.trim();
    final answer = _answerController.text;

    if (primary.length < _minPasswordLength) {
      setState(() => _passwordError = 'Основной пароль: минимум $_minPasswordLength символа');
      return;
    }
    if (primary != primaryConfirm) {
      setState(() => _passwordError = 'Основные пароли не совпадают');
      return;
    }
    if (backup.length < _minPasswordLength) {
      setState(() => _passwordError = 'Запасной пароль: минимум $_minPasswordLength символа');
      return;
    }
    if (backup != backupConfirm) {
      setState(() => _passwordError = 'Запасные пароли не совпадают');
      return;
    }
    if (AppSettings.secretsMatch(primary, backup)) {
      setState(() => _passwordError = 'Запасной пароль должен отличаться от основного');
      return;
    }
    if (question.isEmpty) {
      setState(() => _passwordError = 'Введите контрольный вопрос');
      return;
    }
    if (answer.trim().length < 2) {
      setState(() => _passwordError = 'Ответ слишком короткий');
      return;
    }

    await widget.onSave(
      widget.settings.copyWith(
        parentPasswordPrimary: AppSettings.normalizeSecret(primary),
        parentPasswordBackup: AppSettings.normalizeSecret(backup),
        parentRecoveryQuestion: question,
        parentRecoveryAnswer: AppSettings.normalizeSecret(answer),
      ),
    );

    _primaryController.clear();
    _primaryConfirmController.clear();
    _backupController.clear();
    _backupConfirmController.clear();
    _answerController.clear();

    if (!mounted) return;
    setState(() => _passwordError = null);
    await AppFeedback.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пароли сохранены', textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _plainDecoration({
    required String labelText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text(
          widget.settings.hasParentPassword
              ? 'Пароли заданы. Чтобы изменить — введите новые и нажмите «Сохранить пароли».'
              : 'Задайте основной и запасной пароль, а также контрольный вопрос.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ObscuredTextField(
          controller: _primaryController,
          labelText: 'Основной пароль',
          helperText: 'Минимум 4 символа',
        ),
        const SizedBox(height: 12),
        ObscuredTextField(
          controller: _primaryConfirmController,
          labelText: 'Повтор основного пароля',
        ),
        const SizedBox(height: 16),
        ObscuredTextField(
          controller: _backupController,
          labelText: 'Запасной пароль',
          helperText: 'На случай, если забыли основной',
        ),
        const SizedBox(height: 12),
        ObscuredTextField(
          controller: _backupConfirmController,
          labelText: 'Повтор запасного пароля',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _questionController,
          decoration: _plainDecoration(
            labelText: 'Контрольный вопрос',
            helperText: 'Например: какая река течёт в Москве?',
          ),
        ),
        const SizedBox(height: 12),
        ObscuredTextField(
          controller: _answerController,
          labelText: 'Ответ на контрольный вопрос',
          helperText: 'Если забыли оба пароля',
          obscure: false,
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 12),
          Text(
            _passwordError!,
            style: TextStyle(color: colors.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _savePasswords,
          child: const Text('Сохранить пароли'),
        ),
      ],
    );
  }
}
