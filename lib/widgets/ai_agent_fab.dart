import 'package:flutter/material.dart';
import '../screens/agent_chat_screen.dart';

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

class _AIAgentFabState extends State<AIAgentFab> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _openAgentChatModal,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Silicon Brushed Titanium Metal Finish
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A3A3C),
                Color(0xFF242426),
                Color(0xFF1C1C1E),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF636366),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Precision Inner Bevel Ring
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF2C2C2E),
                      Color(0xFF18181A),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
              ),

              // Clean Silicon Robot Bot Icon
              const Icon(
                Icons.smart_toy_rounded,
                color: Color(0xFFF2F2F7),
                size: 30,
              ),

              // Subtle Minimalist LED Indicator (Clean Soft White)
              Positioned(
                top: 9,
                right: 12,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
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
