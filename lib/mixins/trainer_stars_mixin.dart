import 'package:flutter/material.dart';

import '../data/hive/local_storage.dart';
import '../gamification/rewards_service.dart';

/// Загрузка и обновление баланса звёзд на игровых экранах.
mixin TrainerStarsMixin<T extends StatefulWidget> on State<T> {
  int trainerStars = 0;

  void initTrainerStars() {
    trainerStars = LocalStorage.isReady
        ? RewardsService.availableStars()
        : 0;
  }

  void reloadTrainerStars() {
    if (!mounted) return;
    setState(() {
      trainerStars = LocalStorage.isReady
          ? RewardsService.availableStars()
          : 0;
    });
  }
}
