import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/utils/date_helper.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../dialogs/task_dialog.dart';
import '../feedback/undo_snackbar.dart';
import '../task/task_card.dart';

/// Frosted Glass Bottom Sheet for peeking and managing the Tomorrow Task Queue (H+1)
class TomorrowSheet extends ConsumerStatefulWidget {
  const TomorrowSheet({super.key});

  /// Displays the Tomorrow Peek Sheet with frosted backdrop
  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (context) => const TomorrowSheet(),
    );
  }

  @override
  ConsumerState<TomorrowSheet> createState() => _TomorrowSheetState();
}

class _TomorrowSheetState extends ConsumerState<TomorrowSheet> {
  bool _isModalOpen = false;

  void _openAddTomorrowTask() {
    if (_isModalOpen) return;
    _isModalOpen = true;

    HapticFeedback.lightImpact();
    TaskDialog.showCreate(
      context,
      isTomorrowDefault: true,
      onAdd: (title, isForTomorrow, reminderAnchor) {
        ref.read(taskProvider.notifier).addTask(
              title,
              isForTomorrow: true,
              reminderAnchor: reminderAnchor,
            );
      },
    ).whenComplete(() {
      if (mounted) {
        _isModalOpen = false;
      }
    });
  }

  void _openEditTomorrowTask(TaskModel task) {
    if (_isModalOpen) return;
    _isModalOpen = true;

    HapticFeedback.lightImpact();
    TaskDialog.showEdit(
      context,
      initialText: task.title,
      initialAnchor: task.reminderAnchor,
      onSave: (newTitle, reminderAnchor) =>
          ref.read(taskProvider.notifier).updateTask(
                task.id,
                newTitle,
                reminderAnchor: reminderAnchor,
                clearReminderAnchor: reminderAnchor == null,
              ),
    ).whenComplete(() {
      if (mounted) {
        _isModalOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final notifier = ref.read(taskProvider.notifier);
    final screenHeight = MediaQuery.of(context).size.height;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, -6),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD2D6DC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Sheet Header: Title, Tomorrow Date, & Close Button
            _SheetHeader(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // 3. Tomorrow Tasks List OR Zen Empty State
            Expanded(
              child: tomorrowTasks.isEmpty
                  ? const _TomorrowEmptyState()
                  : _TomorrowListView(
                      tasks: tomorrowTasks,
                      onTaskTap: _openEditTomorrowTask,
                      onTaskDelete: (task) {
                        notifier.deleteTask(task.id);
                        UndoSnackBar.show(
                          context,
                          message: 'Rencana besok dihapus.',
                          onUndo: () => notifier.restoreTask(task),
                        );
                      },
                    ),
            ),

            // 4. Bottom Fast Add Button for Tomorrow
            _TomorrowAddButton(onAdd: _openAddTomorrowTask),
          ],
        ),
      ),
    );
  }
}

/// Header with title, tomorrow date, and close button
class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.upcoming_outlined,
                    size: 18,
                    color: Color(0xFF19191B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Rencana Esok Hari',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Besok • ${DateHelper.formatTomorrowDate()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFEAEFF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF5A5C63),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zen empty state when no tasks are queued for tomorrow
class _TomorrowEmptyState extends StatelessWidget {
  const _TomorrowEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upcoming_outlined,
                size: 28,
                color: Color(0xFF81838A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada rencana untuk besok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Siapkan ide dan tugas lebih awal agar esok hari dimulai dengan tenang.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list of tomorrow tasks
class _TomorrowListView extends StatelessWidget {
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onTaskTap;
  final ValueChanged<TaskModel> onTaskDelete;

  const _TomorrowListView({
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          key: ValueKey('tomorrow_task_${task.id}'),
          task: task,
          isTomorrowCard: true,
          onTap: () => onTaskTap(task),
          onToggle: () {}, // Disabled in tomorrow dimension
          onDelete: () => onTaskDelete(task),
        );
      },
    );
  }
}

/// Bottom action button for quick tomorrow task creation
class _TomorrowAddButton extends StatelessWidget {
  final VoidCallback onAdd;

  const _TomorrowAddButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF19191B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShapes.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Catat untuk Esok Hari',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
