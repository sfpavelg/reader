import 'package:flutter/material.dart';

/// Цвета звёзд по смыслу: прогресс vs валюта.
abstract final class StarColors {
  /// Левые / трафаретные — фиолетовые.
  static const progress = Color(0xFF8E24AA);

  /// Ярче при полёте к трафарету.
  static const progressGlow = Color(0xFFCE93D8);

  /// Правые / кошелёк / цена / трата — ярко-оранжевые.
  static const currency = Color(0xFFFF6D00);

  /// Мягкий акцент для фона чипов траты.
  static const currencySoft = Color(0xFFFFB74D);
}
