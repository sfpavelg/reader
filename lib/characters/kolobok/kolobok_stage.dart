import 'package:flutter/material.dart';

enum KolobokStage {
  tadpole(
    level: 1,
    title: 'Головастик',
    subtitle: 'Первые движения',
    color: Color(0xFFFFB15A),
  ),
  sprout(
    level: 2,
    title: 'Росток',
    subtitle: 'Учится держать форму',
    color: Color(0xFFFFA14A),
  ),
  child(
    level: 3,
    title: 'Малыш',
    subtitle: 'Появились ручки',
    color: Color(0xFFFF9238),
  ),
  teen(
    level: 4,
    title: 'Подросток',
    subtitle: 'Становится смелее',
    color: Color(0xFFFF8428),
  ),
  young(
    level: 5,
    title: 'Юный Колобок',
    subtitle: 'Почти взрослый',
    color: Color(0xFFFF781E),
  ),
  adult(
    level: 6,
    title: 'Колобок',
    subtitle: 'Взрослая особь',
    color: Color(0xFFFF6F16),
  );

  const KolobokStage({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final int level;
  final String title;
  final String subtitle;
  final Color color;
}
