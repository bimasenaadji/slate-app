import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  String _formatDateTime(DateTime dateTime) {
    try {
      return DateFormat('EEEE, d MMMM • HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return DateFormat('EEEE, d MMMM • HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMd,
        vertical: 6.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.radiusLg),
        child: Slidable(
          key: ValueKey(task.id),

          // Swipe Right to Complete (Start Pane)
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) => onToggle(),
                backgroundColor: AppColors.successSoft,
                foregroundColor: AppColors.successBold,
                icon: task.isDone
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded,
                label: task.isDone ? 'Batal' : 'Selesai',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppShapes.radiusLg),
                  bottomLeft: Radius.circular(AppShapes.radiusLg),
                ),
              ),
            ],
          ),

          // Swipe Left to Delete (End Pane)
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) => onDelete(),
                backgroundColor: AppColors.dangerSoft,
                foregroundColor: AppColors.dangerBold,
                icon: Icons.delete_rounded,
                label: 'Hapus',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppShapes.radiusLg),
                  bottomRight: Radius.circular(AppShapes.radiusLg),
                ),
              ),
            ],
          ),

          // Main Card Content
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: task.isDone
                  ? AppColors.surfaceCard.withValues(alpha: 0.25)
                  : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppShapes.radiusLg),
              boxShadow: AppShapes.shadowSoftSm,
              border: Border.all(
                color: task.isDone
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Custom Interactive Checklist Circle
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone
                          ? AppColors.successSoft
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isDone
                            ? AppColors.successBold
                            : AppColors.line,
                        width: 2,
                      ),
                    ),
                    child: task.isDone
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.successBold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMd),

                // Task Title and Creation Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.bodyPrimary.copyWith(
                          color: task.isDone
                              ? AppColors.textSecondary.withValues(alpha: 0.5)
                              : AppColors.textPrimary,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(task.createdAt),
                        style: AppTypography.captionSecondary.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
