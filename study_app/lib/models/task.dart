import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String title;

  String? description;

  DateTime? dueAt;

  bool isCompleted = false;

  int? subjectId;
  int? topicId;

  @enumerated
  TaskPriority priority = TaskPriority.medium;

  bool reminderEnabled = false;
  int reminderMinutesBefore = 60;

  @enumerated
  Recurrence recurrence = Recurrence.none;
  int recurrenceIntervalDays = 1;
  DateTime? recurrenceEndsAt;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

enum TaskPriority {
  low,
  medium,
  high,
}

enum Recurrence {
  none,
  daily,
  weekly,
  monthly,
}
