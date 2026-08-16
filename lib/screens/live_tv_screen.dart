import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/live_channel.dart';
import '../services/iptv_service.dart';

class LiveTVScreen extends StatefulWidget {
  final LiveChannel? initialChannel;
  const LiveTVScreen({super.key, this.initialChannel});

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
  final double _volume = 1.0;
  double _playbackSpeed = 1.0;
  
  // Indicator badge
  String? _indicatorText;
  IconData? _indicatorIcon;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _activeChannel = widget.initialChannel ?? IPTVService.channels.first;
    _initPlayer(_activeChannel.streamUrl);
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
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
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
      setState(() => _isPlaying = false);
      _triggerIndicator(Icons.pause, 'PAUSE');
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
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

  @override
  Widget build(BuildContext context) {
    final filteredChannels = IPTVService.searchChannels(_searchQuery, _selectedCategory);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 768;

            if (isDesktop) {
              // 2-Column Desktop / Web Layout
              return Row(
                children: [
                  // Left 65%: Video Player
                  Expanded(
                    flex: 65,
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

                  // Right 35%: Channel Guide
                  Expanded(
                    flex: 35,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF080808),
                        border: Border(left: BorderSide(color: Color(0xFF181818))),
                      ),
                      child: Column(
                        children: [
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

            // Mobile Column Layout (Strict Height Capping to Prevent Overflow)
            return Column(
              children: [
                // Video Player with fixed max height
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.30,
                  width: double.infinity,
                  child: Container(
                    color: Colors.black,
                    child: _buildVideoPlayer(),
                  ),
                ),

                // Category Tabs
                _buildCategoryTabs(),

                // Search Bar
                _buildSearchField(),

                // Channel List takes remaining space
                Expanded(
                  child: _buildChannelList(filteredChannels),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          GestureDetector(
            onTap: _togglePlay,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio > 0 ? _videoController!.value.aspectRatio : 16 / 9,
                child: VideoPlayer(_videoController!),
              ),
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

        // Top Channel Banner Overlay
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
            ],
          ),
        ),

        // Center Indicator Badge
        if (_indicatorText != null)
          Container(
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
          ),

        // Bottom Controls & Scrubber
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
                // Scrubber
                if (_videoController != null && _videoController!.value.isInitialized)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
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

                // Control Buttons Row
                Row(
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.replay_10, color: Colors.white70),
                      onPressed: () => _skip(-10),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.forward_10, color: Colors.white70),
                      onPressed: () => _skip(10),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white70),
                      onPressed: _toggleMute,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? Colors.white : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSel ? Colors.white : const Color(0xFF222222)),
              ),
              child: Text(
                cat,
                style: GoogleFonts.outfit(
                  color: isSel ? Colors.black : Colors.white70,
                  fontSize: 11,
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
