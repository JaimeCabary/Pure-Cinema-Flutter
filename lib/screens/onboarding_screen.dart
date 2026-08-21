import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/fonts.dart';
import '../widgets/subscription_modal.dart';
import '../widgets/cinema_logo.dart';
import '../services/tmdb_service.dart';
import 'landing_screen.dart';
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
      'image': 'https://image.tmdb.org/t/p/original/xJHokMbljvjADYdit5fK5VQsXEG.jpg', // Interstellar 4K
      'badge': '4K HDR CINEMA',
    },
    {
      'title': '10,000+ Worldwide\nLive TV Channels',
      'subtitle': 'Experience seamless 60 FPS live sports, international news, cinema networks, and global broadcasts on demand.',
      'image': 'https://image.tmdb.org/t/p/original/sAtoMqDVhNDQBc3QJL3RF6hlxGq.jpg', // Blade Runner 2049 4K
      'badge': '60 FPS BROADCAST',
    },
    {
      'title': 'Pure Cinema VIP\n& AI CineBot Access',
      'subtitle': 'Unlock unrestricted 4K streaming, Dolby Atmos, and our GenAI ADK concierge with instant Paystack activation.',
      'image': 'https://image.tmdb.org/t/p/original/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg', // Oppenheimer 4K
      'badge': 'VIP PASS ₦2,500',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Proactively preload and cache all movie poster datasets in background during onboarding
    _preloadMoviePosters();
  }

  void _preloadMoviePosters() {
    Future.microtask(() async {
      try {
        final allMovies = await Future.wait([
          TMDBService.fetchNowPlaying(),
          TMDBService.fetchTrending(),
          TMDBService.fetchTopRated(),
          TMDBService.fetchTVShows(),
          TMDBService.fetchDocuseries(),
          TMDBService.fetchBiographies(),
          TMDBService.fetchSports(),
          TMDBService.fetchRomance(),
          TMDBService.fetchFaith(),
          TMDBService.fetchAnimation(),
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
        pageBuilder: (_, __, ___) => enterDirectly ? const MainNavScreen() : const LandingScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openPaystackVIPModal() {
    SubscriptionModal.show(
      context,
      onCompleted: () {
        // When VIP is successfully activated with checkmark verified celebration
        _finishOnboarding(enterDirectly: true);
      },
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

          // Top Header (Logo + Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CinemaLogo(fontSize: 13),
                  GestureDetector(
                    onTap: () => _finishOnboarding(),
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
                    color: isLastPage ? const Color(0xFF10B981) : Colors.white,
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
                        color: isActive ? (isLastPage ? const Color(0xFF10B981) : Colors.white) : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Primary Action Button (CONTINUE / PAYSTACK VIP)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: isLastPage
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                          onPressed: _openPaystackVIPModal,
                          label: Text(
                            'ACTIVATE VIP WITH PAYSTACK',
                            style: AppFonts.sCoreDream(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 10),

                // Secondary Action Button (EXPLORE AS GUEST - Constant on all slides)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      backgroundColor: const Color(0x33141414),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _finishOnboarding(),
                    child: Text(
                      'EXPLORE AS GUEST',
                      style: AppFonts.sCoreDream(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
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
