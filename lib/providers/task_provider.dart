import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

// Provider for the Hive Box
final taskBoxProvider = Provider<Box>((ref) {
  return Hive.box('tasks');
});

// Provider for the TaskNotifier (Today's Tasks)
final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>((
  ref,
) {
  final box = ref.watch(taskBoxProvider);
  return TaskNotifier(box);
});

// Provider for the Tomorrow Tasks (H+1 Queue)
final tomorrowTasksProvider = Provider<List<TaskModel>>((ref) {
  ref.watch(taskProvider); // Triggers re-computation when tasks are modified
  final box = ref.watch(taskBoxProvider);
  final List<TaskModel> list = [];
  for (var key in box.keys) {
    final map = box.get(key);
    if (map != null && map is Map) {
      try {
        final task = TaskModel.fromMap(map);
        if (task.scheduledDate != null) {
          list.add(task);
        }
      } catch (_) {}
    }
  }
  list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return list;
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final Box _box;
  final NotificationService _notifService = NotificationService();
  Timer? _midnightTimer;
  DateTime _lastCheckedDay = DateTime.now();
  void Function()? onMidnightMagicTriggered;

  TaskNotifier(this._box) : super([]) {
    _loadTasksAndCheckMidnight();
    _startMidnightTimer();
    _notifService.init();
  }

  // Load existing tasks from Box and execute Clean Slate, Carry-Over, & Tomorrow Queue rules
  void _loadTasksAndCheckMidnight() {
    final now = DateTime.now();
    final List<TaskModel> allTasks = [];
    final List<dynamic> keysToDelete = [];

    for (var key in _box.keys) {
      final map = _box.get(key);
      if (map != null && map is Map) {
        try {
          final task = TaskModel.fromMap(map);

          // 1. Check if this task belongs to the Tomorrow Queue
          if (task.scheduledDate != null) {
            if (_isFutureDate(task.scheduledDate!, now)) {
              // Still in the future -> keep in Hive, hidden from today's screen
              continue;
            } else {
              // Scheduled date has arrived (00:00) -> promote to active today task!
              final promotedTask = task.copyWith(
                clearScheduledDate: true,
                isCarriedOver: false,
              );
              _box.put(key, promotedTask.toMap());
              allTasks.add(promotedTask);
              continue;
            }
          }

          // 2. Check yesterday tasks (Clean Slate & Automatic Carry-Over)
          if (_isBeforeToday(task.createdAt, now)) {
            _notifService.cancelNotification(task.id);
            if (task.isDone) {
              // Purge completed tasks from yesterday (Clean Slate)
              keysToDelete.add(key);
            } else {
              // Automatic Carry-Over: Save active incomplete tasks with visual demotion
              final carriedOverTask = task.copyWith(
                isCarriedOver: true,
                clearReminderAnchor: true, // Reset anchor on carry-over
              );
              _box.put(key, carriedOverTask.toMap());
              allTasks.add(carriedOverTask);
            }
          } else {
            allTasks.add(task);
          }
        } catch (e) {
          // If formatting is invalid, delete it to maintain data integrity
          keysToDelete.add(key);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      _box.deleteAll(keysToDelete);
    }

    // Sort tasks primarily by user-defined orderIndex
    allTasks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    state = allTasks;
  }

  // Public method to refresh tasks and check midnight cleanup
  Future<void> refreshTasks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _loadTasksAndCheckMidnight();
  }

  // Public method to execute midnight magic sequence (Clean Slate + Carry-Over + Tomorrow Promotion)
  void performMidnightMagic() {
    _loadTasksAndCheckMidnight();
  }

  // Timer to check for day transition while the app is actively running
  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    _midnightTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      if (now.day != _lastCheckedDay.day ||
          now.month != _lastCheckedDay.month ||
          now.year != _lastCheckedDay.year) {
        _lastCheckedDay = now;
        _clearAllTasks();
      }
    });
  }

  // Executes midnight evaluation and triggers cinematic transition if active
  void _clearAllTasks() {
    if (onMidnightMagicTriggered != null) {
      onMidnightMagicTriggered!();
    } else {
      _loadTasksAndCheckMidnight();
    }
  }

  // Helper method to check if a date is in the future
  bool _isFutureDate(DateTime date, DateTime today) {
    final localDate = date.toLocal();
    final localToday = today.toLocal();
    return localDate.year > localToday.year ||
        (localDate.year == localToday.year &&
            localDate.month > localToday.month) ||
        (localDate.year == localToday.year &&
            localDate.month == localToday.month &&
            localDate.day > localToday.day);
  }

  // Helper method to check if a date is before today
  bool _isBeforeToday(DateTime date, DateTime today) {
    final localDate = date.toLocal();
    final localToday = today.toLocal();
    return localDate.year < localToday.year ||
        (localDate.year == localToday.year &&
            localDate.month < localToday.month) ||
        (localDate.year == localToday.year &&
            localDate.month == localToday.month &&
            localDate.day < localToday.day);
  }

  // Add a new task (Today or Tomorrow Queue with optional Mindful Anchor)
  void addTask(
    String title, {
    bool isForTomorrow = false,
    String? reminderAnchor,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();

    if (isForTomorrow) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final task = TaskModel(
        id: now.microsecondsSinceEpoch.toString(),
        title: trimmed,
        createdAt: now,
        scheduledDate: tomorrow,
        orderIndex: 0,
        isCarriedOver: false,
        reminderAnchor: reminderAnchor,
      );
      _box.put(task.id, task.toMap());

      if (reminderAnchor != null) {
        _notifService.scheduleAnchorNotification(
          taskId: task.id,
          title: task.title,
          anchor: reminderAnchor,
          isForTomorrow: true,
        );
      }

      state = [...state]; // Triggers tomorrowTasksProvider update
      return;
    }

    final minOrder = state.isEmpty
        ? 0
        : state.map((t) => t.orderIndex).reduce((a, b) => a < b ? a : b);

    final task = TaskModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: trimmed,
      createdAt: now,
      orderIndex: minOrder - 1,
      isCarriedOver: false,
      reminderAnchor: reminderAnchor,
    );
    _box.put(task.id, task.toMap());

    if (reminderAnchor != null) {
      _notifService.scheduleAnchorNotification(
        taskId: task.id,
        title: task.title,
        anchor: reminderAnchor,
        isForTomorrow: false,
      );
    }

    state = [task, ...state];
  }

  // Reorder task priority position (Drag-and-Drop)
  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= state.length ||
        newIndex < 0 ||
        newIndex >= state.length) {
      return;
    }

    final updatedList = List<TaskModel>.from(state);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    // Normalize orderIndex and persist to Hive
    final persistedList = <TaskModel>[];
    for (int i = 0; i < updatedList.length; i++) {
      final task = updatedList[i].copyWith(orderIndex: i);
      _box.put(task.id, task.toMap());
      persistedList.add(task);
    }

    state = persistedList;
  }

  // Update task title & Mindful Anchor
  void updateTask(
    String id,
    String newTitle, {
    String? reminderAnchor,
    bool clearReminderAnchor = false,
  }) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final existingMap = _box.get(id);
    if (existingMap != null && existingMap is Map) {
      try {
        final existingTask = TaskModel.fromMap(existingMap);
        final updated = existingTask.copyWith(
          title: trimmed,
          isCarriedOver: false,
          reminderAnchor: reminderAnchor,
          clearReminderAnchor: clearReminderAnchor,
        );
        _box.put(id, updated.toMap());

        // Update notification schedule
        final finalAnchor = clearReminderAnchor
            ? null
            : (reminderAnchor ?? existingTask.reminderAnchor);

        if (finalAnchor != null) {
          _notifService.scheduleAnchorNotification(
            taskId: updated.id,
            title: updated.title,
            anchor: finalAnchor,
            isForTomorrow: updated.scheduledDate != null,
          );
        } else {
          _notifService.cancelNotification(updated.id);
        }
      } catch (_) {}
    }

    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(
            title: trimmed,
            isCarriedOver: false,
            reminderAnchor: reminderAnchor,
            clearReminderAnchor: clearReminderAnchor,
          )
        else
          task,
    ];
  }

  // Toggle completion status of a task
  void toggleTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          (() {
            final willBeDone = !task.isDone;
            final updated = task.copyWith(isDone: willBeDone);
            _box.put(id, updated.toMap());
            if (willBeDone) {
              _notifService.cancelNotification(id);
            }
            return updated;
          })()
        else
          task,
    ];
  }

  // Delete a task (from both Today and Tomorrow queue)
  void deleteTask(String id) {
    _notifService.cancelNotification(id);
    _box.delete(id);
    state = state.where((task) => task.id != id).toList();
  }

  // Restore a previously deleted task at its exact orderIndex (Undo Action)
  void restoreTask(TaskModel task) {
    _box.put(task.id, task.toMap());
    if (task.reminderAnchor != null && !task.isDone) {
      _notifService.scheduleAnchorNotification(
        taskId: task.id,
        title: task.title,
        anchor: task.reminderAnchor!,
        isForTomorrow: task.scheduledDate != null,
      );
    }

    if (task.scheduledDate == null) {
      if (state.any((t) => t.id == task.id)) return;
      final updatedList = [...state, task];
      updatedList.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = updatedList;
    } else {
      state = [...state]; // Trigger tomorrowTasksProvider update
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
