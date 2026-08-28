import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ProgressChip extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const ProgressChip({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final isAllDone = completedCount == totalCount;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28.0,
          vertical: 6.0,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isAllDone
                    ? AppColors.successSoft.withValues(alpha: 0.45)
                    : AppColors.line.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppShapes.radiusSm),
              ),
              child: Text(
                '$completedCount dari $totalCount selesai',
                style: GoogleFonts.plusJakartaSans(
                  color: isAllDone
                      ? AppColors.successBold
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
