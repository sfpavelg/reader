import 'package:flutter/material.dart';

import 'app_feedback.dart';

/// Родительский шлюз: пример или удержание кнопки 3 секунды.
class ParentGate {
  ParentGate._();

  static Future<bool> show(BuildContext context) async {
    final mode = await showDialog<_GateMode>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _GateModeDialog(),
    );
    if (mode == null || !context.mounted) return false;

    switch (mode) {
      case _GateMode.math:
        return _MathGateDialog.show(context);
      case _GateMode.hold:
        return _HoldGateDialog.show(context);
    }
  }
}

enum _GateMode { math, hold }

class _GateModeDialog extends StatelessWidget {
  const _GateModeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Только для взрослых'),
      content: const Text('Выберите способ подтверждения:'),
      actions: [
        TextButton(
          onPressed: () {
            AppFeedback.tap();
            Navigator.pop(context, _GateMode.math);
          },
          child: const Text('Пример'),
        ),
        FilledButton(
          onPressed: () {
            AppFeedback.tap();
            Navigator.pop(context, _GateMode.hold);
          },
          child: const Text('Удержать 3 сек'),
        ),
      ],
    );
  }
}

class _MathGateDialog extends StatefulWidget {
  const _MathGateDialog();

  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MathGateDialog(),
    );
    return ok ?? false;
  }

  @override
  State<_MathGateDialog> createState() => _MathGateDialogState();
}

class _MathGateDialogState extends State<_MathGateDialog> {
  late final int _a;
  late final int _b;
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final seed = DateTime.now().millisecond;
    _a = 10 + seed % 15;
    _b = 10 + (seed ~/ 7) % 15;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == _a + _b) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _error = 'Попробуйте ещё раз');
    AppFeedback.softHint();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Родительский шлюз'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Сколько будет $_a + $_b ?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Ответ',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
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

class _HoldGateDialog extends StatefulWidget {
  const _HoldGateDialog();

  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HoldGateDialog(),
    );
    return ok ?? false;
  }

  @override
  State<_HoldGateDialog> createState() => _HoldGateDialogState();
}

class _HoldGateDialogState extends State<_HoldGateDialog> {
  double _progress = 0;

  void _onHoldTick() {
    setState(() => _progress = (_progress + 0.05).clamp(0, 1));
    if (_progress >= 1 && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Родительский шлюз'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Удерживайте кнопку 3 секунды'),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        Listener(
          onPointerDown: (_) {
            _progress = 0;
            _tickLoop();
          },
          onPointerUp: (_) => setState(() => _progress = 0),
          onPointerCancel: (_) => setState(() => _progress = 0),
          child: FilledButton(
            onPressed: () {},
            child: const Text('Удерживать'),
          ),
        ),
      ],
    );
  }

  Future<void> _tickLoop() async {
    while (_progress < 1 && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      _onHoldTick();
    }
  }
}
