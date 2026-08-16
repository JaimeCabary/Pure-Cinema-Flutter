import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/live_channel.dart';
import '../services/iptv_service.dart';

class LiveTVScreen extends StatefulWidget {
  final LiveChannel? initialChannel;
  final bool isActive;
  const LiveTVScreen({super.key, this.initialChannel, this.isActive = true});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  late LiveChannel _activeChannel;
  String _selectedCategory = 'All Channels';
  String _searchQuery = '';
  VideoPlayerController? _videoController;
  bool _isInitializing = true;
  bool _isPlaying = true;
  bool _isMuted = false;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isChannelListCollapsed = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  
  // Indicator badge
  String? _indicatorText;
  IconData? _indicatorIcon;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _activeChannel = widget.initialChannel ?? IPTVService.channels.first;
    if (widget.isActive) {
      _initPlayer(_activeChannel.streamUrl);
    }
  }

  @override
  void didUpdateWidget(covariant LiveTVScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) {
        _videoController?.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_videoController == null) {
          _initPlayer(_activeChannel.streamUrl);
        } else {
          _videoController?.play();
          setState(() => _isPlaying = true);
        }
      }
    }
  }

  Future<void> _initPlayer(String url) async {
    setState(() => _isInitializing = true);
    await _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(_isMuted ? 0.0 : _volume);
      _videoController!.play();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
        });
        _startHideTimer();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _videoController?.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && (_isFullscreen || _isChannelListCollapsed)) {
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
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
      _triggerIndicator(Icons.pause, 'PAUSE');
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
      _startHideTimer();
      _triggerIndicator(Icons.play_arrow, 'PLAY');
    }
  }

  void _skip(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    final current = _videoController!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : target;
    _videoController!.seekTo(clamped);
    _triggerIndicator(
      seconds > 0 ? Icons.fast_forward : Icons.fast_rewind,
      '${seconds > 0 ? "+" : ""}${seconds}s',
    );
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : _volume);
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
    _videoController?.setPlaybackSpeed(next);
    _triggerIndicator(Icons.speed, '${next}x');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showControls = true;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final filteredChannels = IPTVService.searchChannels(_searchQuery, _selectedCategory);

    // Fullscreen View
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) _startHideTimer();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fullscreen Player
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController != null && _videoController!.value.isInitialized
                        ? _videoController!.value.aspectRatio
                        : 16 / 9,
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? VideoPlayer(_videoController!)
                        : const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  ),
                ),
              ),

              // Indicator Badge
              if (_indicatorText != null) _buildIndicatorBadge(),

              // Fullscreen HUD Controls Overlay
              if (_showControls)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFullscreenTopBar(),
                          _buildCenterSkipControls(),
                          _buildFullscreenBottomBar(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Normal Layout (Desktop / Mobile with Collapsible Channel Guide)
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 768;

            if (isDesktop) {
              // 2-Column Desktop / Web View
              return Row(
                children: [
                  // Video Player
                  Expanded(
                    flex: _isChannelListCollapsed ? 100 : 65,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildVideoPlayer(),
                        ),
                      ),
                    ),
                  ),

                  // Collapsible Channel Guide Sidebar
                  if (!_isChannelListCollapsed)
                    Expanded(
                      flex: 35,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF080808),
                          border: Border(left: BorderSide(color: Color(0xFF181818))),
                        ),
                        child: Column(
                          children: [
                            _buildGuideHeader(filteredChannels.length),
                            _buildCategoryTabs(),
                            _buildSearchField(),
                            Expanded(child: _buildChannelList(filteredChannels)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }

            // Mobile Layout
            return Stack(
              children: [
                Column(
                  children: [
                    // Video Player Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: _isChannelListCollapsed
                          ? MediaQuery.of(context).size.height * 0.82
                          : MediaQuery.of(context).size.height * 0.30,
                      width: double.infinity,
                      color: Colors.black,
                      child: _buildVideoPlayer(),
                    ),

                    // Collapsible Channel Guide Body
                    if (!_isChannelListCollapsed) ...[
                      _buildGuideHeader(filteredChannels.length),
                      _buildCategoryTabs(),
                      _buildSearchField(),
                      Expanded(child: _buildChannelList(filteredChannels)),
                    ],
                  ],
                ),

                // Floating Expand Guide Button when collapsed on mobile
                if (_isChannelListCollapsed)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 8,
                      onPressed: () => setState(() => _isChannelListCollapsed = false),
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: Text(
                        'SHOW CHANNELS',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _startHideTimer();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio > 0 ? _videoController!.value.aspectRatio : 16 / 9,
                child: VideoPlayer(_videoController!),
              ),
            )
          else if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            Center(
              child: Text(
                'Live Signal Connecting...',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              ),
            ),

          // Top Channel Banner & Quick Actions
          Positioned(
            top: 8,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeChannel.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '60 FPS · 1080p',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(width: 8),
                // Fullscreen Button
                GestureDetector(
                  onTap: _toggleFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Center Indicator Badge
          if (_indicatorText != null) _buildIndicatorBadge(),

          // Bottom Controls & Advanced Interactive Seeker
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Interactive Seeker Slider
                  if (_videoController != null && _videoController!.value.isInitialized)
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                            thumbColor: Colors.redAccent,
                            activeTrackColor: Colors.redAccent,
                            inactiveTrackColor: Colors.white24,
                          ),
                          child: Slider(
                            value: _videoController!.value.position.inMilliseconds.toDouble().clamp(
                                  0.0,
                                  _videoController!.value.duration.inMilliseconds.toDouble() > 0
                                      ? _videoController!.value.duration.inMilliseconds.toDouble()
                                      : 100.0,
                                ),
                            max: _videoController!.value.duration.inMilliseconds.toDouble() > 0
                                ? _videoController!.value.duration.inMilliseconds.toDouble()
                                : 100.0,
                            onChanged: (val) {
                              _videoController!.seekTo(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_videoController!.value.position),
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _videoController!.value.duration > Duration.zero
                                        ? _formatDuration(_videoController!.value.duration)
                                        : 'LIVE DVR',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 2),

                  // Control Buttons Row
                  Row(
                    children: [
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: _togglePlay,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.replay_10, color: Colors.white70),
                        onPressed: () => _skip(-10),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.forward_10, color: Colors.white70),
                        onPressed: () => _skip(10),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white70),
                        onPressed: _toggleMute,
                      ),
                      const Spacer(),

                      // Collapse / Expand Toggle
                      GestureDetector(
                        onTap: () => setState(() => _isChannelListCollapsed = !_isChannelListCollapsed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isChannelListCollapsed ? Icons.view_sidebar_rounded : Icons.crop_free_rounded,
                                color: Colors.white70,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isChannelListCollapsed ? 'GUIDE' : 'EXPAND',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Speed Selector
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_playbackSpeed}x',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Fullscreen Icon
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_indicatorIcon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            _indicatorText!,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: _toggleFullscreen,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
            child: Text('LIVE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeChannel.name,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
            onPressed: _toggleMute,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterSkipControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(iconSize: 34, icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => _skip(-10)),
        const SizedBox(width: 32),
        IconButton(
          iconSize: 48,
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
          onPressed: _togglePlay,
        ),
        const SizedBox(width: 32),
        IconButton(iconSize: 34, icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => _skip(10)),
      ],
    );
  }

  Widget _buildFullscreenBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                thumbColor: Colors.redAccent,
                activeTrackColor: Colors.redAccent,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(
                value: _videoController!.value.position.inMilliseconds.toDouble().clamp(
                      0.0,
                      _videoController!.value.duration.inMilliseconds.toDouble() > 0
                          ? _videoController!.value.duration.inMilliseconds.toDouble()
                          : 100.0,
                    ),
                max: _videoController!.value.duration.inMilliseconds.toDouble() > 0
                    ? _videoController!.value.duration.inMilliseconds.toDouble()
                    : 100.0,
                onChanged: (val) => _videoController!.seekTo(Duration(milliseconds: val.toInt())),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_videoController?.value.position ?? Duration.zero),
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideHeader(int channelCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Channel Guide',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () => setState(() => _isChannelListCollapsed = true),
            child: Row(
              children: [
                Text(
                  '$channelCount Available',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: IPTVService.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, index) {
          final cat = IPTVService.categories[index];
          final isSel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isSel ? Colors.white : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSel ? Colors.white : const Color(0xFF222222)),
              ),
              child: Text(
                cat,
                style: GoogleFonts.outfit(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: TextField(
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search channels...',
            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList(List<LiveChannel> filteredChannels) {
    if (filteredChannels.isEmpty) {
      return Center(
        child: Text(
          'No channels found',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredChannels.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF141414), height: 1),
      itemBuilder: (ctx, index) {
        final channel = filteredChannels[index];
        final isActive = _activeChannel.id == channel.id;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          tileColor: isActive ? const Color(0xFF181818) : Colors.transparent,
          leading: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          title: Text(
            channel.name,
            style: GoogleFonts.outfit(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          subtitle: Text(
            channel.group,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
          ),
          trailing: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          onTap: () {
            setState(() => _activeChannel = channel);
            _initPlayer(channel.streamUrl);
          },
        );
      },
    );
  }
}
