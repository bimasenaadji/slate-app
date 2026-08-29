import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable floating pill Undo Toast using OverlayEntry for 100% artifact-free shadows
class UndoSnackBar {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    // 1. Immediately cancel prior timer & remove active toast to prevent overlapping
    _dismissTimer?.cancel();
    _activeEntry?.remove();
    _activeEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _UndoToastWidget(
        message: message,
        duration: duration,
        onUndo: () {
          _removeEntry(entry);
          onUndo();
        },
        onDismiss: () {
          _removeEntry(entry);
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void _removeEntry(OverlayEntry entry) {
    if (_activeEntry == entry) {
      _dismissTimer?.cancel();
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }
}

class _UndoToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  const _UndoToastWidget({
    required this.message,
    required this.duration,
    required this.onUndo,
    required this.onDismiss,
  });

  @override
  State<_UndoToastWidget> createState() => _UndoToastWidgetState();
}

class _UndoToastWidgetState extends State<_UndoToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _controller.forward();

    // Start auto-dismiss countdown
    _timer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleUndoTap() {
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onUndo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate Android 3-button nav / iOS home indicator height
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveBottom =
        systemBottomInset > 0 ? systemBottomInset + 16.0 : 28.0;

    return Positioned(
      bottom: effectiveBottom,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.45),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        ),
        child: FadeTransition(
          opacity: _controller,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    // Primary ambient elevation shadow (smooth & natural)
                    BoxShadow(
                      color: const Color(0xFF19191B).withValues(alpha: 0.12),
                      offset: const Offset(0, 10),
                      blurRadius: 28,
                      spreadRadius: -2,
                    ),
                    // Secondary soft depth shadow
                    BoxShadow(
                      color: const Color(0xFF19191B).withValues(alpha: 0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtle indicator dot
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF19191B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Context message text
                    Flexible(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Pill action button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleUndoTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19191B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Batalkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
