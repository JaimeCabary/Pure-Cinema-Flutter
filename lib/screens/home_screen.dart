import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/cinema_logo.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_details_modal.dart';
import '../theme/fonts.dart';
import 'watch_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _bestPicks = [];
  List<Movie> _trending = [];
  List<Movie> _tvShows = [];
  List<Movie> _docuseries = [];
  List<Movie> _biographies = [];
  List<Movie> _sports = [];
  List<Movie> _romance = [];
  List<Movie> _faith = [];
  List<Movie> _topRated = [];
  List<Movie> _animation = [];
  List<Movie> _publicDomain = [];
  List<Movie> _heroMovies = [];
  
  int _currentHeroIndex = 0;
  late final PageController _heroPageController;
  Timer? _heroTimer;

  bool _isLoading = true;
  final Set<int> _watchlist = {};
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _loadData();
    _loadWatchlist();
    _loadUser();
    DatabaseService.watchlistNotifier.addListener(_loadWatchlist);
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  void dispose() {
    DatabaseService.watchlistNotifier.removeListener(_loadWatchlist);
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    if (_heroMovies.length <= 1) return;
    _heroTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || !_heroPageController.hasClients) return;
      final nextIndex = (_currentHeroIndex + 1) % _heroMovies.length;
      _heroPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _loadWatchlist() async {
    final list = await DatabaseService.getWatchlist();
    if (mounted) {
      setState(() {
        _watchlist.clear();
        _watchlist.addAll(list.map((m) => m.id));
      });
    }
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    if (_watchlist.contains(movie.id)) {
      await DatabaseService.removeFromWatchlist(movie.id);
      setState(() => _watchlist.remove(movie.id));
    } else {
      await DatabaseService.addToWatchlist(movie);
      setState(() => _watchlist.add(movie.id));
    }
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      TMDBService.fetchNowPlaying(),
      TMDBService.fetchTrending(),
      TMDBService.fetchTVShows(),
      TMDBService.fetchDocuseries(),
      TMDBService.fetchBiographies(),
      TMDBService.fetchSports(),
      TMDBService.fetchRomance(),
      TMDBService.fetchFaith(),
      TMDBService.fetchTopRated(),
      TMDBService.fetchAnimation(),
      TMDBService.fetchPublicDomainMovies(),
    ]);

    if (mounted) {
      setState(() {
        _bestPicks = results[0];
        _trending = results[1];
        _tvShows = results[2];
        _docuseries = results[3];
        _biographies = results[4];
        _sports = results[5];
        _romance = results[6];
        _faith = results[7];
        _topRated = results[8];
        _animation = results[9];
        _publicDomain = results[10];

        // Curate hero banner from top distinct items
        _heroMovies = [
          ..._bestPicks.take(3),
          ..._trending.take(2),
        ];

        _isLoading = false;
      });
      _startHeroTimer();

      // Immediately precache poster images for all loaded rows
      for (final list in results) {
        for (final movie in list) {
          if (movie.posterUrl.isNotEmpty && mounted) {
            precacheImage(CachedNetworkImageProvider(movie.posterUrl), context);
          }
        }
      }
    }
  }

  void _openCategorySearch(String categoryTitle, String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF141414),
              onRefresh: () async {
                await _loadData();
                await _loadWatchlist();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar with Pure Cinema Breathing Logo & Profile Avatar
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    backgroundColor: const Color(0xFF050505).withValues(alpha: 0.95),
                    elevation: 0,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CinemaLogo(fontSize: 15),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ).then((_) => _loadUser());
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF18181B),
                              border: Border.all(color: const Color(0xFF3F3F46), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _currentUser != null && _currentUser!.name.isNotEmpty
                                  ? Text(
                                      _currentUser!.name[0].toUpperCase(),
                                      style: AppFonts.sCoreDream(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : const Icon(Icons.person_rounded, color: Colors.white70, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero Banner Carousel
                  if (_heroMovies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHeroCarousel(),
                    ),

                  // 1. Best Picks (Curated Masterpieces)
                  _buildSectionHeader('Best Picks', query: 'Best Picks'),
                  _buildMovieRow(_bestPicks, 'Best Picks'),

                  // 2. Trending Now
                  _buildSectionHeader('Trending Now', query: 'Trending'),
                  _buildMovieRow(_trending, 'Trending Now'),

                  // 3. Popular TV Shows & Series
                  _buildSectionHeader('TV Shows & Series', query: 'TV Shows'),
                  _buildMovieRow(_tvShows, 'TV Shows & Series'),

                  // 4. Top Rated Docuseries
                  _buildSectionHeader('Docuseries & Nature', query: 'Documentary'),
                  _buildMovieRow(_docuseries, 'Docuseries & Nature'),

                  // 5. Biographies & True Stories
                  _buildSectionHeader('Biographies & True Stories', query: 'Biography'),
                  _buildMovieRow(_biographies, 'Biographies & True Stories'),

                  // 6. Sports & Legends
                  _buildSectionHeader('Live Sports & Legends', query: 'Sports'),
                  _buildMovieRow(_sports, 'Live Sports & Legends'),

                  // 7. Romance & Heartfelt Cinema
                  _buildSectionHeader('Romance & Heartfelt Cinema', query: 'Romance'),
                  _buildMovieRow(_romance, 'Romance & Heartfelt Cinema'),

                  // 8. Faith & Spiritual Journeys
                  _buildSectionHeader('Faith & Spiritual Journeys', query: 'Faith'),
                  _buildMovieRow(_faith, 'Faith & Spiritual Journeys'),

                  // 9. Top Rated Masterpieces
                  _buildSectionHeader('Top Rated Masterpieces', query: 'Top Rated'),
                  _buildMovieRow(_topRated, 'Top Rated Masterpieces'),

                  // 10. Animation & Anime Masterworks
                  _buildSectionHeader('Animation & Anime', query: 'Animation'),
                  _buildMovieRow(_animation, 'Animation & Anime'),

                  // 11. Available Movies (100% Streamable Vault)
                  if (_publicDomain.isNotEmpty) ...[
                    _buildSectionHeader('Available Movies (100% Streamable Vault)', query: 'Public Domain'),
                    _buildMovieRow(_publicDomain, 'Available Movies (100% Streamable Vault)'),
                  ],

                  // Bottom Spacing for Floating Capsule Dock Navbar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 440,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroPageController,
            onPageChanged: (idx) => setState(() => _currentHeroIndex = idx),
            itemCount: _heroMovies.length,
            itemBuilder: (context, idx) {
              final movie = _heroMovies[idx];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // High-Res Backdrop Image
                  CachedNetworkImage(
                    imageUrl: movie.backdropUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(color: const Color(0xFF0F0F0F)),
                    errorWidget: (_, __, ___) => Container(color: Colors.black),
                  ),

                  // Smooth Obsidian Cinematic Gradients
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xCC050505),
                          Color(0xFF050505),
                        ],
                        stops: [0.0, 0.35, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Movie Info Overlay
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: AppFonts.sCoreDream(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${(movie.voteAverage * 10).toInt()}% Match',
                              style: AppFonts.sCoreDream(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              movie.releaseYear,
                              style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Text(
                                '4K ULTRA HD',
                                style: AppFonts.sCoreDream(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.overview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.sCoreDream(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons: Play (Cinema Watch), Add to List, Details Modal
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                              label: Text(
                                'PLAY',
                                style: AppFonts.sCoreDream(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              icon: Icon(
                                _watchlist.contains(movie.id) ? Icons.check_rounded : Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                _watchlist.contains(movie.id) ? 'ADDED' : 'ADD',
                                style: AppFonts.sCoreDream(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _toggleWatchlist(movie),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 22),
                              onPressed: () {
                                MovieDetailsModal.show(
                                  context,
                                  movie,
                                  _watchlist.contains(movie.id),
                                  () => _toggleWatchlist(movie),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Pagination Dots Indicator
          Positioned(
            top: 16,
            right: 20,
            child: Row(
              children: List.generate(_heroMovies.length, (idx) {
                final isSelected = _currentHeroIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isSelected ? 16 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required String query}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppFonts.sCoreDream(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => _openCategorySearch(title, query),
              child: Row(
                children: [
                  Text(
                    'SEE MORE',
                    style: AppFonts.sCoreDream(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFA1A1AA), size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieRow(List<Movie> movies, String categoryTitle) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: movies.length + 1, // Movies + End "See More" Card
          itemBuilder: (context, index) {
            if (index == movies.length) {
              return _buildSeeMoreCard(categoryTitle);
            }
            final movie = movies[index];
            final isInList = _watchlist.contains(movie.id);
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: MovieCard(
                movie: movie,
                isInWatchlist: isInList,
                onTap: () {
                  MovieDetailsModal.show(
                    context,
                    movie,
                    isInList,
                    () => _toggleWatchlist(movie),
                  );
                },
                onPlay: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                  );
                },
                onToggleWatchlist: () => _toggleWatchlist(movie),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeeMoreCard(String categoryTitle) {
    return GestureDetector(
      onTap: () => _openCategorySearch(categoryTitle, categoryTitle),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C20),
                border: Border.all(color: const Color(0xFF3F3F46)),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Explore All',
              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              categoryTitle.split(' ').first,
              style: AppFonts.sCoreDream(color: const Color(0xFFA1A1AA), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}
