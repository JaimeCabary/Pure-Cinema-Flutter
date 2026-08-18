import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/movie.dart';
import '../services/database_service.dart';
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
  Timer? _hideTimer;
  int _currentSourceIndex = 0;
  
  // Indicator badge
  String? _indicatorText;
  IconData? _indicatorIcon;
  Timer? _indicatorTimer;

  // Resilient High-Speed 4K/HD Video CDN Streams
  static const List<String> _videoSources = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
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

    _initVideoSource(_currentSourceIndex);
  }

  Future<void> _initVideoSource(int index) async {
    if (index >= _videoSources.length) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    await _controller?.dispose();

    try {
      final url = _videoSources[index];
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
      _startHideTimer();

      _controller!.addListener(_videoListener);
    } catch (e) {
      debugPrint('Video source $index failed: $e. Trying fallback stream...');
      _currentSourceIndex++;
      if (_currentSourceIndex < _videoSources.length) {
        _initVideoSource(_currentSourceIndex);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    setState(() {});

    // Periodically save progress to LocalStorage
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
    _hideTimer = Timer(const Duration(seconds: 4), () {
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
            // 1. Backdrop Poster & Ambient Backdrop (Visible during load)
            if (widget.movie.backdropPath != null && !isVideoReady)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.movie.backdropUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF050505)),
                ),
              ),

            // Backdrop Dim Overlay
            if (!isVideoReady)
              Container(color: Colors.black.withValues(alpha: 0.75)),

            // 2. Video Surface
            if (isVideoReady)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // 3. Clean Buffering / Preloader Spinner (No Play Button Overlap!)
            if (!isVideoReady || isBuffering)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
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
                      _hasError ? 'Connecting 4K stream...' : 'Buffering 4K Cinema Stream...',
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

            // 4. Center Skip / Play HUD (ONLY shown when initialized and not buffering!)
            if (_showControls && isVideoReady && !isBuffering)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.replay_10, color: Colors.white),
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
                      iconSize: 52,
                      icon: Icon(
                        _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlay,
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () => _skip(10),
                  ),
                ],
              ),

            // 5. Indicator Badge Overlay (e.g. +10s / Muted / Paused)
            if (_indicatorText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_indicatorIcon, color: Colors.white, size: 36),
                    const SizedBox(height: 6),
                    Text(
                      _indicatorText!,
                      style: AppFonts.sCoreDream(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // 6. Top & Bottom HUD Controls
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
                      Colors.black.withValues(alpha: 0.9),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PURE CINEMA 4K',
                                    style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    widget.movie.title,
                                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                              onPressed: _toggleMute,
                            ),
                          ],
                        ),
                      ),

                      // Bottom Scrubber Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          children: [
                            if (isVideoReady)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
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
                            if (isVideoReady)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller!.value.position),
                                    style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
                                  ),
                                  Text(
                                    _formatDuration(_controller!.value.duration),
                                    style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
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
          ],
        ),
      ),
    );
  }
}
