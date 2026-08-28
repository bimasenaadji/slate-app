import 'package:flutter_test/flutter_test.dart';
import 'package:slate/models/task_model.dart';

void main() {
  group('TaskModel Unit Tests', () {
    test('TaskModel copyWith works correctly', () {
      final task = TaskModel(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime(2026, 8, 25),
      );

      final updatedTask = task.copyWith(isDone: true);

      expect(updatedTask.id, '1');
      expect(updatedTask.title, 'Test Task');
      expect(updatedTask.isDone, true);
      expect(updatedTask.createdAt, DateTime(2026, 8, 25));
    });

    test('TaskModel toMap and fromMap serialization works correctly', () {
      final originalTask = TaskModel(
        id: '2',
        title: 'Serialization Test',
        isDone: true,
        createdAt: DateTime(2026, 8, 25),
      );

      final map = originalTask.toMap();
      final parsedTask = TaskModel.fromMap(map);

      expect(parsedTask.id, originalTask.id);
      expect(parsedTask.title, originalTask.title);
      expect(parsedTask.isDone, originalTask.isDone);
      expect(parsedTask.createdAt, originalTask.createdAt);
    });
  });
}
