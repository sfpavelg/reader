import 'package:flutter/material.dart';

/// Подпись выпадающего меню в AppBar — заметный акцент, что есть выбор.
class TrainerMenuLabel extends StatelessWidget {
  const TrainerMenuLabel(this.label, {super.key});

  /// Фиолетовый акцент для пунктов «Простой / Средний / …».
  static const accent = Color(0xFF6A3DE8);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Icon(Icons.arrow_drop_down, color: accent),
      ],
    );
  }
}
