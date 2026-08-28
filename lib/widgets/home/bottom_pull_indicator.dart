import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class BottomPullIndicator extends StatelessWidget {
  final double pullDistance;
  final double threshold;

  const BottomPullIndicator({
    super.key,
    required this.pullDistance,
    this.threshold = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (pullDistance <= 4) return const SizedBox.shrink();

    final pullProgress = (pullDistance / threshold).clamp(0.0, 1.0);
    final isReadyToRelease = pullDistance >= threshold;

    return Positioned(
      bottom: 24 + (pullDistance * 0.2),
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          scale: 0.85 + (0.15 * pullProgress),
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isReadyToRelease
                    ? AppColors.textPrimary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1B20).withValues(
                    alpha: isReadyToRelease ? 0.12 : 0.06,
                  ),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rotating Icon
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReadyToRelease
                        ? AppColors.textPrimary
                        : const Color(0xFFF4F7FC),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: pullProgress * math.pi, // 180 degree rotation
                      child: Icon(
                        Icons.add_rounded,
                        color: isReadyToRelease
                            ? Colors.white
                            : AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Responsive Text
                Text(
                  isReadyToRelease
                      ? 'Lepaskan untuk mencatat'
                      : 'Tarik ke atas...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isReadyToRelease
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isReadyToRelease
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    letterSpacing: -0.2,
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
