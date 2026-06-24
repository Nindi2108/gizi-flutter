// lib/models/schedule.dart

class Schedule {
  final String id;
  final String coachId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String recurrence; // e.g., "weekly", "monthly", "none"

  Schedule({
    required this.id,
    required this.coachId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.recurrence,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      coachId: map['coach_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      recurrence: map['recurrence'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'recurrence': recurrence,
    };
  }
}
