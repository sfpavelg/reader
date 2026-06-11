class AppSettings {
  const AppSettings({
    this.soundEffectsEnabled = true,
    this.backgroundMusicEnabled = false,
    this.baseFontScale = 1.0,
    this.lastOpenedTrainerId,
  });

  final bool soundEffectsEnabled;
  final bool backgroundMusicEnabled;
  final double baseFontScale;
  final String? lastOpenedTrainerId;

  AppSettings copyWith({
    bool? soundEffectsEnabled,
    bool? backgroundMusicEnabled,
    double? baseFontScale,
    String? lastOpenedTrainerId,
  }) {
    return AppSettings(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      baseFontScale: baseFontScale ?? this.baseFontScale,
      lastOpenedTrainerId: lastOpenedTrainerId ?? this.lastOpenedTrainerId,
    );
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      soundEffectsEnabled: map['soundEffectsEnabled'] as bool? ?? true,
      backgroundMusicEnabled: map['backgroundMusicEnabled'] as bool? ?? false,
      baseFontScale: (map['baseFontScale'] as num?)?.toDouble() ?? 1.0,
      lastOpenedTrainerId: map['lastOpenedTrainerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'soundEffectsEnabled': soundEffectsEnabled,
        'backgroundMusicEnabled': backgroundMusicEnabled,
        'baseFontScale': baseFontScale,
        if (lastOpenedTrainerId != null)
          'lastOpenedTrainerId': lastOpenedTrainerId,
      };
}
