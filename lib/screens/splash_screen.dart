import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi Sutradara Animasi (Tempo: 1.5 detik per siklus)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. Tentukan jangkauan opasitas kedipan: dari 0.25 (redup) ke 1.0 (terang)
    _animation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves
            .easeInOut, // Kurva transisi lambat-cepat-lambat agar kedipan halus
      ),
    );

    // 3. Mainkan animasi berkedip secara bolak-balik tanpa henti (repeat & reverse)
    _controller.repeat(reverse: true);

    // 4. Jadwalkan perpindahan halaman ke HomeScreen setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // "Bakar jembatan" dan ganti layar dengan efek transisi silang (cross-fade) yang sangat premium
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(
              milliseconds: 700,
            ), // Transisi pudar halus
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Patuhi etika kebersihan: matikan sutradara animasi agar terhindar dari Memory Leak!
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.bgMain, // Gunakan latar belakang kanvas Slate kita
      body: Center(
        // Gunakan widget khusus transisi pudar untuk menerapkan animasi kedipan kita
        child: FadeTransition(
          opacity: _animation,
          child: Text(
            'Slate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing:
                  -1.0, // Merapatkan jarak antar huruf agar terlihat sangat kokoh
            ),
          ),
        ),
      ),
    );
  }
}
