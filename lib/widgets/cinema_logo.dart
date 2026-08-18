import 'package:flutter/material.dart';

class CinemaLogoWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const CinemaLogoWidget({
    super.key,
    this.size = 28,
    this.animate = true,
  });

  @override
  State<CinemaLogoWidget> createState() => _CinemaLogoWidgetState();
}

class _CinemaLogoWidgetState extends State<CinemaLogoWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CinemaLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _CinemaLogoPainter(animationValue: 0.0),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = _glowAnimation.value;
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Pulsing Red / Crimson Cinematic Breathing Glow
                BoxShadow(
                  color: const Color(0xFFE50914).withValues(alpha: glow * 0.5),
                  blurRadius: widget.size * 0.45,
                  spreadRadius: widget.size * 0.05,
                ),
                // Subtle White Core Highlight
                BoxShadow(
                  color: Colors.white.withValues(alpha: glow * 0.25),
                  blurRadius: widget.size * 0.2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CinemaLogoPainter(
                animationValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CinemaLogoPainter extends CustomPainter {
  final double animationValue;

  _CinemaLogoPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    // Subtle dynamic brightness based on breath cycle
    final brightness = (200 + (animationValue * 55)).toInt().clamp(0, 255);
    final dynamicWhite = Color.fromARGB(255, brightness, brightness, brightness);

    final strokePaint = Paint()
      ..color = dynamicWhite
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;

    final perfPaint = Paint()
      ..color = dynamicWhite
      ..style = PaintingStyle.fill;

    final dimPaint = Paint()
      ..color = Color.lerp(const Color(0xFF52525B), const Color(0xFF8E8E93), animationValue)!
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final redAccentPaint = Paint()
      ..color = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFE50914), animationValue)!
      ..style = PaintingStyle.fill;

    // ── LEFT FILM STRIP ──
    final leftRect = const Rect.fromLTRB(3, 4, 7, 20);
    canvas.drawRect(leftRect, fillPaint);
    canvas.drawLine(const Offset(3, 4), const Offset(3, 20), strokePaint);
    canvas.drawLine(const Offset(7, 4), const Offset(7, 20), strokePaint);
    canvas.drawLine(const Offset(3, 4), const Offset(7, 4), dimPaint);
    canvas.drawLine(const Offset(3, 20), const Offset(7, 20), dimPaint);

    for (final y in [6.0, 9.0, 12.0, 15.0, 18.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4, y - 0.5, 2, 1), const Radius.circular(0.2)),
        perfPaint,
      );
    }

    // ── RIGHT FILM STRIP ──
    final rightRect = const Rect.fromLTRB(17, 4, 21, 20);
    canvas.drawRect(rightRect, fillPaint);
    canvas.drawLine(const Offset(17, 4), const Offset(17, 20), strokePaint);
    canvas.drawLine(const Offset(21, 4), const Offset(21, 20), strokePaint);
    canvas.drawLine(const Offset(17, 4), const Offset(21, 4), dimPaint);
    canvas.drawLine(const Offset(17, 20), const Offset(21, 20), dimPaint);

    for (final y in [6.0, 9.0, 12.0, 15.0, 18.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(18, y - 0.5, 2, 1), const Radius.circular(0.2)),
        perfPaint,
      );
    }

    // ── CENTER SCREEN FRAME ──
    final centerRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 5, 8, 14),
      const Radius.circular(1.2),
    );
    canvas.drawRRect(centerRRect, fillPaint);
    canvas.drawRRect(centerRRect, strokePaint);

    // Subtle grid lines
    canvas.drawLine(const Offset(8, 9), const Offset(16, 9), dimPaint);
    canvas.drawLine(const Offset(8, 15), const Offset(16, 15), dimPaint);

    // ── CENTER PLAY TRIANGLE ──
    final playScale = 1.0 + (animationValue * 0.15);
    canvas.save();
    canvas.translate(12, 12);
    canvas.scale(playScale);
    canvas.translate(-12, -12);

    final playPath = Path()
      ..moveTo(10.5, 9.5)
      ..lineTo(14.5, 12.0)
      ..lineTo(10.5, 14.5)
      ..close();

    // Red accent play triangle with breathing fill
    canvas.drawPath(playPath, redAccentPaint);
    canvas.drawPath(playPath, strokePaint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CinemaLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
