import 'package:flutter/material.dart';
import '../screens/agent_chat_screen.dart';
import '../theme/fonts.dart';

class AIAgentFab extends StatefulWidget {
  final Function(int index)? onNavigateTab;
  final Function(int movieId)? onOpenMovie;

  const AIAgentFab({
    super.key,
    this.onNavigateTab,
    this.onOpenMovie,
  });

  @override
  State<AIAgentFab> createState() => _AIAgentFabState();
}

class _AIAgentFabState extends State<AIAgentFab> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // Pulsing aura animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subtle floating hover animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _openAgentChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentChatScreen(
        onNavigateTab: widget.onNavigateTab,
        onOpenMovie: widget.onOpenMovie,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _openAgentChatModal,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFE50914),
                Color(0xFF7928CA),
                Color(0xFF0F051D),
              ],
              center: Alignment(-0.2, -0.3),
              radius: 1.1,
            ),
            border: Border.all(
              color: const Color(0xFFFF4D4D).withValues(alpha: 0.8),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF7928CA).withValues(alpha: 0.6),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating Neon Orbit Ring
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
              ),

              // Huge Actual Robot / Bot Icon
              const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 38,
              ),

              // Bot Antenna Top Glowing Signal
              Positioned(
                top: 7,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // AI Live Status Badge Pill (Bottom)
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF66),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00FF66),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'AI BOT',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
