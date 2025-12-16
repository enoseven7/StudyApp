import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../services/subject_services.dart';
import '../services/task_service.dart';

enum PlannerView { today, week, calendar }

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  PlannerView _view = PlannerView.today;
  DateTime? _draftDue;
  TaskPriority _draftPriority = TaskPriority.medium;
  Recurrence _draftRecurrence = Recurrence.none;
  int _draftInterval = 1;
  bool _reminderEnabled = false;
  int _reminderMinutes = 60;
  int? _selectedSubjectId;
  int? _selectedTopicId;
  bool _showCompleted = false;

  bool _loading = true;
  List<TaskOccurrence> _occurrences = [];
  List<Subject> _subjects = [];

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedCalendarDay = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final subjects = await subjectService.getSubjects();
    final occurrences = await _fetchTasksForView();
    setState(() {
      _subjects = subjects;
      _occurrences = occurrences;
      _loading = false;
    });
  }

  Future<List<TaskOccurrence>> _fetchTasksForView() {
    final now = DateTime.now();
    switch (_view) {
      case PlannerView.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        return taskService.tasksForRange(
          start,
          end,
          subjectId: _selectedSubjectId,
          topicId: _selectedTopicId,
          includeCompleted: _showCompleted,
        );
      case PlannerView.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        return taskService.tasksForRange(
          start,
          end,
          subjectId: _selectedSubjectId,
          topicId: _selectedTopicId,
          includeCompleted: _showCompleted,
        );
      case PlannerView.calendar:
        final start = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
        final end = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1)
            .subtract(const Duration(seconds: 1));
        return taskService.tasksForRange(
          start,
          end,
          subjectId: _selectedSubjectId,
          topicId: _selectedTopicId,
          includeCompleted: _showCompleted,
        );
    }
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await taskService.createTask(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueAt: _draftDue,
      subjectId: _selectedSubjectId,
      topicId: _selectedTopicId,
      priority: _draftPriority,
      recurrence: _draftRecurrence,
      recurrenceIntervalDays: _draftInterval,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutes,
    );

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _draftDue = null;
      _draftRecurrence = Recurrence.none;
      _draftInterval = 1;
      _reminderEnabled = false;
      _reminderMinutes = 60;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Planner', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(colors, textTheme),
                    const SizedBox(height: 16),
                    _filters(colors, textTheme),
                    const SizedBox(height: 12),
                    _quickAddCard(colors, textTheme),
                    const SizedBox(height: 16),
                    _viewSwitcher(colors, textTheme),
                    const SizedBox(height: 12),
                    if (_view == PlannerView.calendar)
                      _calendarView(colors, textTheme)
                    else
                      _listView(colors, textTheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _hero(ColorScheme colors, TextTheme textTheme) {
    final openTasks = _occurrences.where((o) => !o.task.isCompleted).toList();
    final today = DateUtils.dateOnly(DateTime.now());
    final dueToday = openTasks.where((o) => DateUtils.isSameDay(o.dueAt, today)).length;
    final overdue = openTasks.where((o) => o.dueAt.isBefore(DateTime.now())).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [colors.surfaceContainer, colors.surfaceContainerHigh],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Stay organized", style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                "$dueToday due today • $overdue overdue • ${openTasks.length} open",
                style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _pill(colors, textTheme, Icons.flash_on, "Quick add a task"),
                  _pill(colors, textTheme, Icons.alarm, "Set optional reminders"),
                  _pill(colors, textTheme, Icons.repeat, "Recurring tasks supported"),
                ],
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.dashboard_customize, color: colors.primary),
        ],
      ),
    );
  }

  Widget _pill(ColorScheme colors, TextTheme textTheme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _filters(ColorScheme colors, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: _selectedSubjectId,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All subjects'),
              ),
              ..._subjects.map(
                (s) => DropdownMenuItem<int?>(
                  value: s.id,
                  child: Text(s.name),
                ),
              ),
            ],
            onChanged: (val) async {
              setState(() => _selectedSubjectId = val);
              _occurrences = await _fetchTasksForView();
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 170,
          child: SwitchListTile(
            dense: true,
            value: _showCompleted,
            onChanged: (val) async {
              setState(() => _showCompleted = val);
              _occurrences = await _fetchTasksForView();
              setState(() {});
            },
            title: const Text('Show completed'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _quickAddCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_task, color: colors.primary),
              const SizedBox(width: 8),
              Text("Quick add", style: textTheme.titleMedium),
              const Spacer(),
              ElevatedButton(
                onPressed: _addTask,
                child: const Text('Add task'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task title',
              hintText: 'e.g., Draft essay outline',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _chipButton(
                colors,
                icon: Icons.calendar_today,
                label: _draftDue == null
                    ? 'Set due date'
                    : 'Due ${_formatShortDateTime(_draftDue!)}',
                onTap: _pickDueDate,
              ),
              _chipButton(
                colors,
                icon: Icons.priority_high,
                label: 'Priority: ${_draftPriority.name}',
                onTap: () => _cyclePriority(),
              ),
              _chipButton(
                colors,
                icon: Icons.repeat,
                label: _recurrenceLabel(),
                onTap: () => _showRecurrenceSheet(context),
              ),
              _chipButton(
                colors,
                icon: Icons.alarm,
                label: _reminderEnabled
                    ? 'Reminder: $_reminderMinutes min before'
                    : 'Add reminder (optional)',
                onTap: () => _toggleReminder(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewSwitcher(ColorScheme colors, TextTheme textTheme) {
    return Wrap(
      spacing: 10,
      children: [
        _viewChip(colors, textTheme, PlannerView.today, "Today"),
        _viewChip(colors, textTheme, PlannerView.week, "This week"),
        _viewChip(colors, textTheme, PlannerView.calendar, "Calendar"),
      ],
    );
  }

  Widget _viewChip(ColorScheme colors, TextTheme textTheme, PlannerView view, String label) {
    final selected = _view == view;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        setState(() {
          _view = view;
          if (view != PlannerView.calendar) {
            _selectedCalendarDay = DateUtils.dateOnly(DateTime.now());
          }
        });
        _occurrences = await _fetchTasksForView();
        setState(() {});
      },
    );
  }

  Widget _listView(ColorScheme colors, TextTheme textTheme) {
    final grouped = <DateTime, List<TaskOccurrence>>{};
    for (final occ in _occurrences) {
      final day = DateUtils.dateOnly(occ.dueAt);
      grouped.putIfAbsent(day, () => []).add(occ);
    }

    if (grouped.isEmpty) {
      return _emptyState(colors, textTheme);
    }

    final days = grouped.keys.toList()..sort();
    return Column(
      children: days.map((day) {
        final items = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDayHeading(day),
                style: textTheme.titleMedium,
              ),
            ),
            ...items.map((occ) => _taskTile(colors, textTheme, occ)),
            const SizedBox(height: 6),
          ],
        );
      }).toList(),
    );
  }

  Widget _calendarView(ColorScheme colors, TextTheme textTheme) {
    final firstDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    final startWeekday = firstDayOfMonth.weekday;
    final totalCells = startWeekday - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final grouped = <DateTime, List<TaskOccurrence>>{};
    for (final occ in _occurrences) {
      final day = DateUtils.dateOnly(occ.dueAt);
      grouped.putIfAbsent(day, () => []).add(occ);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () async {
                setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                });
                _occurrences = await _fetchTasksForView();
                setState(() {});
              },
            ),
            Text(
              "${_calendarMonth.year} - ${_calendarMonth.month.toString().padLeft(2, '0')}",
              style: textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () async {
                setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                });
                _occurrences = await _fetchTasksForView();
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            final cellIndex = index - (startWeekday - 1);
            final dayNumber = cellIndex + 1;
            if (cellIndex < 0 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(_calendarMonth.year, _calendarMonth.month, dayNumber);
            final isSelected = DateUtils.isSameDay(date, _selectedCalendarDay);
            final dayTasks = grouped[DateUtils.dateOnly(date)] ?? [];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCalendarDay = DateUtils.dateOnly(date));
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? colors.primary.withOpacity(0.12) : colors.surfaceContainerHigh,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayNumber.toString(),
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                    if (dayTasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}",
                            style: textTheme.bodySmall?.copyWith(color: colors.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          "Tasks on ${_formatDayHeading(_selectedCalendarDay)}",
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(grouped[_selectedCalendarDay]?.map((occ) => _taskTile(colors, textTheme, occ)) ??
            [_emptyState(colors, textTheme)]),
      ],
    );
  }

  Widget _taskTile(ColorScheme colors, TextTheme textTheme, TaskOccurrence occ) {
    final task = occ.task;
    final subject = _subjects.firstWhere(
      (s) => s.id == task.subjectId,
      orElse: () => Subject()..name = '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (val) async {
                  await taskService.toggleComplete(task, val ?? false);
                  await _loadData();
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: textTheme.titleMedium),
                    if (task.description != null && task.description!.isNotEmpty)
                      Text(
                        task.description!,
                        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _infoChip(
                          colors,
                          icon: Icons.schedule,
                          label: _formatShortDateTime(occ.dueAt),
                        ),
                        _infoChip(
                          colors,
                          icon: Icons.flag,
                          label: "Priority: ${task.priority.name}",
                        ),
                        if (task.reminderEnabled)
                          _infoChip(
                            colors,
                            icon: Icons.alarm_on,
                            label: "Reminder ${task.reminderMinutesBefore}m before",
                          ),
                        if (task.recurrence != Recurrence.none)
                          _infoChip(
                            colors,
                            icon: Icons.repeat,
                            label: _recurrenceLabelForTask(task),
                          ),
                        if (task.subjectId != null && subject.name.isNotEmpty)
                          _infoChip(
                            colors,
                            icon: Icons.book_outlined,
                            label: subject.name,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await taskService.deleteTask(task.id);
                  await _loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No tasks yet. Add one to keep your study plan on track.",
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipButton(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ColorScheme colors, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _draftDue ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draftDue ?? now),
    );
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 9,
      pickedTime?.minute ?? 0,
    );
    setState(() => _draftDue = combined);
  }

  void _cyclePriority() {
    setState(() {
      switch (_draftPriority) {
        case TaskPriority.low:
          _draftPriority = TaskPriority.medium;
          break;
        case TaskPriority.medium:
          _draftPriority = TaskPriority.high;
          break;
        case TaskPriority.high:
          _draftPriority = TaskPriority.low;
          break;
      }
    });
  }

  String _formatShortDateTime(DateTime date) {
    final time = TimeOfDay.fromDateTime(date);
    return "${date.month}/${date.day} • ${time.format(context)}";
  }

  String _formatDayHeading(DateTime date) {
    final weekDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    return "$weekDay, ${date.month}/${date.day}";
  }

  String _recurrenceLabel() {
    if (_draftRecurrence == Recurrence.none) return "No recurrence";
    final interval = _draftInterval <= 1 ? '' : ' every $_draftInterval';
    return switch (_draftRecurrence) {
      Recurrence.daily => "Repeats$interval day(s)",
      Recurrence.weekly => "Repeats$interval week(s)",
      Recurrence.monthly => "Repeats$interval month(s)",
      Recurrence.none => "No recurrence",
    };
  }

  String _recurrenceLabelForTask(Task task) {
    final interval = task.recurrenceIntervalDays <= 1 ? '' : ' every ${task.recurrenceIntervalDays}';
    return switch (task.recurrence) {
      Recurrence.daily => "Repeats$interval day(s)",
      Recurrence.weekly => "Repeats$interval week(s)",
      Recurrence.monthly => "Repeats$interval month(s)",
      Recurrence.none => "No recurrence",
    };
  }

  Future<void> _showRecurrenceSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recurrence", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: Recurrence.values.map((rec) {
                      return ChoiceChip(
                        label: Text(rec.name),
                        selected: _draftRecurrence == rec,
                        onSelected: (_) {
                          setModalState(() => _draftRecurrence = rec);
                          setState(() => _draftRecurrence = rec);
                        },
                      );
                    }).toList(),
                  ),
                  if (_draftRecurrence != Recurrence.none) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Interval (days)"),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            if (_draftInterval > 1) {
                              setModalState(() => _draftInterval--);
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(_draftInterval.toString()),
                        IconButton(
                          onPressed: () {
                            setModalState(() => _draftInterval++);
                            setState(() {});
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleReminder(BuildContext context) async {
    if (!_reminderEnabled) {
      setState(() => _reminderEnabled = true);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Reminder", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Slider(
                  value: _reminderMinutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  label: "$_reminderMinutes minutes before",
                  onChanged: (val) {
                    setModalState(() => _reminderMinutes = val.round());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _reminderEnabled = false);
                        Navigator.pop(context);
                      },
                      child: const Text('Disable'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
