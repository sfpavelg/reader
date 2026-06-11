class UserProfile {
  const UserProfile({
    required this.childName,
    required this.createdAtMs,
    this.totalStars = 0,
    this.totalTrainingMinutes = 0,
  });

  final String childName;
  final int createdAtMs;
  final int totalStars;
  final int totalTrainingMinutes;

  UserProfile copyWith({
    String? childName,
    int? createdAtMs,
    int? totalStars,
    int? totalTrainingMinutes,
  }) {
    return UserProfile(
      childName: childName ?? this.childName,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      totalStars: totalStars ?? this.totalStars,
      totalTrainingMinutes:
          totalTrainingMinutes ?? this.totalTrainingMinutes,
    );
  }

  factory UserProfile.defaults() => UserProfile(
        childName: 'Читатель',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      childName: map['childName'] as String? ?? 'Читатель',
      createdAtMs: map['createdAtMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      totalStars: map['totalStars'] as int? ?? 0,
      totalTrainingMinutes: map['totalTrainingMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'childName': childName,
        'createdAtMs': createdAtMs,
        'totalStars': totalStars,
        'totalTrainingMinutes': totalTrainingMinutes,
      };
}
