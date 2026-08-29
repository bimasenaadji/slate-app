import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

/// Zen Empty State with One-Shot Lottie Opening, Idle Levitation, & Interactive Tap Spring
class EmptyState extends StatefulWidget {
  const EmptyState({super.key});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _floatingController;
  late final AnimationController _bounceController;

  late final Animation<double> _floatingAnim;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 1. One-shot Lottie Opening Controller
    _lottieController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Once opening completes, begin gentle infinite floating levitation
          _floatingController.repeat(reverse: true);
        }
      });

    // 2. Smooth Zen Floating Levitation (2.4s peaceful oscillation)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _floatingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Tactile Spring Tap Controller (Squish -> Overshoot -> Settle)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.93)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.93, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 25,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _floatingController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Interactive Floating Animation Component
            GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _floatingController,
                  _bounceController,
                ]),
                builder: (context, child) {
                  final floatVal = _floatingAnim.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Breathing Glow
                      _ZenAuraGlow(floatProgress: floatVal),

                      // Floating & Spring Responsive Lottie Box
                      Transform.translate(
                        offset: Offset(0, -8.0 * floatVal),
                        child: Transform.scale(
                          scale: _bounceAnim.value,
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Lottie.asset(
                              'assets/No Data Found.json',
                              controller: _lottieController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _lottieController
                                  ..duration = composition.duration
                                  ..forward();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Zen Typography Block
            const _EmptyStateTypography(),
          ],
        ),
      ),
    );
  }
}

/// Ambient Radial Glow that smoothly pulses and breathes with the floating box
class _ZenAuraGlow extends StatelessWidget {
  final double floatProgress;

  const _ZenAuraGlow({required this.floatProgress});

  @override
  Widget build(BuildContext context) {
    final auraScale = 1.0 + (0.05 * floatProgress);
    final auraOpacity = 0.30 + (0.20 * floatProgress);

    return Transform.scale(
      scale: auraScale,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFD6E3F8).withValues(alpha: auraOpacity),
              const Color(0xFFF4F7FC).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Static Zen Title & Subtitle for Empty State
class _EmptyStateTypography extends StatelessWidget {
  const _EmptyStateTypography();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppConstants.emptyStateTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.emptyStateSubtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: -0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
