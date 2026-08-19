import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/fonts.dart';

// Conditional import for web platform view
import 'youtube_view_stub.dart'
    if (dart.library.js_interop) 'youtube_view_web.dart';

class YouTubeTrailerView extends StatefulWidget {
  final String trailerKey;
  final String backdropUrl;
  final String title;

  const YouTubeTrailerView({
    super.key,
    required this.trailerKey,
    required this.backdropUrl,
    required this.title,
  });

  @override
  State<YouTubeTrailerView> createState() => _YouTubeTrailerViewState();
}

class _YouTubeTrailerViewState extends State<YouTubeTrailerView> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    if (widget.trailerKey.isEmpty) {
      return _buildBackdropFallback();
    }

    if (kIsWeb) {
      return buildWebYouTubePlayer(widget.trailerKey);
    }

    return _buildBackdropFallback();
  }

  Widget _buildBackdropFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.backdropUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.backdropUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: const Color(0xFF141418)),
          )
        else
          Container(color: const Color(0xFF141418)),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Official Studio Preview',
                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
