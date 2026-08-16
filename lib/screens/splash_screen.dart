import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/cinema_logo.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Iconic Harry Potter / Cinematic Backdrop
  static const String _harryPotterPoster = 'https://image.tmdb.org/t/p/original/1stU2qFa47v6t9vKq1t6iT5m7vG.jpg';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LandingScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Harry Potter Cinematic Poster Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: CachedNetworkImage(
                imageUrl: _harryPotterPoster,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF050505)),
              ),
            ),
          ),

          // Deep Dark Gradient Mask
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                    Color(0xFF050505),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Center Logo and Title Animation
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Web Cinema Logo
                    const CinemaLogoWidget(size: 64, animate: true),
                    const SizedBox(height: 18),

                    // Brand Typography
                    Text(
                      'PURE CINEMA',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'UNCOMPROMISED 4K STREAMING',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Subtle Progress Ring
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version Tag
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'PURE CINEMA STUDIOS · 2026',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
