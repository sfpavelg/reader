import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../data/hive/models/app_settings.dart';
import 'app_feedback.dart';
import 'obscured_text_field.dart';

enum _ParentLoginMode { primary, backup, recovery }

/// Вход в родительский контроль по паролю.
class ParentGate {
  ParentGate._();

  static Future<bool> show(BuildContext context) async {
    if (!LocalStorage.isReady) return false;

    final settings = LocalStorage.readSettings();
    if (!settings.hasParentPassword) return true;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ParentPasswordDialog(settings: settings),
    );
    return ok ?? false;
  }
}

class _ParentPasswordDialog extends StatefulWidget {
  const _ParentPasswordDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_ParentPasswordDialog> createState() => _ParentPasswordDialogState();
}

class _ParentPasswordDialogState extends State<_ParentPasswordDialog> {
  static const _minPasswordLength = 4;

  final _controller = TextEditingController();
  _ParentLoginMode _mode = _ParentLoginMode.primary;
  String? _error;

  AppSettings get _settings => widget.settings;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchMode(_ParentLoginMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _controller.clear();
    });
  }

  void _submit() {
    final input = _controller.text;
    if (input.trim().length < _minPasswordLength) {
      setState(() => _error = 'Минимум $_minPasswordLength символа');
      AppFeedback.softHint();
      return;
    }

    final ok = switch (_mode) {
      _ParentLoginMode.primary => _settings.verifyParentPassword(input),
      _ParentLoginMode.backup => _settings.verifyParentBackupPassword(input),
      _ParentLoginMode.recovery => _settings.verifyParentRecoveryAnswer(input),
    };

    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _error = _wrongAnswerMessage());
    AppFeedback.softHint();
  }

  String _wrongAnswerMessage() {
    return switch (_mode) {
      _ParentLoginMode.primary => 'Неверный пароль',
      _ParentLoginMode.backup => 'Неверный запасной пароль',
      _ParentLoginMode.recovery => 'Неверный ответ',
    };
  }

  String get _title {
    return switch (_mode) {
      _ParentLoginMode.primary => 'Родительский контроль',
      _ParentLoginMode.backup => 'Запасной пароль',
      _ParentLoginMode.recovery => 'Контрольный вопрос',
    };
  }

  String get _fieldLabel {
    return switch (_mode) {
      _ParentLoginMode.primary => 'Пароль',
      _ParentLoginMode.backup => 'Запасной пароль',
      _ParentLoginMode.recovery => 'Ответ',
    };
  }

  Widget _linkButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUseBackup = _settings.parentPasswordBackup?.isNotEmpty ?? false;
    final canUseRecovery = _settings.hasParentRecovery;
    final obscure = _mode != _ParentLoginMode.recovery;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(_title, textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_mode == _ParentLoginMode.recovery)
              Text(
                _settings.parentRecoveryQuestion ?? '',
                style: Theme.of(context).textTheme.titleSmall,
              )
            else
              Text(
                _mode == _ParentLoginMode.primary
                    ? 'Введите пароль для входа'
                    : 'Введите запасной пароль',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            ObscuredTextField(
              controller: _controller,
              labelText: _fieldLabel,
              errorText: _error,
              obscure: obscure,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_mode == _ParentLoginMode.primary && canUseBackup)
              _linkButton(
                'Забыли основной пароль?',
                () => _switchMode(_ParentLoginMode.backup),
              ),
            if (_mode == _ParentLoginMode.backup && canUseRecovery)
              _linkButton(
                'Забыли и запасной?',
                () => _switchMode(_ParentLoginMode.recovery),
              ),
            if (_mode != _ParentLoginMode.primary)
              _linkButton(
                'Вернуться к основному паролю',
                () => _switchMode(_ParentLoginMode.primary),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Войти')),
      ],
    );
  }
}
