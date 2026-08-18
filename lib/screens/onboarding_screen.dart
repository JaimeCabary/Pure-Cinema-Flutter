import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/fonts.dart';
import '../widgets/cinema_logo.dart';
import 'landing_screen.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Masterpiece Cinema\nin True 4K Ultra HD',
      'subtitle': 'Stream curated film masterpieces, Hollywood blockbusters, and award-winning motion pictures with high bitrate fidelity.',
      'badge': '4K HDR CINEMA',
      'image': 'https://image.tmdb.org/t/p/original/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
    },
    {
      'title': '10,000+ Live TV\nWorldwide Broadcasts',
      'subtitle': 'Experience seamless 60 FPS live sports, international news, cinema networks, and VLC network streaming on demand.',
      'badge': 'GLOBAL LIVE TV',
      'image': 'https://image.tmdb.org/t/p/original/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
    },
    {
      'title': 'Intelligent CineBot\nAI Film Companion',
      'subtitle': 'Powered by Google GenAI. Discover hidden gems, navigate channels, and control your theater experience with natural speech.',
      'badge': 'AI ASSISTANT',
      'image': 'https://image.tmdb.org/t/p/original/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg',
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LandingScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Slide Image
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (ctx, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: slide['image']!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF0A0A0A)),
                  ),

                  // Cinematic Dark Vignette & Multi-stop Gradients
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x66000000),
                          Color(0xEE050505),
                          Color(0xFF050505),
                        ],
                        stops: [0.0, 0.35, 0.70, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top App Bar with Cinema Logo & Skip button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CinemaLogoWidget(size: 24, animate: true),
                      const SizedBox(width: 8),
                      Text(
                        'PURE CINEMA',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'SKIP',
                      style: AppFonts.sCoreDream(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content & Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _slides[_currentPage]['badge']!,
                    style: AppFonts.sCoreDream(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  _slides[_currentPage]['title']!,
                  style: AppFonts.sCoreDream(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  _slides[_currentPage]['subtitle']!,
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Slide Indicators
                Row(
                  children: List.generate(_slides.length, (idx) {
                    final isActive = idx == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: isActive ? 24 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Primary Next / Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'GET STARTED' : 'CONTINUE',
                      style: AppFonts.sCoreDream(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
