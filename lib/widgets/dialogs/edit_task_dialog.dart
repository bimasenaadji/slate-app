import 'package:flutter/material.dart';
import 'task_dialog.dart';
export 'task_dialog.dart';

/// Backward-compatible delegate for TaskDialog.showEdit
class EditTaskDialog {
  static void show(
    BuildContext context, {
    required String initialTitle,
    required ValueChanged<String> onSave,
  }) {
    TaskDialog.showEdit(
      context,
      initialTitle: initialTitle,
      onSave: onSave,
    );
  }
}
