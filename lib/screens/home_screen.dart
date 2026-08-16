import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';
import '../widgets/cinema_logo.dart';
import '../widgets/movie_card.dart';
import 'watch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _nowPlaying = [];
  List<Movie> _topRated = [];
  List<Movie> _animation = [];
  Movie? _heroMovie;
  bool _isLoading = true;
  final Set<int> _watchlist = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadWatchlist();
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
      TMDBService.fetchTrending(),
      TMDBService.fetchPopular(),
      TMDBService.fetchNowPlaying(),
      TMDBService.fetchTopRated(),
      TMDBService.fetchAnimation(),
    ]);

    if (!mounted) return;
    setState(() {
      _trending = results[0];
      _popular = results[1];
      _nowPlaying = results[2];
      _topRated = results[3];
      _animation = results[4];
      if (_trending.isNotEmpty) {
        _heroMovie = _trending.first;
      }
      _isLoading = false;
    });
  }

  void _showMovieDetails(Movie movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C0C0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF222222), width: 1),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final isInList = _watchlist.contains(movie.id);
        return Container(
          height: MediaQuery.of(context).size.height * 0.76,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image & Close
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(color: Colors.black),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                movie.title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),

              // Badges
              Row(
                children: [
                  Text(
                    '${movie.matchScore}% Match',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4ADE80),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    movie.releaseYear,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '4K ULTRA HD',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                      label: Text(
                        'PLAY',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      _toggleWatchlist(movie);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6),
                        color: isInList ? Colors.white12 : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(isInList ? Icons.check : Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isInList ? 'MY LIST' : 'ADD TO LIST',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Overview
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    movie.overview,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: CustomScrollView(
        slivers: [
          // App Bar with Web Cinema Logo
          SliverAppBar(
            backgroundColor: const Color(0xFF050505).withValues(alpha: 0.95),
            floating: true,
            pinned: false,
            elevation: 0,
            title: Row(
              children: [
                const CinemaLogoWidget(size: 22, animate: true),
                const SizedBox(width: 8),
                Text(
                  'PURE CINEMA',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),

          // Hero Section
          if (_heroMovie != null)
            SliverToBoxAdapter(
              child: _buildHeroSection(_heroMovie!),
            ),

          // Content Carousels with Bottom Clearance
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentRow('Trending Now', _trending),
                  _buildContentRow('Recommended For You', _popular.reversed.toList()),
                  _buildContentRow('New Releases', _nowPlaying),
                  _buildContentRow('Kids & Family', _animation),
                  _buildContentRow('Top Rated Classics', _topRated),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Movie movie) {
    final isInList = _watchlist.contains(movie.id);
    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        children: [
          // Backdrop Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: movie.backdropUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(color: Colors.black),
            ),
          ),

          // Deep Gradient Masks
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Color(0xFF050505),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Hero Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movie.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),

                // Match Score & Badges
                Row(
                  children: [
                    Text(
                      '${movie.matchScore}% Match',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4ADE80),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      movie.releaseYear,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black45,
                      ),
                      child: Text(
                        '4K ULTRA HD',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Short Overview
                Text(
                  movie.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.black, size: 18),
                      label: Text(
                        'PLAY',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _toggleWatchlist(movie),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(6),
                          color: isInList ? Colors.white12 : const Color(0xFF141414),
                        ),
                        child: Row(
                          children: [
                            Icon(isInList ? Icons.check : Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              isInList ? 'MY LIST' : 'ADD TO LIST',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentRow(String title, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                final movie = movies[index];
                final isInList = _watchlist.contains(movie.id);
                return MovieCard(
                  movie: movie,
                  isInWatchlist: isInList,
                  onTap: () => _showMovieDetails(movie),
                  onPlay: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                    );
                  },
                  onToggleWatchlist: () => _toggleWatchlist(movie),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
