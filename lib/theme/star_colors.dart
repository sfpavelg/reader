import 'package:flutter/material.dart';

/// Цвета звёзд по смыслу: прогресс vs валюта.
abstract final class StarColors {
  /// Левые / трафаретные — жёлтые.
  static const progress = Color(0xFFFFD600);

  /// Ярче при полёте к трафарету.
  static const progressGlow = Color(0xFFFFEA00);

  /// Правые / кошелёк / цена / трата — фиолетовые.
  static const currency = Color(0xFF8E24AA);

  /// Мягкий акцент для фона чипов траты.
  static const currencySoft = Color(0xFFCE93D8);
}
