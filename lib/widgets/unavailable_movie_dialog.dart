import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/fonts.dart';
import '../models/movie.dart';

class UnavailableMovieDialog extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onSwitchToAvailable;
  final VoidCallback? onSwitchToLiveTV;

  const UnavailableMovieDialog({
    super.key,
    required this.movie,
    this.onSwitchToAvailable,
    this.onSwitchToLiveTV,
  });

  static void show(
    BuildContext context, {
    required Movie movie,
    VoidCallback? onSwitchToAvailable,
    VoidCallback? onSwitchToLiveTV,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => UnavailableMovieDialog(
        movie: movie,
        onSwitchToAvailable: onSwitchToAvailable,
        onSwitchToLiveTV: onSwitchToLiveTV,
      ),
    );
  }

  @override
  State<UnavailableMovieDialog> createState() => _UnavailableMovieDialogState();
}

class _UnavailableMovieDialogState extends State<UnavailableMovieDialog> {
  late String _fullText;
  String _displayedText = '';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();
    _fullText =
        "We sincerely apologize. Streaming distribution clearance for '${widget.movie.title}' is currently undergoing legal compliance and licensing review.\n\nIn the meantime, enjoy 10,000+ Live TV Channels or stream from our verified 100% legal Available Movies Vault below!";
    _startTypewriterEffect();
  }

  void _startTypewriterEffect() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_charIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayedText += _fullText[_charIndex];
            _charIndex++;
          });
        }
      } else {
        _typewriterTimer?.cancel();
        if (mounted) {
          setState(() => _isTypingComplete = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C0C0E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF27272A), width: 1.2),
      ),
      contentPadding: const EdgeInsets.all(22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge & Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.gavel_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEGAL CLEARANCE IN PROGRESS',
                      style: AppFonts.sCoreDream(
                        color: Colors.amber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Pure Cinema Rights Engine',
                      style: AppFonts.sCoreDream(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1F1F23), height: 1),
          const SizedBox(height: 16),

          // Typewriter Text Field with glowing cursor
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F23)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _displayedText,
                          style: AppFonts.sCoreDream(
                            color: const Color(0xFFE4E4E7),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                        if (!_isTypingComplete)
                          TextSpan(
                            text: ' █',
                            style: AppFonts.sCoreDream(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSwitchToAvailable?.call();
                  },
                  icon: const Icon(Icons.movie_rounded, size: 16, color: Colors.black),
                  label: Text(
                    'EXPLORE AVAILABLE MOVIES',
                    style: AppFonts.sCoreDream(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSwitchToLiveTV?.call();
                  },
                  icon: const Icon(Icons.live_tv_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'SWITCH TO LIVE TV (10,000+ CHANNELS)',
                    style: AppFonts.sCoreDream(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
