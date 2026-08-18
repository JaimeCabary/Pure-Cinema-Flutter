import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/cinema_logo.dart';
import '../theme/fonts.dart';
import 'main_nav_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  final String? initialEmail;
  const SignInScreen({super.key, this.initialEmail});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.login(email: email, password: password);
    if (!mounted) return;

    if (res.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message ?? 'Sign in failed. Please check credentials.';
      });
    }
  }

  void _enterAsGuest() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header
                Center(
                  child: Column(
                    children: [
                      const CinemaLogoWidget(size: 48, animate: true),
                      const SizedBox(height: 14),
                      Text(
                        'Welcome Back',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access your theater & watchlist',
                        style: AppFonts.sCoreDream(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Error alert
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppFonts.sCoreDream(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Email field
                Text(
                  'EMAIL OR USERNAME',
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: AppFonts.sCoreDream(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE50914)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password field
                Text(
                  'PASSWORD',
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: AppFonts.sCoreDream(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE50914)),
                    ),
                  ),
                  onSubmitted: (_) => _handleSignIn(),
                ),
                const SizedBox(height: 12),

                // Remember me row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFE50914),
                          side: const BorderSide(color: Colors.white38),
                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        ),
                        Text(
                          'Remember me',
                          style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset link will be sent to your registered email.',
                              style: AppFonts.sCoreDream(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF222222),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppFonts.sCoreDream(
                          color: const Color(0xFFE50914),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _handleSignIn,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : Text(
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

                // Guest button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      backgroundColor: const Color(0x33141414),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _enterAsGuest,
                    child: Text(
                      'CONTINUE AS GUEST',
                      style: AppFonts.sCoreDream(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Link to Sign Up
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: AppFonts.sCoreDream(
                            color: const Color(0xFFE50914),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
