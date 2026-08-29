import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/constants/time_anchor.dart';

typedef TaskAddCallback = void Function(
  String title,
  bool isForTomorrow,
  String? reminderAnchor,
);

typedef TaskEditCallback = void Function(
  String title,
  String? reminderAnchor,
);

/// Modal dialog with frosted glass backdrop for creating or editing a task with Mindful Anchors
class TaskDialog extends StatefulWidget {
  final TaskAddCallback? onAdd;
  final TaskEditCallback? onEditSave;
  final String? initialText;
  final String? initialAnchor;
  final bool isEditMode;
  final bool isTomorrowDefault;

  const TaskDialog({
    super.key,
    this.onAdd,
    this.onEditSave,
    this.initialText,
    this.initialAnchor,
    this.isEditMode = false,
    this.isTomorrowDefault = false,
  });

  /// Displays the task creation dialog with elastic spring overshoot physics
  static Future<void> showCreate(
    BuildContext context, {
    required TaskAddCallback onAdd,
    bool isTomorrowDefault = false,
  }) {
    return _show(
      context,
      dialog: TaskDialog(
        onAdd: onAdd,
        isTomorrowDefault: isTomorrowDefault,
      ),
      barrierLabel: AppConstants.newNoteTitle,
    );
  }

  /// Displays the task edit dialog with elastic spring overshoot physics
  static Future<void> showEdit(
    BuildContext context, {
    required String initialText,
    String? initialAnchor,
    required TaskEditCallback onSave,
  }) {
    return _show(
      context,
      dialog: TaskDialog(
        initialText: initialText,
        initialAnchor: initialAnchor,
        onEditSave: onSave,
        isEditMode: true,
      ),
      barrierLabel: 'Edit Tugas',
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required Widget dialog,
    required String barrierLabel,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, anim1, anim2) => dialog,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Elastic spring curve with subtle overshoot and settle
        final springCurvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        // Slide up from bottom with spring physics
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.22),
          end: Offset.zero,
        ).animate(springCurvedAnimation);

        // Scale up from 0.88 with spring overshoot
        final scaleAnimation = Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(springCurvedAnimation);

        // Gentle blur & fade
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          reverseCurve: Curves.easeIn,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * animation.value,
            sigmaY: 8 * animation.value,
          ),
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
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
  bool _isForTomorrow = false;
  String? _selectedAnchor;
  bool _isAnchorAutoDetected = false;
  bool _isTomorrowAutoDetected = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isForTomorrow = widget.isTomorrowDefault;
    _selectedAnchor = widget.initialAnchor;
    _controller = TextEditingController(text: widget.initialText ?? '');
    _controller.addListener(_detectKeywords);

    // Set cursor at the end of the text if editing
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    // Auto-focus input field and open keyboard smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_detectKeywords);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Dynamically activates or clears time anchors & tomorrow queue as keywords are typed or deleted
  void _detectKeywords() {
    final text = _controller.text;

    // 1. Detect time anchor keywords using TimeAnchorDetector
    final detected = TimeAnchorDetector.detectAnchor(text);
    final detectedAnchor = detected?.key;

    if (detectedAnchor != null) {
      if (detectedAnchor != _selectedAnchor) {
        _isAnchorAutoDetected = true;
        HapticFeedback.selectionClick();
        setState(() {
          _selectedAnchor = detectedAnchor;
        });
      }
    } else if (_isAnchorAutoDetected && _selectedAnchor != null) {
      // Keyword was deleted by user via backspace
      _isAnchorAutoDetected = false;
      setState(() {
        _selectedAnchor = null;
      });
    }

    // 2. Detect tomorrow keyword (in create mode)
    if (!widget.isEditMode) {
      final hasTomorrow = TimeAnchorDetector.detectTomorrow(text);
      if (hasTomorrow && !_isForTomorrow) {
        _isTomorrowAutoDetected = true;
        HapticFeedback.selectionClick();
        setState(() {
          _isForTomorrow = true;
        });
      } else if (!hasTomorrow && _isTomorrowAutoDetected) {
        // "besok" keyword was deleted by user via backspace
        _isTomorrowAutoDetected = false;
        setState(() {
          _isForTomorrow = widget.isTomorrowDefault;
        });
      }
    }
  }

  void _handleTomorrowToggle() {
    _isTomorrowAutoDetected = false; // User took manual control
    HapticFeedback.lightImpact();
    setState(() {
      _isForTomorrow = !_isForTomorrow;
    });
  }

  void _handleAnchorToggle(String anchor) {
    _isAnchorAutoDetected = false; // User took manual control
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnchor = _selectedAnchor == anchor ? null : anchor;
    });
  }

  void _submit() {
    if (_isSubmitting) return; // Prevent double-submit on rapid tap
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _isSubmitting = true;
      Navigator.of(context).pop();
      if (widget.isEditMode) {
        widget.onEditSave?.call(text, _selectedAnchor);
      } else {
        widget.onAdd?.call(text, _isForTomorrow, _selectedAnchor);
      }
    } else {
      Navigator.of(context).pop();
    }
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
                // 1. Header with Title and Tomorrow Crescent Moon Toggle
                _DialogHeader(
                  isEditMode: widget.isEditMode,
                  isForTomorrow: _isForTomorrow,
                  onTomorrowToggle: _handleTomorrowToggle,
                ),
                const SizedBox(height: 14),

                // 2. Multiline Brain Dump Input Area
                _DialogInputArea(
                  controller: _controller,
                  focusNode: _focusNode,
                  isEditMode: widget.isEditMode,
                  isForTomorrow: _isForTomorrow,
                  onSubmit: _submit,
                ),
                const SizedBox(height: 16),

                // 3. Discrete Mindful Time Anchors (Pagi, Siang, Malam)
                _DialogTimeAnchors(
                  selectedAnchor: _selectedAnchor,
                  onAnchorToggle: _handleAnchorToggle,
                ),
                const SizedBox(height: 20),

                // 4. Modal Actions: Batal & Simpan
                _DialogActions(
                  onSubmit: _submit,
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header component displaying dialog title and tomorrow queue toggle
class _DialogHeader extends StatelessWidget {
  final bool isEditMode;
  final bool isForTomorrow;
  final VoidCallback onTomorrowToggle;

  const _DialogHeader({
    required this.isEditMode,
    required this.isForTomorrow,
    required this.onTomorrowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          isEditMode ? 'Edit Tugas' : AppConstants.newNoteTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
            letterSpacing: -0.2,
          ),
        ),

        // Tomorrow Queue Crescent Moon Toggle (Hidden in Edit Mode)
        if (!isEditMode)
          GestureDetector(
            onTap: onTomorrowToggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isForTomorrow
                    ? const Color(0xFF19191B)
                    : const Color(0xFFF0F3F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upcoming_outlined,
                    size: 15,
                    color: isForTomorrow
                        ? Colors.white
                        : const Color(0xFF81838A),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Besok',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isForTomorrow
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isForTomorrow
                          ? Colors.white
                          : const Color(0xFF81838A),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Flexible multi-line input field supporting 1-5 lines and internal scrolling for brain dumps
class _DialogInputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditMode;
  final bool isForTomorrow;
  final VoidCallback onSubmit;

  const _DialogInputArea({
    required this.controller,
    required this.focusNode,
    required this.isEditMode,
    required this.isForTomorrow,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1E1E),
        height: 1.4,
      ),
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      maxLines: 5,
      minLines: 1,
      scrollPhysics: const BouncingScrollPhysics(),
      decoration: InputDecoration(
        hintText: isEditMode
            ? 'Tulis catatan tugas...'
            : isForTomorrow
                ? 'Tulis untuk besok...'
                : AppConstants.inputPlaceholder,
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
      onSubmitted: (_) => onSubmit(),
    );
  }
}

/// Discrete 1-Tap Mindful Time Anchors: Pagi (09:00), Siang (13:00), Malam (19:00)
class _DialogTimeAnchors extends StatelessWidget {
  final String? selectedAnchor;
  final ValueChanged<String> onAnchorToggle;

  const _DialogTimeAnchors({
    required this.selectedAnchor,
    required this.onAnchorToggle,
  });

  Widget _buildAnchorPill({required TimeAnchor anchor}) {
    final isSelected = selectedAnchor == anchor.key;

    return GestureDetector(
      onTap: () => onAnchorToggle(anchor.key),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19191B) : const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              anchor.icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF5A5C63),
            ),
            const SizedBox(width: 5),
            Text(
              '${anchor.label} ${anchor.timeHint}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF5A5C63),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < TimeAnchor.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildAnchorPill(anchor: TimeAnchor.values[i]),
          ],
        ],
      ),
    );
  }
}

/// Action buttons: 'Batal' and 'Simpan' pill
class _DialogActions extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _DialogActions({
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Batal Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            onTap: onSubmit,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
    );
  }
}
