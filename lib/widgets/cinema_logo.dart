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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CinemaLogoPainter(
              animationValue: widget.animate ? _controller.value : 0.0,
            ),
          );
        },
      ),
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

    final strokePaint = Paint()
      ..color = const Color(0xFFE4E4E7)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;

    final perfPaint = Paint()
      ..color = const Color(0xFFE4E4E7)
      ..style = PaintingStyle.fill;

    final dimPaint = Paint()
      ..color = const Color(0xFF52525B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

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
    final playScale = 1.0 + (animationValue * 0.1);
    canvas.save();
    canvas.translate(12, 12);
    canvas.scale(playScale);
    canvas.translate(-12, -12);

    final playPath = Path()
      ..moveTo(10.5, 9.5)
      ..lineTo(14.5, 12.0)
      ..lineTo(10.5, 14.5)
      ..close();

    canvas.drawPath(playPath, perfPaint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CinemaLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
