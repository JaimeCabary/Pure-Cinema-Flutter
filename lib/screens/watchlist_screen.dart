import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/database_service.dart';
import '../theme/fonts.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_details_modal.dart';
import 'watch_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: ValueListenableBuilder<List<Movie>>(
            valueListenable: DatabaseService.watchlistStream,
            builder: (context, savedMovies, _) {
              return Column(
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
                            '${savedMovies.length} Title${savedMovies.length == 1 ? '' : 's'} Saved',
                            style: AppFonts.sCoreDream(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: savedMovies.isEmpty
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
                                  'Tap "+ MY LIST" on any movie or trailer to save it here in real time.',
                                  textAlign: TextAlign.center,
                                  style: AppFonts.sCoreDream(color: const Color(0xFF71717A), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2 / 3.2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: savedMovies.length,
                            itemBuilder: (ctx, index) {
                              final movie = savedMovies[index];
                              return MovieCard(
                                key: ValueKey(movie.id),
                                movie: movie,
                                isInWatchlist: true,
                                onTap: () {
                                  MovieDetailsModal.show(
                                    context,
                                    movie,
                                    isInWatchlist: true,
                                  );
                                },
                                onPlay: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                                  );
                                },
                                onToggleWatchlist: () => DatabaseService.removeFromWatchlist(movie.id),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
