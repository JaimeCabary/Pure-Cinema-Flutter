import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/movie.dart';
import '../models/cast_member.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';
import '../screens/watch_screen.dart';
import '../theme/fonts.dart';
import 'movie_card.dart';
import 'youtube_trailer_view.dart';

class MovieDetailsModal extends StatefulWidget {
  final Movie movie;
  final bool isInWatchlist;
  final VoidCallback? onToggleWatchlist;

  const MovieDetailsModal({
    super.key,
    required this.movie,
    this.isInWatchlist = false,
    this.onToggleWatchlist,
  });

  static void show(
    BuildContext context,
    Movie movie, [
    bool isInWatchlist = false,
    VoidCallback? onToggleWatchlist,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovieDetailsModal(
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
  bool _isInList = false;
  String? _youtubeTrailerKey;

  // Trailer Controller (Unseeked, Expandable)
  VideoPlayerController? _trailerController;
  bool _isTrailerReady = false;
  bool _isMuted = true;
  bool _isPlaying = true;
  bool _isExpanded = false;

  // High-performance lightweight fast-start cinematic preview streams (< 3MB)
  static final List<String> _sampleTrailers = [
    'https://assets.mixkit.co/videos/preview/mixkit-futuristic-city-and-space-station-with-stars-32986-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-set-of-plateaus-seen-from-the-sky-in-a-sunset-26070-large.mp4',
    'https://vjs.zencdn.net/v/oceans.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-sun-setting-over-the-ocean-1181-large.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _isInList = widget.isInWatchlist;
    DatabaseService.isInWatchlist(widget.movie.id).then((inList) {
      if (mounted) setState(() => _isInList = inList);
    });
    _loadCreditsAndSimilar();
    _initTrailerPlayer();
  }

  Future<void> _initTrailerPlayer() async {
    final trailerIndex = widget.movie.id.abs() % _sampleTrailers.length;
    final streamUrl = _sampleTrailers[trailerIndex];

    try {
      _trailerController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      _trailerController!.addListener(() {
        if (mounted) setState(() {});
      });

      await _trailerController!.initialize();
      await _trailerController!.setLooping(true);
      await _trailerController!.setVolume(0.0); // Muted for instant browser autoplay compliance

      if (mounted) {
        setState(() {
          _isTrailerReady = true;
          _isPlaying = true;
        });
      }

      _trailerController!.play().catchError((_) {});
    } catch (e) {
      debugPrint('Trailer autoplay error: $e');
    }
  }

  Future<void> _loadCreditsAndSimilar() async {
    final results = await Future.wait([
      TMDBService.fetchCredits(widget.movie.id),
      TMDBService.fetchSimilar(widget.movie.id),
      TMDBService.fetchTrailerKey(widget.movie.id),
    ]);

    if (mounted) {
      setState(() {
        _cast = results[0] as List<CastMember>;
        _similar = results[1] as List<Movie>;
        _youtubeTrailerKey = results[2] as String?;
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFFICIAL TRAILER',
                        style: AppFonts.sCoreDream(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
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
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
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
          // Top Header Bar with Center Drag Handle & Guaranteed Clickable Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 28), // Balance Spacer
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F24),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF383842)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                          child: _youtubeTrailerKey != null && _youtubeTrailerKey!.isNotEmpty
                              ? YouTubeTrailerView(
                                  trailerKey: _youtubeTrailerKey!,
                                  backdropUrl: movie.backdropUrl,
                                  title: movie.title,
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: movie.backdropUrl,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorWidget: (_, __, ___) => Container(color: Colors.black),
                                    ),
                                    if (_trailerController != null && _trailerController!.value.isInitialized)
                                      Positioned.fill(
                                        child: VideoPlayer(_trailerController!),
                                      )
                                    else
                                      const Positioned.fill(
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),

                      // Subtle bottom gradient vignette
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 40,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TRAILER',
                                style: AppFonts.sCoreDream(
                                  color: Colors.black,
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
                        onTap: () async {
                          final newState = await DatabaseService.toggleWatchlist(movie);
                          widget.onToggleWatchlist?.call();
                          if (mounted) setState(() => _isInList = newState);
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
