import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/live_channel.dart';
import '../services/iptv_service.dart';
import '../theme/fonts.dart';

class LiveTVScreen extends StatefulWidget {
  final LiveChannel? initialChannel;
  final bool isActive;
  final ValueChanged<bool>? onFullscreenChanged;

  const LiveTVScreen({
    super.key,
    this.initialChannel,
    this.isActive = true,
    this.onFullscreenChanged,
  });

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  late LiveChannel _activeChannel;
  String _selectedCategory = 'All Channels';
  String _selectedCountry = 'All';
  String _searchQuery = '';
  VideoPlayerController? _videoController;
  bool _isInitializing = true;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _hasError = false;
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

  // Custom Stream URL controller
  final TextEditingController _customUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeChannel = widget.initialChannel ?? IPTVService.channels.first;
    _isInitializing = widget.isActive;
    
    // Load dynamic IPTV-org channels in background
    IPTVService.loadIPTVOrgChannels(onUpdated: () {
      if (mounted) setState(() {});
    });

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

  Future<void> _initPlayer(String url, {bool isRetryWithProxy = false}) async {
    if (!widget.isActive) return;
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });
    await _videoController?.dispose();

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      if (!widget.isActive || !mounted) {
        await _videoController?.pause();
        return;
      }
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
          _hasError = false;
        });
        _startHideTimer();
      }
    } catch (err) {
      debugPrint('Stream $url failed: $err. Trying proxy...');
      if (!isRetryWithProxy && !url.contains('stream-proxy')) {
        final proxyUrl = '${IPTVService.backendApiUrl}/stream-proxy?url=${Uri.encodeComponent(url)}';
        await _initPlayer(proxyUrl, isRetryWithProxy: true);
      } else {
        // Fallback to high-reliability verified live stream
        try {
          const fallbackUrl = 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8';
          _videoController = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
          await _videoController!.initialize();
          if (mounted) {
            _videoController!.setLooping(true);
            _videoController!.setVolume(_isMuted ? 0.0 : _volume);
            _videoController!.play();
            setState(() {
              _isInitializing = false;
              _isPlaying = true;
              _hasError = false;
            });
            _startHideTimer();
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _isInitializing = false;
              _hasError = true;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _videoController?.dispose();
    _customUrlController.dispose();
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

    widget.onFullscreenChanged?.call(_isFullscreen);

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

  void _openVlcStreamDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF282828)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stream_rounded, color: Color(0xFFE50914), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'VLC Network Stream',
              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter any HTTP, HLS (.m3u8), MP4 or IPTV stream URL to play directly:',
              style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _customUrlController,
              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://.../stream.m3u8',
                hintStyle: AppFonts.sCoreDream(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: Text('Mux HLS Test', style: AppFonts.sCoreDream(fontSize: 10, color: Colors.white70)),
                  backgroundColor: const Color(0xFF202020),
                  onPressed: () => _customUrlController.text = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                ),
                ActionChip(
                  label: Text('Akamai Test', style: AppFonts.sCoreDream(fontSize: 10, color: Colors.white70)),
                  backgroundColor: const Color(0xFF202020),
                  onPressed: () => _customUrlController.text = 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppFonts.sCoreDream(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final url = _customUrlController.text.trim();
              if (url.isNotEmpty) {
                final customChannel = LiveChannel(
                  id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                  name: 'Custom Stream',
                  logo: 'https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=100&h=100&fit=crop&q=80',
                  group: 'Custom',
                  streamUrl: url,
                  badge: 'VLC NET',
                  currentProgram: 'Custom Network Stream',
                );
                setState(() => _activeChannel = customChannel);
                _initPlayer(url);
                Navigator.pop(ctx);
              }
            },
            child: Text('Stream Now', style: AppFonts.sCoreDream(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final filteredChannels = IPTVService.getFilteredChannels(
      category: _selectedCategory,
      country: _selectedCountry,
      query: _searchQuery,
    );

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
                            _buildCountryChips(),
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
                      _buildCountryChips(),
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
                        style: AppFonts.sCoreDream(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 2),
                  const SizedBox(height: 12),
                  Text(
                    'Buffering Live Stream...',
                    style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            )
          else if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Live Stream Offline or Geo-Restricted',
                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select another channel or tap retry below',
                    style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('Retry Stream', style: AppFonts.sCoreDream(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _initPlayer(_activeChannel.streamUrl),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Text(
                'Live Signal Connecting...',
                style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 12),
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
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _activeChannel.badge ?? 'LIVE',
                    style: AppFonts.sCoreDream(
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
                    style: AppFonts.sCoreDream(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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
                            thumbColor: const Color(0xFFE50914),
                            activeTrackColor: const Color(0xFFE50914),
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
                                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 10),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE50914),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _videoController!.value.duration > Duration.zero
                                        ? _formatDuration(_videoController!.value.duration)
                                        : 'LIVE DVR',
                                    style: AppFonts.sCoreDream(
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
                                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
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
                            style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
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
            style: AppFonts.sCoreDream(
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
            decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(4)),
            child: Text('LIVE', style: AppFonts.sCoreDream(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeChannel.name,
              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
                thumbColor: const Color(0xFFE50914),
                activeTrackColor: const Color(0xFFE50914),
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
                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
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

  static String getCountryFlagEmoji(String countryCode) {
    if (countryCode == 'All' || countryCode.isEmpty) return '🌐';
    String code = countryCode.toUpperCase();
    if (code == 'UK') code = 'GB';
    if (code.length != 2) return '🌐';
    try {
      final int first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
      final int second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(first) + String.fromCharCode(second);
    } catch (_) {
      return '🌐';
    }
  }

  Widget _buildGuideHeader(int channelCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Live IPTV Guide',
                style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (IPTVService.isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 1.5),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _isChannelListCollapsed = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$channelCount Channels',
                  style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(width: 4),
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
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2),
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
              child: Center(
                child: Text(
                  cat,
                  style: AppFonts.sCoreDream(
                    color: isSel ? Colors.black : Colors.white70,
                    fontSize: 10.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountryChips() {
    return Container(
      height: 28,
      margin: const EdgeInsets.only(top: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: IPTVService.countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (ctx, index) {
          final country = IPTVService.countries[index];
          final isSel = _selectedCountry == country;
          final flag = getCountryFlagEmoji(country);
          return GestureDetector(
            onTap: () => setState(() => _selectedCountry = country),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFE50914).withValues(alpha: 0.25) : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSel ? const Color(0xFFE50914) : const Color(0xFF1E1E1E),
                ),
              ),
              child: Center(
                child: Text(
                  country == 'All' ? '🌐 ALL REGIONS' : '$flag $country',
                  style: AppFonts.sCoreDream(
                    color: isSel ? const Color(0xFFE50914) : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: TextField(
          style: AppFonts.sCoreDream(color: Colors.white, fontSize: 12),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search 10,000+ IPTV channels...',
            hintStyle: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 14),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38, size: 14),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_off_rounded, color: Colors.white24, size: 36),
            const SizedBox(height: 8),
            Text(
              'No channels matching query',
              style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() {
                _selectedCategory = 'All Channels';
                _selectedCountry = 'All';
                _searchQuery = '';
              }),
              child: Text('Reset Filters', style: AppFonts.sCoreDream(color: const Color(0xFFE50914), fontSize: 11)),
            ),
          ],
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          tileColor: isActive ? const Color(0xFF181818) : Colors.transparent,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? const Color(0xFFE50914) : const Color(0xFF222222),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: channel.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: channel.logo,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          channel.name.substring(0, channel.name.isNotEmpty ? 1 : 0).toUpperCase(),
                          style: AppFonts.sCoreDream(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
          title: Text(
            channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.sCoreDream(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                channel.group,
                style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 10),
              ),
              if (channel.country != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${getCountryFlagEmoji(channel.country!)} ${channel.country}',
                  style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 9.5),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (channel.badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    channel.badge!,
                    style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'PLAYING',
                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          onTap: () {
            setState(() => _activeChannel = channel);
            _initPlayer(channel.streamUrl);
          },
        );
      },
    );
  }
}
