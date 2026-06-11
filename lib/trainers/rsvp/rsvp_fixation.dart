import 'package:flutter/material.dart';

/// Точка фиксации — красная буква в середине слова (RSVP-тренировка).
int rsvpFixationIndex(String word) {
  if (word.isEmpty) return 0;
  return (word.length - 1) ~/ 2;
}

TextSpan buildRsvpWordSpan({
  required String word,
  required TextStyle baseStyle,
  required Color fixationColor,
}) {
  if (word.isEmpty) {
    return TextSpan(text: '', style: baseStyle);
  }

  final fix = rsvpFixationIndex(word);
  final before = word.substring(0, fix);
  final fixation = word.substring(fix, fix + 1);
  final after = word.substring(fix + 1);

  return TextSpan(
    style: baseStyle,
    children: [
      TextSpan(text: before),
      TextSpan(
        text: fixation,
        style: baseStyle.copyWith(color: fixationColor),
      ),
      TextSpan(text: after),
    ],
  );
}
