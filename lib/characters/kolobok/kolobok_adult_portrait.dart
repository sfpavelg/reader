import 'package:flutter/material.dart';

/// Статичный портрет взрослого Колобка из слоёв (тело, глаза, рот).
class KolobokAdultPortrait extends StatelessWidget {
  const KolobokAdultPortrait({
    super.key,
    required this.size,
    this.wink = false,
  });

  static const _base = 'assets/characters/kolobok/stage_06_adult';

  final double size;
  final bool wink;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              '$_base/body_layer.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -size * 0.035),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 90),
                child: Transform.scale(
                  key: ValueKey(wink),
                  scale: 0.72,
                  child: Image.asset(
                    wink
                        ? '$_base/eyes_wink_layer.png'
                        : '$_base/eyes_open_layer.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, size * 0.11),
              child: Transform.scale(
                scale: 0.68,
                child: Image.asset(
                  '$_base/mouth_smile_layer.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
