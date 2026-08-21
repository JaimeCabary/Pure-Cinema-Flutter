import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/movie.dart';
import '../services/database_service.dart';
import '../services/tmdb_service.dart';
import '../theme/fonts.dart';

class WatchScreen extends StatefulWidget {
  final Movie movie;
  const WatchScreen({super.key, required this.movie});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isMuted = false;
  bool _hasError = false;
  final double _volume = 1.0;
  double _playbackSpeed = 1.0;
  String _selectedQuality = '4K Ultra HD (2160p)';
  Timer? _hideTimer;
  int _currentSourceIndex = 0;
  int _selectedEpisodeIndex = 0;
  List<Movie> _similarMovies = [];
  
  // Indicator badge
  String? _indicatorText;
  IconData? _indicatorIcon;
  Timer? _indicatorTimer;

  // Episodes List for Series & Multi-Part Features
  final List<Map<String, dynamic>> _episodes = [
    {
      'title': 'Episode 1: Prologue & Departure',
      'duration': '58m',
      'overview': 'The expedition prepares for launch through the uncharted dimensional rift.',
      'stream': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    },
    {
      'title': 'Episode 2: Event Horizon',
      'duration': '52m',
      'overview': 'Approaching the accretion disk of Gargantua as time dilation takes effect.',
      'stream': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    },
    {
      'title': 'Episode 3: The Ocean of Waves',
      'duration': '49m',
      'overview': 'A high-stakes descent into the aquatic expanse with relentless ticking seconds.',
      'stream': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
    {
      'title': 'Episode 4: The Ice Cloud Frontier',
      'duration': '55m',
      'overview': 'Surveying frozen clouds and unraveling an unexpected transmission.',
      'stream': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    },
    {
      'title': 'Episode 5: Tesseract Finale (4K Master)',
      'duration': '64m',
      'overview': 'Descending past the event horizon into a 5-dimensional construct to save humanity.',
      'stream': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF050505),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF050505),
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _loadSimilarMovies();
    _initAppropriateMovieStream();
  }

  Future<void> _loadSimilarMovies() async {
    final list = await TMDBService.fetchSimilar(widget.movie.id);
    if (mounted) {
      setState(() => _similarMovies = list);
    }
  }

  void _initAppropriateMovieStream() {
    final title = widget.movie.title.toLowerCase();
    
    // Choose cinematic stream matched to movie genre
    if (title.contains('avatar') || title.contains('interstellar') || title.contains('dune') || title.contains('matrix') || title.contains('blade')) {
      _currentSourceIndex = 0; // Tears of Steel (Sci-Fi Cyberpunk)
    } else if (title.contains('spider') || title.contains('inside') || title.contains('anime') || title.contains('spirited')) {
      _currentSourceIndex = 1; // Sintel / Animation
    } else {
      _currentSourceIndex = 0;
    }

    _initVideoSource(_currentSourceIndex);
  }

  List<String> get _activeStreamsList {
    return [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    ];
  }

  Future<void> _initVideoSource(int index, [String? directUrl]) async {
    final streams = _activeStreamsList;
    if (directUrl == null && index >= streams.length) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    await _controller?.dispose();

    try {
      final url = directUrl ?? streams[index];
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      
      if (!mounted) return;
      
      // Check saved progress
      final saved = await DatabaseService.getWatchProgress(widget.movie.id);
      if (saved != null && saved['position'] != null) {
        final posSec = saved['position'] as int;
        if (posSec > 0 && posSec < _controller!.value.duration.inSeconds - 10) {
          await _controller!.seekTo(Duration(seconds: posSec));
        }
      }

      setState(() => _isInitialized = true);
      _controller!.play();
      _controller!.setLooping(true);
      _controller!.setVolume(_isMuted ? 0.0 : _volume);
      _startHideTimer();

      _controller!.addListener(_videoListener);
    } catch (e) {
      debugPrint('Video source failed: $e. Trying fallback...');
      _currentSourceIndex++;
      if (_currentSourceIndex < streams.length) {
        _initVideoSource(_currentSourceIndex);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    setState(() {});

    // Save progress to LocalStorage
    if (_isInitialized && _controller!.value.isPlaying) {
      final pos = _controller!.value.position.inSeconds;
      final dur = _controller!.value.duration.inSeconds;
      if (dur > 0 && pos % 5 == 0) {
        DatabaseService.saveWatchProgress(widget.movie.id, pos, dur);
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _indicatorTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _triggerIndicator(IconData icon, String text) {
    _indicatorTimer?.cancel();
    setState(() {
      _indicatorIcon = icon;
      _indicatorText = text;
    });
    _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _indicatorIcon = null;
          _indicatorText = null;
        });
      }
    });
  }

  void _togglePlay() {
    if (!_isInitialized || _controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _showControls = true);
      _triggerIndicator(Icons.pause, 'PAUSE');
    } else {
      _controller!.play();
      _startHideTimer();
      _triggerIndicator(Icons.play_arrow, 'PLAY');
    }
  }

  void _skip(int seconds) {
    if (!_isInitialized || _controller == null) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : target;
    _controller!.seekTo(clamped);
    _triggerIndicator(
      seconds > 0 ? Icons.fast_forward : Icons.fast_rewind,
      '${seconds > 0 ? "+" : ""}${seconds}s',
    );
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : _volume);
    });
    _triggerIndicator(
      _isMuted ? Icons.volume_off : Icons.volume_up,
      _isMuted ? 'MUTED' : '${(_volume * 100).round()}%',
    );
  }

  void _cycleSpeed() {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    final next = speeds[(speeds.indexOf(_playbackSpeed) + 1) % speeds.length];
    setState(() => _playbackSpeed = next);
    _controller?.setPlaybackSpeed(next);
    _triggerIndicator(Icons.speed, '${next}x');
  }

  void _showQualityPickerModal() {
    final qualities = [
      '4K Ultra HD (2160p)',
      'Full HD (1080p)',
      'HD Ready (720p)',
      'Data Saver (480p)',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Streaming Quality',
                style: AppFonts.sCoreDream(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...qualities.map((q) {
                final isSelected = q == _selectedQuality;
                return ListTile(
                  title: Text(
                    q,
                    style: AppFonts.sCoreDream(
                      color: isSelected ? Colors.amber : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.amber) : null,
                  onTap: () {
                    setState(() => _selectedQuality = q);
                    Navigator.pop(ctx);
                    _triggerIndicator(Icons.hd_rounded, q.split(' ').first);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _openEpisodesDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0C0C0E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF27272A), width: 1),
            ),
          ),
          child: Column(
            children: [
              // Drawer Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Episodes & Parts',
                      style: AppFonts.sCoreDream(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Season 1',
                      style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1F1F23), height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _episodes.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF18181B), height: 12),
                  itemBuilder: (context, idx) {
                    final ep = _episodes[idx];
                    final isCurrent = idx == _selectedEpisodeIndex;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isCurrent ? const Color(0xFF18181B) : Colors.transparent,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white : const Color(0xFF121214),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCurrent ? Colors.white : const Color(0xFF27272A)),
                        ),
                        child: Center(
                          child: Icon(
                            isCurrent ? Icons.play_arrow_rounded : Icons.play_arrow_outlined,
                            color: isCurrent ? Colors.black : Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                      title: Text(
                        ep['title'] as String,
                        style: AppFonts.sCoreDream(
                          color: isCurrent ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        ep['overview'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11),
                      ),
                      trailing: Text(
                        ep['duration'] as String,
                        style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        setState(() => _selectedEpisodeIndex = idx);
                        Navigator.pop(ctx);
                        _initVideoSource(idx, ep['stream'] as String);
                        _triggerIndicator(Icons.play_circle_filled, 'EPISODE ${idx + 1}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isBuffering = _controller?.value.isBuffering ?? false;
    final isVideoReady = _isInitialized && _controller != null && !_hasError;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startHideTimer();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Backdrop Poster (Visible while loading)
            if (widget.movie.backdropPath != null && !isVideoReady)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.movie.backdropUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF050505)),
                ),
              ),

            if (!isVideoReady)
              Container(color: Colors.black.withValues(alpha: 0.75)),

            // 2. Main Video Surface
            if (isVideoReady)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // 3. Preloader Spinner (Clean & Centered)
            if (!isVideoReady || isBuffering)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasError ? 'Reconnecting stream...' : 'Buffering 4K Cinema Stream...',
                      style: AppFonts.sCoreDream(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Center Play / Skip Controls HUD
            if (_showControls && isVideoReady && !isBuffering)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                    onPressed: () => _skip(-10),
                  ),
                  const SizedBox(width: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: IconButton(
                      iconSize: 58,
                      icon: Icon(
                        _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlay,
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                    onPressed: () => _skip(10),
                  ),
                ],
              ),

            // 5. Always-Accessible Floating Back Button (Top Left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.0),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),

            // 6. Top & Bottom HUD Controls Overlays
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(58, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _showQualityPickerModal,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _selectedQuality.split(' ').first.toUpperCase(),
                                            style: AppFonts.sCoreDream(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '60 FPS MASTER',
                                        style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.movie.title,
                                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.high_quality_rounded, color: Colors.white, size: 20),
                              onPressed: _showQualityPickerModal,
                            ),
                            IconButton(
                              icon: const Icon(Icons.speed_rounded, color: Colors.white, size: 20),
                              onPressed: _cycleSpeed,
                            ),
                            IconButton(
                              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
                              onPressed: _toggleMute,
                            ),
                          ],
                        ),
                      ),

                      // Bottom Seeker & Episodes Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            if (isVideoReady)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  thumbColor: Colors.white,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                ),
                                child: Slider(
                                  value: _controller!.value.position.inMilliseconds.toDouble().clamp(
                                    0.0,
                                    _controller!.value.duration.inMilliseconds.toDouble() > 0
                                        ? _controller!.value.duration.inMilliseconds.toDouble()
                                        : 100.0,
                                  ),
                                  max: _controller!.value.duration.inMilliseconds.toDouble() > 0
                                      ? _controller!.value.duration.inMilliseconds.toDouble()
                                      : 100.0,
                                  onChanged: (val) {
                                    _controller!.seekTo(Duration(milliseconds: val.toInt()));
                                  },
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller?.value.position ?? Duration.zero),
                                  style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                Row(
                                  children: [
                                    // Episodes Drawer Button
                                    GestureDetector(
                                      onTap: _openEpisodesDrawer,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF18181B),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF3F3F46)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.video_library_rounded, color: Colors.white, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Episodes (${_selectedEpisodeIndex + 1}/${_episodes.length})',
                                              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _formatDuration(_controller?.value.duration ?? Duration.zero),
                                      style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. Indicator Overlay (e.g. +10s / Muted / Speed)
            if (_indicatorText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_indicatorIcon, color: Colors.white, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      _indicatorText!,
                      style: AppFonts.sCoreDream(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
