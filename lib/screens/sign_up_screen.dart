import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/cinema_logo.dart';
import '../theme/fonts.dart';
import 'main_nav_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required fields.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (!_agreeTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms of Service.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.register(name: name, email: email, password: password);
    if (!mounted) return;

    if (res.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message ?? 'Registration failed. Please try again.';
      });
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      const CinemaLogoWidget(size: 48, animate: true),
                      const SizedBox(height: 14),
                      Text(
                        'Create Account',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join Pure Cinema for personalized 4K streaming',
                        style: AppFonts.sCoreDream(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

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
                  const SizedBox(height: 16),
                ],

                // Full Name
                Text(
                  'FULL NAME',
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'John Doe',
                    hintStyle: AppFonts.sCoreDream(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 18),
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
                const SizedBox(height: 16),

                // Email
                Text(
                  'EMAIL ADDRESS',
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
                const SizedBox(height: 16),

                // Password
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
                    hintText: 'Minimum 6 characters',
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
                ),
                const SizedBox(height: 16),

                // Confirm Password
                Text(
                  'CONFIRM PASSWORD',
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    hintStyle: AppFonts.sCoreDream(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.white38, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                  onSubmitted: (_) => _handleSignUp(),
                ),
                const SizedBox(height: 16),

                // Terms agreement
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      activeColor: const Color(0xFFE50914),
                      side: const BorderSide(color: Colors.white38),
                      onChanged: (v) => setState(() => _agreeTerms = v ?? true),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms of Service & Privacy Policy',
                        style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create account button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'CREATE ACCOUNT',
                            style: AppFonts.sCoreDream(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Link to Sign In
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: AppFonts.sCoreDream(
                            color: Colors.white,
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
