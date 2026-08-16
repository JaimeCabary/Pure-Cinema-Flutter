import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/database_service.dart';
import '../widgets/movie_card.dart';
import 'watch_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Movie> _savedMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    final list = await DatabaseService.getWatchlist();
    if (mounted) {
      setState(() {
        _savedMovies = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMovie(Movie movie) async {
    await DatabaseService.removeFromWatchlist(movie.id);
    _loadWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Watchlist',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : _savedMovies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_border, color: Colors.white24, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Your list is empty',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add movies to your list from the Home screen.',
                                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2 / 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _savedMovies.length,
                            itemBuilder: (ctx, index) {
                              final movie = _savedMovies[index];
                              return MovieCard(
                                movie: movie,
                                isInWatchlist: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                                  );
                                },
                                onPlay: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                                  );
                                },
                                onToggleWatchlist: () => _removeMovie(movie),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
