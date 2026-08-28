import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

enum TaskDialogMode { create, edit }

/// Unified, reusable dialog for both creating and editing tasks (DRY Principle)
class TaskDialog extends StatefulWidget {
  final TaskDialogMode mode;
  final String? initialTitle;
  final ValueChanged<String> onSubmit;

  const TaskDialog({
    super.key,
    required this.mode,
    this.initialTitle,
    required this.onSubmit,
  });

  /// Displays the task creation dialog
  static void showCreate(
    BuildContext context, {
    required ValueChanged<String> onAdd,
  }) {
    _show(
      context,
      mode: TaskDialogMode.create,
      onSubmit: onAdd,
    );
  }

  /// Displays the task edit dialog
  static void showEdit(
    BuildContext context, {
    required String initialTitle,
    required ValueChanged<String> onSave,
  }) {
    _show(
      context,
      mode: TaskDialogMode.edit,
      initialTitle: initialTitle,
      onSubmit: onSave,
    );
  }

  static void _show(
    BuildContext context, {
    required TaskDialogMode mode,
    String? initialTitle,
    required ValueChanged<String> onSubmit,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: mode == TaskDialogMode.create
          ? AppConstants.newNoteTitle
          : AppConstants.editNoteTitle,
      barrierColor: Colors.black.withValues(alpha: 0.14),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return TaskDialog(
          mode: mode,
          initialTitle: initialTitle,
          onSubmit: onSubmit,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * animation.value,
            sigmaY: 8 * animation.value,
          ),
          child: Transform.scale(
            scale: 0.92 + (0.08 * curvedValue),
            alignment: Alignment.center,
            child: Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  bool get _isEditMode => widget.mode == TaskDialogMode.edit;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');

    // For edit mode, position cursor at the very end of the string
    if (_isEditMode && _controller.text.isNotEmpty) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    // Auto-focus input field and pop up keyboard smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // In edit mode, only trigger if modified; in create mode, always trigger
      if (!_isEditMode || text != widget.initialTitle) {
        widget.onSubmit(text);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          elevation: 0,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 14),
                  blurRadius: 40,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Title
                Text(
                  _isEditMode
                      ? AppConstants.editNoteTitle
                      : AppConstants.newNoteTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),

                // Note / Task Input Field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E1E),
                    height: 1.4,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _isEditMode ? null : AppConstants.inputPlaceholder,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E9E9E),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Batal & Simpan
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Batal Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Simpan Pill Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19191B),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Simpan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
