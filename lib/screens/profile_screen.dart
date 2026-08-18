import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'auth_screen.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  int _watchlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.getCurrentUser();
    final watchlist = await DatabaseService.getWatchlist();

    if (mounted) {
      setState(() {
        _user = user;
        _watchlistCount = watchlist.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out of Pure Cinema?',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LandingScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 250),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ACCOUNT PROFILE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: _user == null ? _buildLoggedOutView() : _buildProfileView(),
            ),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.person_outline_rounded, size: 40, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          Text(
            'Guest Session',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync your watchlist, unlock 4K streams, and access live channels.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen(initialMode: AuthMode.signIn)),
                );
              },
              child: Text(
                'SIGN IN',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final user = _user!;
    final isAdmin = user.isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAdmin ? const Color(0xFFE50914).withValues(alpha: 0.5) : const Color(0xFF222222),
            ),
            boxShadow: [
              if (isAdmin)
                BoxShadow(
                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAdmin ? const Color(0xFFE50914) : const Color(0xFF222222),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  image: user.avatar != null && user.avatar!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(user.avatar!), fit: BoxFit.cover)
                      : null,
                ),
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdmin ? Icons.verified_rounded : Icons.star_rounded,
                            size: 12,
                            color: isAdmin ? const Color(0xFFE50914) : const Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdmin ? 'Administrator' : 'Premium Member',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Stats Row
        Row(
          children: [
            _buildStatCard('Watchlist', _watchlistCount.toString(), Icons.bookmark_added_rounded),
            const SizedBox(width: 12),
            _buildStatCard('Stream Quality', '4K UHD', Icons.high_quality_rounded),
            const SizedBox(width: 12),
            _buildStatCard('Live Channels', '85+ HD', Icons.live_tv_rounded),
          ],
        ),

        const SizedBox(height: 28),

        // Settings / Actions Group
        Text(
          'ACCOUNT SETTINGS',
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        _buildMenuOption(
          icon: Icons.shield_outlined,
          title: 'Email Security & Verification',
          subtitle: 'Your email address is secured',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF181818),
                content: Text(
                  'Email ${user.email} is verified and secured.',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
              ),
            );
          },
        ),

        _buildMenuOption(
          icon: Icons.lock_reset_rounded,
          title: 'Reset Password',
          subtitle: 'Request verification code to change password',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthScreen(
                  initialMode: AuthMode.forgotPassword,
                  initialEmail: user.email,
                ),
              ),
            );
          },
        ),

        _buildMenuOption(
          icon: Icons.switch_account_outlined,
          title: 'Switch Account',
          subtitle: 'Sign in with another user or admin profile',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthScreen(initialMode: AuthMode.signIn)),
            );
          },
        ),

        const SizedBox(height: 24),

        // Sign Out Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x66E50914)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: const Color(0x1AE50914),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFF5252)),
            label: Text(
              'SIGN OUT OF PURE CINEMA',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5252),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white54),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white30),
      ),
    );
  }
}
