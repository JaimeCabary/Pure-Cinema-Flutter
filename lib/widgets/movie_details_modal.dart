import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/movie.dart';
import '../models/cast_member.dart';
import '../services/tmdb_service.dart';
import '../screens/watch_screen.dart';
import '../theme/fonts.dart';
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

  // Trailer Controller (Unseeked, Expandable)
  VideoPlayerController? _trailerController;
  bool _isTrailerReady = false;
  bool _isMuted = true;
  bool _isPlaying = true;
  bool _isExpanded = false;

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
      _trailerController!.setVolume(0.0); // Start muted for instant autoplay
      await _trailerController!.play();
      if (mounted) {
        setState(() {
          _isTrailerReady = true;
          _isPlaying = true;
        });
      }
    } catch (_) {
      // Fallback cleanly to backdrop image if video stream fails
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

  void _togglePlayPause() {
    if (_trailerController != null && _isTrailerReady) {
      if (_trailerController!.value.isPlaying) {
        _trailerController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _trailerController!.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  void _toggleMute() {
    if (_trailerController != null && _isTrailerReady) {
      setState(() {
        _isMuted = !_isMuted;
        _trailerController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _isMuted) {
        // Automatically unmute when expanded for full immersion
        _isMuted = false;
        _trailerController?.setVolume(1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    // Full Expanded Trailer View
    if (_isExpanded) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.95,
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar for Expanded Trailer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                      onPressed: _toggleExpand,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFFICIAL TRAILER',
                        style: AppFonts.sCoreDream(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movie.title,
                        style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: _toggleMute,
                    ),
                  ],
                ),
              ),

              // Expanded Trailer View (Unseeked)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _trailerController != null && _trailerController!.value.isInitialized
                        ? _trailerController!.value.aspectRatio
                        : 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isTrailerReady && _trailerController != null)
                          VideoPlayer(_trailerController!)
                        else
                          CachedNetworkImage(
                            imageUrl: movie.backdropUrl,
                            fit: BoxFit.cover,
                          ),

                        // Play/Pause Overlay Toggle
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Button in Expanded Trailer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WatchScreen(movie: movie)),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: Text(
                          'WATCH FULL MOVIE',
                          style: AppFonts.sCoreDream(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _toggleExpand,
                      icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                      label: Text('COLLAPSE', style: AppFonts.sCoreDream(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default Halfscreen Details Modal
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
                  // Hero Trailer Auto-play & Backdrop Player (Unseeked, Expandable)
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

                              // Autoplay Video Trailer Layer (Unseeked continuous teaser)
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

                      // Trailer Badge & Audio Toggle (Top Left)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TRAILER',
                                style: AppFonts.sCoreDream(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_isTrailerReady) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _toggleMute,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isMuted ? 'UNMUTE' : 'MUTE',
                                        style: AppFonts.sCoreDream(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Play/Pause Center Tap
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _isPlaying ? 0.0 : 0.9,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Expand Trailer Button (Bottom Right)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _toggleExpand,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'EXPAND',
                                  style: AppFonts.sCoreDream(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
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
                    style: AppFonts.sCoreDream(
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
                        style: AppFonts.sCoreDream(
                          color: const Color(0xFF4ADE80),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        movie.releaseYear,
                        style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 12),
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
                          style: AppFonts.sCoreDream(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                          style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
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
                            style: AppFonts.sCoreDream(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
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
                                style: AppFonts.sCoreDream(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                    style: AppFonts.sCoreDream(
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
                    style: AppFonts.sCoreDream(
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
                        child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 2),
                      ),
                    )
                  else if (_cast.isEmpty)
                    Text(
                      'Cast details unavailable for this title.',
                      style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 12),
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
                                  style: AppFonts.sCoreDream(
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
                                  style: AppFonts.sCoreDream(
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
                      style: AppFonts.sCoreDream(
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
