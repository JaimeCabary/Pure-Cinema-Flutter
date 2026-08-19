import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/cinema_logo.dart';
import '../theme/fonts.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'main_nav_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _keyBuffer = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final character = event.character;
      if (character != null && character.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(character)) {
        _keyBuffer += character.toLowerCase();
        if (_keyBuffer.length > 10) {
          _keyBuffer = _keyBuffer.substring(_keyBuffer.length - 10);
        }

        if (_keyBuffer.contains('shalom')) {
          _keyBuffer = '';
          _enterAppAsAdmin();
        }
      }
    }
  }

  Future<void> _enterAppAsAdmin() async {
    await AuthService.login(email: 'shalom', password: '');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _openSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _enterAppGuest() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: Stack(
          children: [
            // Background Cinematic Image
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.network(
                  'https://image.tmdb.org/t/p/original/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050505)),
                ),
              ),
            ),

            // Deep Gradient Vignette
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Color(0xFF050505),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Logo (Double tap to unlock Shalom admin)
                    GestureDetector(
                      onDoubleTap: _enterAppAsAdmin,
                      child: Row(
                        children: [
                          const CinemaLogoWidget(size: 26, animate: true),
                          const SizedBox(width: 10),
                          Text(
                            'PURE CINEMA',
                            style: AppFonts.sCoreDream(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Hero Headlines in sCore Dream Medium
                    Text(
                      'UNCOMPROMISED\nCINEMA 4K',
                      style: AppFonts.sCoreDream(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w500, // sCore Dream Medium
                        height: 1.12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Experience master-quality motion pictures, 60 FPS live broadcast suite, and curated visual arts.',
                      style: AppFonts.sCoreDream(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign In Button (Primary White)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _openSignIn,
                        child: Text(
                          'SIGN IN',
                          style: AppFonts.sCoreDream(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Create Account Button (Secondary Monochrome)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18181B),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          side: const BorderSide(color: Color(0xFF3F3F46)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _openSignUp,
                        child: Text(
                          'CREATE ACCOUNT',
                          style: AppFonts.sCoreDream(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Enter as Guest Button (Outline)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF333333)),
                          backgroundColor: const Color(0x33141414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _enterAppGuest,
                        child: Text(
                          'ENTER AS GUEST',
                          style: AppFonts.sCoreDream(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
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
