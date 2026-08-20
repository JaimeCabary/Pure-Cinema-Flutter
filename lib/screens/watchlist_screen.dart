import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/database_service.dart';
import '../theme/fonts.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_details_modal.dart';
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
    DatabaseService.watchlistNotifier.addListener(_loadWatchlist);
  }

  @override
  void dispose() {
    DatabaseService.watchlistNotifier.removeListener(_loadWatchlist);
    super.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY WATCHLIST',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_savedMovies.length} Title${_savedMovies.length == 1 ? '' : 's'} Saved',
                        style: AppFonts.sCoreDream(
                          color: const Color(0xFFA1A1AA),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (_savedMovies.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                      onPressed: _loadWatchlist,
                      tooltip: 'Refresh Watchlist',
                    ),
                ],
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
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF27272A)),
                                  ),
                                  child: const Icon(Icons.bookmark_border_rounded, color: Colors.white38, size: 48),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your Watchlist is Empty',
                                  style: AppFonts.sCoreDream(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "+ MY LIST" on any movie or trailer to save it here.',
                                  textAlign: TextAlign.center,
                                  style: AppFonts.sCoreDream(color: const Color(0xFF71717A), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.black,
                            backgroundColor: Colors.white,
                            onRefresh: _loadWatchlist,
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 90),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2 / 3.2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _savedMovies.length,
                              itemBuilder: (ctx, index) {
                                final movie = _savedMovies[index];
                                return MovieCard(
                                  movie: movie,
                                  isInWatchlist: true,
                                  onTap: () {
                                    MovieDetailsModal.show(
                                      context,
                                      movie,
                                      isInWatchlist: true,
                                      onToggleWatchlist: _loadWatchlist,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
