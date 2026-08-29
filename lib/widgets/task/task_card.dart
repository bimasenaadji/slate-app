import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isTomorrowCard;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.isTomorrowCard = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  bool _isDismissing = false;

  late final AnimationController _collapseController;
  late final Animation<double> _sizeFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fluid height collapse controller (280ms)
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 280),
      value: 1.0, // Fully visible by default to prevent initial load shift & reorder flicker
    );

    _sizeFadeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  void _handleDelete() {
    if (_isDismissing) return;
    _isDismissing = true;

    HapticFeedback.lightImpact();

    // Fluid height collapse & fade out (280ms)
    _collapseController.reverse().then((_) {
      if (mounted) {
        widget.onDelete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeFadeAnimation,
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _sizeFadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical: 6.0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppShapes.radiusLg),
            child: Slidable(
              key: ValueKey(widget.task.id),
              enabled: !_isDismissing,

              // Swipe Right to Complete (Start Pane) - Disabled in Tomorrow dimension
              startActionPane: widget.isTomorrowCard
                  ? null
                  : ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (context) => widget.onToggle(),
                          backgroundColor: AppColors.successSoft,
                          foregroundColor: AppColors.successBold,
                          icon: widget.task.isDone
                              ? Icons.undo_rounded
                              : Icons.check_circle_rounded,
                          label: widget.task.isDone ? 'Batal' : 'Selesai',
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppShapes.radiusLg),
                            bottomLeft: Radius.circular(AppShapes.radiusLg),
                          ),
                        ),
                      ],
                    ),

              // Swipe Left to Delete (End Pane with Fluid Collapse)
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                dismissible: DismissiblePane(
                  onDismissed: _handleDelete,
                  closeOnCancel: true,
                ),
                children: [
                  SlidableAction(
                    onPressed: (context) => _handleDelete(),
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

              // Main Card Content with Tap to Open TaskDialog Edit Mode
              child: GestureDetector(
                onTap: _isDismissing ? null : widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: widget.task.isDone
                        ? AppColors.surfaceCard.withValues(alpha: 0.25)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppShapes.radiusLg),
                    boxShadow: AppShapes.shadowSoftSm,
                    border: Border.all(
                      color: widget.task.isDone
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Checklist Circle Component
                      _TaskChecklistCircle(
                        isDone: widget.task.isDone,
                        isTomorrowCard: widget.isTomorrowCard,
                        isDismissing: _isDismissing,
                        onToggle: widget.onToggle,
                      ),
                      const SizedBox(width: AppConstants.paddingMd),

                      // Title & Subtitle Content Component
                      Expanded(
                        child: _TaskContent(
                          task: widget.task,
                          isTomorrowCard: widget.isTomorrowCard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive checklist circle for completing/uncompleting tasks
class _TaskChecklistCircle extends StatelessWidget {
  final bool isDone;
  final bool isTomorrowCard;
  final bool isDismissing;
  final VoidCallback onToggle;

  const _TaskChecklistCircle({
    required this.isDone,
    required this.isTomorrowCard,
    required this.isDismissing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isTomorrowCard) {
      // In Tomorrow dimension: Show quiet crescent indicator (non-completable)
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF0F3F8),
          border: Border.all(
            color: const Color(0xFFD2D6DC),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.nightlight_round,
            size: 13,
            color: Color(0xFF81838A),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: isDismissing ? null : onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? AppColors.successSoft : Colors.transparent,
          border: Border.all(
            color: isDone ? AppColors.successBold : AppColors.line,
            width: 2,
          ),
        ),
        child: isDone
            ? const Center(
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.successBold,
                ),
              )
            : null,
      ),
    );
  }
}

/// Compact 2-line title with ellipsis and animated date subtitle
class _TaskContent extends StatelessWidget {
  final TaskModel task;
  final bool isTomorrowCard;

  const _TaskContent({
    required this.task,
    this.isTomorrowCard = false,
  });

  Color get _titleColor {
    if (task.isDone) {
      return AppColors.textSecondary.withValues(alpha: 0.5);
    }
    if (task.isCarriedOver) {
      return AppColors.textSecondary; // Muted grey #81838A for visual demotion
    }
    return AppColors.textPrimary; // Deep dark #1A1B20 for active today tasks
  }

  String _formatDateTime(DateTime dateTime) {
    if (isTomorrowCard) {
      return 'Direncanakan untuk besok';
    }
    try {
      final formatted =
          DateFormat('EEEE, d MMMM • HH:mm', 'id_ID').format(dateTime);
      return task.isCarriedOver ? 'Sisa kemarin • $formatted' : formatted;
    } catch (e) {
      final formatted = DateFormat('EEEE, d MMMM • HH:mm').format(dateTime);
      return task.isCarriedOver ? 'Sisa kemarin • $formatted' : formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title: Compact 2-Line Limit with Ellipsis
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
          style: AppTypography.bodyPrimary.copyWith(
            color: _titleColor,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
          child: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle: Animated Date with Carry-Over / Tomorrow Indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            _formatDateTime(task.createdAt),
            key: ValueKey(
              '${isTomorrowCard}_${task.isCarriedOver}_${task.createdAt.millisecondsSinceEpoch}',
            ),
            style: AppTypography.captionSecondary.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
