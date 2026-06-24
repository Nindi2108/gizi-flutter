// lib/models/skill.dart

class Skill {
  final String id;
  final String athleteId;
  final String beltLevel; // e.g., "white", "yellow", "green", ...
  final String skillName;
  final bool isMastered;

  Skill({
    required this.id,
    required this.athleteId,
    required this.beltLevel,
    required this.skillName,
    required this.isMastered,
  });

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as String,
      athleteId: map['athlete_id'] as String,
      beltLevel: map['belt_level'] as String,
      skillName: map['skill_name'] as String,
      isMastered: map['is_mastered'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'athlete_id': athleteId,
      'belt_level': beltLevel,
      'skill_name': skillName,
      'is_mastered': isMastered,
    };
  }
}
