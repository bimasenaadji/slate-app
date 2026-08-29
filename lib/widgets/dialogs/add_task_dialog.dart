import 'package:flutter/material.dart';
import 'task_dialog.dart';
export 'task_dialog.dart';

/// Backward-compatible delegate for TaskDialog.showCreate
class AddTaskDialog {
  static void show(BuildContext context, TaskAddCallback onAdd) {
    TaskDialog.showCreate(context, onAdd: onAdd);
  }
}
