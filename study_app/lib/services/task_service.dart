import 'package:isar/isar.dart';

import '../main.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskOccurrence {
  TaskOccurrence({required this.task, required this.dueAt});

  final Task task;
  final DateTime dueAt;
}

class TaskService {
  Future<int> createTask({
    required String title,
    String? description,
    DateTime? dueAt,
    int? subjectId,
    int? topicId,
    TaskPriority priority = TaskPriority.medium,
    Recurrence recurrence = Recurrence.none,
    int recurrenceIntervalDays = 1,
    DateTime? recurrenceEndsAt,
    bool reminderEnabled = false,
    int reminderMinutesBefore = 60,
  }) async {
    final task = Task()
      ..title = title
      ..description = description
      ..dueAt = dueAt
      ..subjectId = subjectId
      ..topicId = topicId
      ..priority = priority
      ..recurrence = recurrence
      ..recurrenceIntervalDays = recurrenceIntervalDays
      ..recurrenceEndsAt = recurrenceEndsAt
      ..reminderEnabled = reminderEnabled
      ..reminderMinutesBefore = reminderMinutesBefore
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final id = await isar.writeTxn(() => isar.tasks.put(task));
    task.id = id;
    if (task.reminderEnabled && task.dueAt != null && !task.isCompleted) {
      await NotificationService.instance.scheduleTaskReminder(task);
    }
    return id;
  }

  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    await isar.writeTxn(() => isar.tasks.put(task));
    await NotificationService.instance.cancelTaskReminder(task.id);
    if (task.reminderEnabled && task.dueAt != null && !task.isCompleted) {
      await NotificationService.instance.scheduleTaskReminder(task);
    }
  }

  Future<void> toggleComplete(Task task, bool isCompleted) async {
    task.isCompleted = isCompleted;
    await updateTask(task);
  }

  Future<void> deleteTask(int id) async {
    await NotificationService.instance.cancelTaskReminder(id);
    await isar.writeTxn(() => isar.tasks.delete(id));
  }

  Future<List<TaskOccurrence>> tasksForRange(
    DateTime start,
    DateTime end, {
    int? subjectId,
    int? topicId,
    bool includeCompleted = true,
  }) async {
    final tasks = await isar.tasks.where().anyId().findAll();
    final filtered = tasks.where((task) {
      if (!includeCompleted && task.isCompleted) return false;
      if (subjectId != null && task.subjectId != subjectId) return false;
      if (topicId != null && task.topicId != topicId) return false;
      return true;
    });

    final occurrences = <TaskOccurrence>[];
    for (final task in filtered) {
      final due = task.dueAt ?? task.createdAt;
      if (!_isInRange(due, start, end)) continue;
      occurrences.add(TaskOccurrence(task: task, dueAt: due));

      if (task.recurrence != Recurrence.none && task.dueAt != null) {
        occurrences.addAll(_expandRecurrence(task, start, end));
      }
    }

    occurrences.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return occurrences;
  }

  Future<List<TaskOccurrence>> upcomingTasks({int days = 7}) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return tasksForRange(now, end, includeCompleted: false);
  }

  List<TaskOccurrence> _expandRecurrence(Task task, DateTime rangeStart, DateTime rangeEnd) {
    if (task.dueAt == null) return [];

    final occurrences = <TaskOccurrence>[];
    final intervalDays = switch (task.recurrence) {
      Recurrence.daily => 1,
      Recurrence.weekly => 7,
      Recurrence.monthly => 30, // approximate month span
      Recurrence.none => 0,
    } * (task.recurrenceIntervalDays <= 0 ? 1 : task.recurrenceIntervalDays);

    var next = task.dueAt!;
    final limit = task.recurrenceEndsAt ?? rangeEnd;

    while (true) {
      next = next.add(Duration(days: intervalDays));
      if (next.isAfter(limit) || next.isAfter(rangeEnd)) break;
      if (_isInRange(next, rangeStart, rangeEnd)) {
        occurrences.add(TaskOccurrence(task: task, dueAt: next));
      }
    }

    return occurrences;
  }

  bool _isInRange(DateTime date, DateTime start, DateTime end) {
    return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
        (date.isAtSameMomentAs(end) || date.isBefore(end));
  }
}

final taskService = TaskService();
