import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/fonts.dart';
import '../widgets/cinema_logo.dart';
import '../services/tmdb_service.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'main_nav_screen.dart';

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
      'subtitle': 'Stream curated film masterpieces, Hollywood blockbusters, and award-winning motion pictures with direct studio bitrates.',
      'image': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1600&q=90', // Cinema Theater 4K
      'badge': '4K HDR CINEMA',
    },
    {
      'title': '10,000+ Worldwide\nLive TV Channels',
      'subtitle': 'Experience seamless 60 FPS live sports, international news, cinema networks, and global broadcasts on demand.',
      'image': 'https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=1600&q=90', // Live Studio Broadcast 4K
      'badge': '60 FPS BROADCAST',
    },
    {
      'title': 'UNCOMPROMISED\nCINEMA 4K',
      'subtitle': 'Experience master-quality motion pictures, 60 FPS live broadcast suite, and curated visual arts.',
      'image': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=1600&q=90', // Cinema Motion Picture 4K
      'badge': 'PURE CINEMA VIP',
    },
  ];

  @override
  void initState() {
    super.initState();
    _preloadMoviePosters();
  }

  void _preloadMoviePosters() {
    Future.microtask(() async {
      try {
        if (mounted) {
          for (final slide in _slides) {
            precacheImage(CachedNetworkImageProvider(slide['image']!), context);
          }
        }
        final allMovies = await Future.wait([
          TMDBService.fetchNowPlaying(),
          TMDBService.fetchTrending(),
          TMDBService.fetchTopRated(),
          TMDBService.fetchTVShows(),
        ]);

        if (!mounted) return;
        for (final list in allMovies) {
          for (final movie in list) {
            if (movie.posterUrl.isNotEmpty && mounted) {
              precacheImage(CachedNetworkImageProvider(movie.posterUrl), context);
            }
            if (movie.backdropUrl.isNotEmpty && mounted) {
              precacheImage(CachedNetworkImageProvider(movie.backdropUrl), context);
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _finishOnboarding({bool enterDirectly = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => enterDirectly ? const MainNavScreen() : const SignInScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _openSignUp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

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
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF050505)),
                  ),

                  // Cinematic Dark Vignette
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

          // Top Header (Logo + Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CinemaLogo(fontSize: 13),
                  if (!isLastPage)
                    GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
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

          // Bottom Content & Actions
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                const SizedBox(height: 20),

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
                const SizedBox(height: 24),

                // Action Buttons for Slide 3 (Matching 5th Screenshot)
                if (isLastPage) ...[
                  // SIGN IN
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openSignIn,
                      child: Text(
                        'SIGN IN',
                        style: AppFonts.sCoreDream(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CREATE ACCOUNT
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF3F3F46)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openSignUp,
                      child: Text(
                        'CREATE ACCOUNT',
                        style: AppFonts.sCoreDream(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ENTER AS GUEST
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF333333)),
                        backgroundColor: const Color(0x33141414),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _finishOnboarding(enterDirectly: true),
                      child: Text(
                        'ENTER AS GUEST',
                        style: AppFonts.sCoreDream(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Slides 1 & 2: Single CONTINUE button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Text(
                        'CONTINUE',
                        style: AppFonts.sCoreDream(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
