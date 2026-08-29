import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/utils/date_helper.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onTomorrowTap;
  final int tomorrowTaskCount;

  const HomeHeader({
    super.key,
    required this.onAddTap,
    required this.onTomorrowTap,
    this.tomorrowTaskCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 28.0,
          right: 28.0,
          top: 36.0,
          bottom: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pure, Clean Editorial Date Typography (No awkward chevron)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    DateHelper.getGreeting(),
                    key: ValueKey(DateHelper.getGreeting()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    DateHelper.formatTodayDate(),
                    key: ValueKey(DateHelper.formatTodayDate()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),

            // Top-Right Action Buttons: Tomorrow Moon Peek Button + Add Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tomorrow Queue Peek Button (Crescent Moon with dynamic count)
                GestureDetector(
                  onTap: onTomorrowTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: tomorrowTaskCount > 0
                          ? const Color(0xFF19191B)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppShapes.radiusMd),
                      border: Border.all(
                        color: tomorrowTaskCount > 0
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: AppShapes.shadowSoftSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upcoming_outlined,
                          color: tomorrowTaskCount > 0
                              ? Colors.white
                              : AppColors.textPrimary,
                          size: 20,
                        ),
                        if (tomorrowTaskCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$tomorrowTaskCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Add Task Action Button (+)
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    width: 44,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppShapes.radiusMd),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: AppShapes.shadowSoftSm,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
