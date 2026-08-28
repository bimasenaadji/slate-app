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

  // Load existing tasks from Box and remove tasks created on previous days (Clean Slate)
  void _loadTasksAndCheckMidnight() {
    final now = DateTime.now();
    final List<TaskModel> allTasks = [];
    final List<dynamic> keysToDelete = [];

    for (var key in _box.keys) {
      final map = _box.get(key);
      if (map != null && map is Map) {
        try {
          final task = TaskModel.fromMap(map);
          if (_isBeforeToday(task.createdAt, now)) {
            keysToDelete.add(key);
          } else {
            allTasks.add(task);
          }
        } catch (e) {
          // If formatting is invalid, delete it to maintain a clean slate
          keysToDelete.add(key);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      _box.deleteAll(keysToDelete);
    }

    // Sort tasks: put non-completed tasks on top, sorted by creation time (newest first)
    // Actually, simple sorting by newest first is extremely clean.
    allTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = allTasks;
  }

  // Public method to refresh tasks and check midnight cleanup
  Future<void> refreshTasks() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _loadTasksAndCheckMidnight();
  }

  // Timer to check for day transition while the app is active
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

  // Clear all tasks (for midnight cleanup)
  void _clearAllTasks() {
    _box.clear();
    state = [];
  }

  // Add a new task
  void addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = TaskModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      createdAt: DateTime.now(),
    );
    _box.put(task.id, task.toMap());
    state = [task, ...state];
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

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
