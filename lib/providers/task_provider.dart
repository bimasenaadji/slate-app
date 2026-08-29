import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';

// Provider for the Hive Box
final taskBoxProvider = Provider<Box>((ref) {
  return Hive.box('tasks');
});

// Provider for the TaskNotifier
final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>((
  ref,
) {
  final box = ref.watch(taskBoxProvider);
  return TaskNotifier(box);
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final Box _box;
  Timer? _midnightTimer;
  DateTime _lastCheckedDay = DateTime.now();

  TaskNotifier(this._box) : super([]) {
    _loadTasksAndCheckMidnight();
    _startMidnightTimer();
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
            if (task.isDone) {
              // Purge completed tasks from yesterday (Clean Slate)
              keysToDelete.add(key);
            } else {
              // Automatic Carry-Over: Save active incomplete tasks with visual demotion
              final carriedOverTask = task.copyWith(isCarriedOver: true);
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

  // Executes midnight evaluation and clean slate carry-over rules
  void _clearAllTasks() {
    _loadTasksAndCheckMidnight();
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

  // Add a new task (Today or Tomorrow Queue)
  void addTask(String title, {bool isForTomorrow = false}) {
    if (title.trim().isEmpty) return;
    
    final now = DateTime.now();

    if (isForTomorrow) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final task = TaskModel(
        id: now.microsecondsSinceEpoch.toString(),
        title: title.trim(),
        createdAt: now,
        scheduledDate: tomorrow,
        orderIndex: 0,
        isCarriedOver: false,
      );
      _box.put(task.id, task.toMap());
      // Do not add to state (Tomorrow Queue is hidden from today's list)
      return;
    }

    final minOrder = state.isEmpty
        ? 0
        : state.map((t) => t.orderIndex).reduce((a, b) => a < b ? a : b);

    final task = TaskModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      createdAt: now,
      orderIndex: minOrder - 1,
      isCarriedOver: false,
    );
    _box.put(task.id, task.toMap());
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

  // Update task title (Edit Task) & Re-activate Carry-Over task
  void updateTask(String id, String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    state = [
      for (final task in state)
        if (task.id == id)
          (() {
            // Re-activate: reset isCarriedOver flag when edited
            final updated = task.copyWith(
              title: trimmed,
              isCarriedOver: false,
            );
            _box.put(id, updated.toMap());
            return updated;
          })()
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
            final updated = task.copyWith(isDone: !task.isDone);
            _box.put(id, updated.toMap());
            return updated;
          })()
        else
          task,
    ];
  }

  // Delete a task
  void deleteTask(String id) {
    _box.delete(id);
    state = state.where((task) => task.id != id).toList();
  }

  // Restore a previously deleted task at its exact orderIndex (Undo Action)
  void restoreTask(TaskModel task) {
    if (state.any((t) => t.id == task.id)) return; // Prevent duplicate restoration
    final updatedList = [...state, task];
    updatedList.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    _box.put(task.id, task.toMap());
    state = updatedList;
  }

  // Helper for quick testing of carry-over & purge logic
  void debugInjectCarryOverSample() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final task1 = TaskModel(
      id: 'debug_active_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Tugas kemarin belum selesai',
      createdAt: yesterday,
      isDone: false,
    );
    final task2 = TaskModel(
      id: 'debug_done_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Tugas kemarin sudah selesai',
      createdAt: yesterday,
      isDone: true,
    );
    _box.put(task1.id, task1.toMap());
    _box.put(task2.id, task2.toMap());
    _loadTasksAndCheckMidnight();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
