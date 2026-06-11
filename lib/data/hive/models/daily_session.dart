class DailySessionState {
  const DailySessionState({required this.dateKey, required this.minutes});

  final String dateKey;
  final int minutes;

  Map<String, dynamic> toMap() => {'dateKey': dateKey, 'minutes': minutes};

  factory DailySessionState.fromMap(Map<dynamic, dynamic> map) {
    return DailySessionState(
      dateKey: map['dateKey'] as String? ?? '',
      minutes: map['minutes'] as int? ?? 0,
    );
  }
}
