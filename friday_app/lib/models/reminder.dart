/// A locally-stored reminder.
class Reminder {
  final int? id;
  final String title;
  final DateTime scheduledAt;
  final bool isCompleted;

  const Reminder({
    this.id,
    required this.title,
    required this.scheduledAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as int?,
        title: map['title'] as String,
        scheduledAt:
            DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int),
        isCompleted: (map['is_completed'] as int) == 1,
      );

  Reminder copyWith({
    int? id,
    String? title,
    DateTime? scheduledAt,
    bool? isCompleted,
  }) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
