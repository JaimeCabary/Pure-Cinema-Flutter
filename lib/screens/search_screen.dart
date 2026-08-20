import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';
import '../widgets/movie_card.dart';
import '../theme/fonts.dart';
import 'watch_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _results = [];
  bool _isLoading = false;
  final Set<int> _watchlist = {};

  @override
  void initState() {
    super.initState();
    final initQ = widget.initialQuery ?? '';
    if (initQ.isNotEmpty) {
      _searchController.text = initQ;
    }
    _performSearch(initQ);
    _loadWatchlist();
    DatabaseService.watchlistNotifier.addListener(_loadWatchlist);
  }

  @override
  void dispose() {
    DatabaseService.watchlistNotifier.removeListener(_loadWatchlist);
    _searchController.dispose();
    super.dispose();
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

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final list = await TMDBService.searchMovies(query);
    if (mounted) {
      setState(() {
        _results = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar / Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141418),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        onChanged: (val) => _performSearch(val),
                        decoration: InputDecoration(
                          hintText: 'Search movies, TV shows, genres...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category tag indicator
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      'CATEGORY: ',
                      style: AppFonts.sCoreDream(color: const Color(0xFFA1A1AA), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _searchController.text.toUpperCase(),
                        style: AppFonts.sCoreDream(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),

            // Results Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.movie_filter_outlined, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No titles found',
                                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final movie = _results[index];
                            final isInList = _watchlist.contains(movie.id);
                            return MovieCard(
                              movie: movie,
                              isInWatchlist: isInList,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                                );
                              },
                              onPlay: () {
                                Navigator.of(context).push(
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
      ),
    );
  }
}
