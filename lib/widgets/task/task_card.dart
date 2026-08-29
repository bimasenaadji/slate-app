import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _focusNode = FocusNode();

    // Passive save: triggers when tapping outside or losing focus
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.title != widget.task.title && !_isEditing) {
      _controller.text = widget.task.title;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveChanges();
    }
  }

  void _startEditing() {
    if (widget.task.isDone) return; // Do not edit already completed tasks

    // 1. Tactile haptic feedback (Light Impact upon tap)
    HapticFeedback.lightImpact();

    setState(() {
      _isEditing = true;
      _controller.text = widget.task.title;
      // 2. Position cursor automatically at the end of the text
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });

    // 3. Auto-focus and open the keyboard with zero delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _saveChanges() {
    if (!_isEditing) return;

    final trimmed = _controller.text.trim();

    // Blank text safety net: Revert to previous title if accidentally emptied
    if (trimmed.isEmpty) {
      _controller.text = widget.task.title;
    } else if (trimmed != widget.task.title) {
      widget.onEdit(trimmed);
    }

    setState(() {
      _isEditing = false;
    });
    _focusNode.unfocus();
  }

  Color get _titleColor {
    if (widget.task.isDone) {
      return AppColors.textSecondary.withValues(alpha: 0.5);
    }
    if (widget.task.isCarriedOver) {
      return AppColors.textSecondary; // Muted grey #81838A for visual demotion
    }
    return AppColors.textPrimary; // Deep dark #1A1B20 for active today tasks
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      final formatted =
          DateFormat('EEEE, d MMMM • HH:mm', 'id_ID').format(dateTime);
      return widget.task.isCarriedOver ? 'Sisa kemarin • $formatted' : formatted;
    } catch (e) {
      final formatted = DateFormat('EEEE, d MMMM • HH:mm').format(dateTime);
      return widget.task.isCarriedOver ? 'Sisa kemarin • $formatted' : formatted;
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
          key: ValueKey(widget.task.id),
          // Gesture lock: disable swipe actions while editing to prevent gesture conflicts
          enabled: !_isEditing,

          // Swipe Right to Complete (Start Pane)
          startActionPane: ActionPane(
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

          // Swipe Left to Delete (End Pane)
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) => widget.onDelete(),
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

          // Main Card Content with Single Tap to Edit
          child: GestureDetector(
            onTap: _isEditing ? null : _startEditing,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AppColors.surfaceExpanded
                    : widget.task.isDone
                        ? AppColors.surfaceCard.withValues(alpha: 0.25)
                        : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppShapes.radiusLg),
                boxShadow: _isEditing
                    ? AppShapes.shadowSoftMd
                    : AppShapes.shadowSoftSm,
                border: Border.all(
                  color: _isEditing
                      ? Colors.white
                      : widget.task.isDone
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Interactive Checklist Circle (Independent tap handler)
                  GestureDetector(
                    onTap: widget.onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.task.isDone
                            ? AppColors.successSoft
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.task.isDone
                              ? AppColors.successBold
                              : AppColors.line,
                          width: 2,
                        ),
                      ),
                      child: widget.task.isDone
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

                  // Task Title: Seamless Zero-Layout-Shift Swap between Text and TextField
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isEditing)
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: AppTypography.bodyPrimary.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            maxLines: null,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                            onSubmitted: (_) => _saveChanges(),
                          )
                        else
                          Text(
                            widget.task.title,
                            style: AppTypography.bodyPrimary.copyWith(
                              color: _titleColor,
                              decoration: widget.task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(widget.task.createdAt),
                          style: AppTypography.captionSecondary.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
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
      ),
    );
  }
}
