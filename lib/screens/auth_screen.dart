import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/cinema_logo.dart';
import 'main_nav_screen.dart';

enum AuthMode { signIn, register, otp, forgotPassword }

class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;
  final String? initialEmail;

  const AuthScreen({
    super.key,
    this.initialMode = AuthMode.signIn,
    this.initialEmail,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Timer? _timer;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown([int seconds = 60]) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
      (route) => false,
    );
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await AuthService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _enterApp();
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Invalid email or password');
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await AuthService.register(name: name, email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _enterApp();
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Registration failed');
    }
  }

  Future<void> _handleSendOtp({String purpose = 'login'}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email to receive code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.sendOtp(email: email, purpose: purpose);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _startCountdown(60);
      setState(() {
        _mode = AuthMode.otp;
        _successMessage = res['message'] ?? 'Verification code sent to your email!';
      });
      if (res['devCode'] != null) {
        _otpController.text = res['devCode'].toString();
      }
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Failed to send verification code');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();

    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.verifyOtp(
      email: email,
      code: code,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _enterApp();
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Invalid verification code');
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code from email');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'New password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _mode = AuthMode.signIn;
        _successMessage = 'Password updated successfully! Please sign in.';
      });
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Password reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.network(
                'https://image.tmdb.org/t/p/original/mBaXZ95R2v4ZhBv298G6ZzK2k9y.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF050505)),
              ),
            ),
          ),

          // Vignette
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF0050505),
                    Color(0xCC050505),
                    Color(0xFF050505),
                  ],
                ),
              ),
            ),
          ),

          // Form Center Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand
                      Center(
                        child: Column(
                          children: [
                            const CinemaLogoWidget(size: 36, animate: true),
                            const SizedBox(height: 12),
                            Text(
                              'PURE CINEMA',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mode == AuthMode.signIn
                                  ? 'Sign in to your account'
                                  : _mode == AuthMode.register
                                      ? 'Create your free account'
                                      : _mode == AuthMode.otp
                                          ? 'Enter verification code'
                                          : 'Reset your password',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In / Register Tabs
                      if (_mode == AuthMode.signIn || _mode == AuthMode.register)
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF282828)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTab(
                                  label: 'SIGN IN',
                                  isSelected: _mode == AuthMode.signIn,
                                  onTap: () => setState(() {
                                    _mode = AuthMode.signIn;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  }),
                                ),
                              ),
                              Expanded(
                                child: _buildTab(
                                  label: 'REGISTER',
                                  isSelected: _mode == AuthMode.register,
                                  onTap: () => setState(() {
                                    _mode = AuthMode.register;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),

                      // Main Card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0C0C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF222222)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Alerts
                            if (_errorMessage != null)
                              _buildAlert(_errorMessage!, isError: true),
                            if (_successMessage != null)
                              _buildAlert(_successMessage!, isError: false),

                            // Fields
                            if (_mode == AuthMode.signIn) ...[
                              _buildInput(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'name@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _buildInput(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _mode = AuthMode.forgotPassword;
                                    _errorMessage = null;
                                  }),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildPrimaryButton(
                                label: 'SIGN IN',
                                onPressed: _handleSignIn,
                              ),
                              const SizedBox(height: 10),
                              _buildSecondaryButton(
                                label: 'Email Me a Login Code',
                                icon: Icons.mark_email_read_outlined,
                                onPressed: () => _handleSendOtp(purpose: 'login'),
                              ),
                            ] else if (_mode == AuthMode.register) ...[
                              _buildInput(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'John Doe',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),
                              _buildInput(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'name@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _buildInput(
                                controller: _passwordController,
                                label: 'Password (min 6 characters)',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 18),
                              _buildPrimaryButton(
                                label: 'CREATE ACCOUNT',
                                onPressed: _handleRegister,
                              ),
                            ] else if (_mode == AuthMode.otp) ...[
                              Text(
                                'Verification code sent to:',
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emailController.text.trim(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildInput(
                                controller: _otpController,
                                label: '6-Digit Code',
                                hint: '123456',
                                icon: Icons.security_rounded,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                letterSpacing: 6.0,
                              ),
                              const SizedBox(height: 18),
                              _buildPrimaryButton(
                                label: 'VERIFY & ENTER',
                                onPressed: _handleVerifyOtp,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _countdown > 0
                                        ? null
                                        : () => _handleSendOtp(purpose: 'login'),
                                    child: Text(
                                      _countdown > 0 ? 'Resend in ${_countdown}s' : 'Resend Code',
                                      style: GoogleFonts.outfit(
                                        color: _countdown > 0
                                            ? Colors.white30
                                            : const Color(0xFFE50914),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('|', style: GoogleFonts.outfit(color: Colors.white24)),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() => _mode = AuthMode.signIn),
                                    child: Text(
                                      'Back to Sign In',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_mode == AuthMode.forgotPassword) ...[
                              _buildInput(
                                controller: _emailController,
                                label: 'Your Registered Email',
                                hint: 'name@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildSecondaryButton(
                                label: _countdown > 0
                                    ? 'Code Sent (${_countdown}s)'
                                    : 'Send Reset Code to Email',
                                icon: Icons.send_rounded,
                                onPressed: _countdown > 0
                                    ? null
                                    : () => _handleSendOtp(purpose: 'reset'),
                              ),
                              const SizedBox(height: 14),
                              _buildInput(
                                controller: _otpController,
                                label: '6-Digit Code from Email',
                                hint: '123456',
                                icon: Icons.vpn_key_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 14),
                              _buildInput(
                                controller: _passwordController,
                                label: 'New Password',
                                hint: '••••••••',
                                icon: Icons.lock_reset,
                                isPassword: true,
                              ),
                              const SizedBox(height: 18),
                              _buildPrimaryButton(
                                label: 'UPDATE PASSWORD',
                                onPressed: _handleResetPassword,
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: () => setState(() => _mode = AuthMode.signIn),
                                  child: Text(
                                    'Cancel and Back to Sign In',
                                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Continue as Guest
                      Center(
                        child: TextButton.icon(
                          onPressed: _enterApp,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white54),
                          label: Text(
                            'Continue as Guest',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.black : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextAlign textAlign = TextAlign.start,
    double? letterSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF282828)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            keyboardType: keyboardType,
            textAlign: textAlign,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: letterSpacing,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
              prefixIcon: Icon(icon, size: 18, color: Colors.white38),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2E2E2E)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFF141414),
        ),
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, size: 15, color: Colors.white60),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAlert(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? const Color(0x33E50914) : const Color(0x332E7D32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0x88E50914) : const Color(0x884CAF50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 15,
            color: isError ? const Color(0xFFFF5252) : const Color(0xFF81C784),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: isError ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
