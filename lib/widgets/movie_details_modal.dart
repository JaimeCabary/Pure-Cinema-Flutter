import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/movie.dart';
import '../models/cast_member.dart';
import '../services/tmdb_service.dart';
import '../screens/watch_screen.dart';
import 'movie_card.dart';

class MovieDetailsModal extends StatefulWidget {
  final Movie movie;
  final bool isInWatchlist;
  final VoidCallback onToggleWatchlist;

  const MovieDetailsModal({
    super.key,
    required this.movie,
    required this.isInWatchlist,
    required this.onToggleWatchlist,
  });

  static void show(BuildContext context, Movie movie, bool isInWatchlist, VoidCallback onToggleWatchlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C0C0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF222222), width: 1),
      ),
      isScrollControlled: true,
      builder: (ctx) => MovieDetailsModal(
        movie: movie,
        isInWatchlist: isInWatchlist,
        onToggleWatchlist: onToggleWatchlist,
      ),
    );
  }

  @override
  State<MovieDetailsModal> createState() => _MovieDetailsModalState();
}

class _MovieDetailsModalState extends State<MovieDetailsModal> {
  List<CastMember> _cast = [];
  List<Movie> _similar = [];
  bool _isLoadingDetails = true;
  late bool _isInList;

  // Trailer Auto-play Controller
  VideoPlayerController? _trailerController;
  bool _isTrailerReady = false;
  bool _isMuted = true;

  // High-def sample cinematic preview streams
  static final List<String> _sampleTrailers = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _isInList = widget.isInWatchlist;
    _loadCreditsAndSimilar();
    _initTrailerPlayer();
  }

  Future<void> _initTrailerPlayer() async {
    // Select sample trailer stream deterministically by movie ID
    final trailerIndex = widget.movie.id.abs() % _sampleTrailers.length;
    final streamUrl = _sampleTrailers[trailerIndex];

    try {
      _trailerController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await _trailerController!.initialize();
      _trailerController!.setLooping(true);
      _trailerController!.setVolume(0.0); // Start muted for compliant autoplay
      await _trailerController!.play();
      if (mounted) {
        setState(() {
          _isTrailerReady = true;
        });
      }
    } catch (_) {
      // Fallback cleanly to backdrop image if video fails to stream
    }
  }

  Future<void> _loadCreditsAndSimilar() async {
    final results = await Future.wait([
      TMDBService.fetchCredits(widget.movie.id),
      TMDBService.fetchSimilar(widget.movie.id),
    ]);

    if (mounted) {
      setState(() {
        _cast = results[0] as List<CastMember>;
        _similar = results[1] as List<Movie>;
        _isLoadingDetails = false;
      });
    }
  }

  @override
  void dispose() {
    _trailerController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_trailerController != null && _isTrailerReady) {
      setState(() {
        _isMuted = !_isMuted;
        _trailerController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Trailer Auto-play & Backdrop Player
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            children: [
                              // Backdrop Image Placeholder
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: movie.backdropUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorWidget: (_, __, ___) => Container(color: Colors.black),
                                ),
                              ),

                              // Autoplay Video Layer
                              if (_isTrailerReady && _trailerController != null)
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    opacity: _isTrailerReady ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 500),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _trailerController!.value.size.width,
                                        height: _trailerController!.value.size.height,
                                        child: VideoPlayer(_trailerController!),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                        ),
                      ),

                      // Close Button (Top Right)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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

                      // Mute / Unmute Audio Toggle (Top Left)
                      if (_isTrailerReady)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isMuted ? Icons.volume_off : Icons.volume_up,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isMuted ? 'UNMUTE' : 'MUTE',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Fullscreen Watch Preview Floating Button (Bottom Left)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow, color: Colors.black, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'PLAY MOVIE',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    movie.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata Badges Row
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
                          color: Colors.black38,
                        ),
                        child: Text(
                          '4K ULTRA HD',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black38,
                        ),
                        child: Text(
                          '5.1 AUDIO',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                            );
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                          label: Text(
                            'WATCH NOW',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          widget.onToggleWatchlist();
                          setState(() => _isInList = !_isInList);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(6),
                            color: _isInList ? Colors.white12 : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(_isInList ? Icons.check : Icons.add, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _isInList ? 'IN LIST' : 'MY LIST',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Overview Synopsis
                  Text(
                    movie.overview,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── TOP BILLED CAST & ACTORS ──
                  Text(
                    'Cast & Crew',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingDetails)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  else if (_cast.isEmpty)
                    Text(
                      'Cast details unavailable for this title.',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                    )
                  else
                    SizedBox(
                      height: 135,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, index) {
                          final actor = _cast[index];
                          return SizedBox(
                            width: 75,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  backgroundImage: NetworkImage(actor.profileUrl),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  actor.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  actor.character,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── SIMILAR & RECOMMENDED TITLES ──
                  if (_similar.isNotEmpty) ...[
                    Text(
                      'More Like This',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 185,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, index) {
                          final simMovie = _similar[index];
                          return MovieCard(
                            movie: simMovie,
                            width: 110,
                            height: 165,
                            onTap: () {
                              Navigator.pop(context);
                              MovieDetailsModal.show(context, simMovie, false, () {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
