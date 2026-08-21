import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/subscription_modal.dart';
import '../theme/fonts.dart';
import 'auth_screen.dart';
import 'landing_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

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
    DatabaseService.watchlistNotifier.addListener(_loadProfile);
  }

  @override
  void dispose() {
    DatabaseService.watchlistNotifier.removeListener(_loadProfile);
    super.dispose();
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
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
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
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
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
              color: isAdmin ? Colors.white : const Color(0xFF222222),
            ),
            boxShadow: [
              if (isAdmin)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
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
                  color: const Color(0xFF18181B),
                  border: Border.all(color: Colors.white70, width: 1.5),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: GoogleFonts.outfit(
                                color: Colors.black,
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
                            color: Colors.white,
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

        // VIP Subscription Option
        _buildMenuOption(
          icon: Icons.workspace_premium_rounded,
          title: 'Pure Cinema VIP Pass',
          subtitle: 'Upgrade to 4K Master streaming & Dolby Atmos',
          onTap: () => SubscriptionModal.show(context),
        ),

        _buildMenuOption(
          icon: Icons.analytics_rounded,
          title: 'Usage & Streaming Analytics',
          subtitle: 'View watch time stats, top genres & bandwidth metrics',
          onTap: () => _openUsageAnalyticsModal(context),
        ),

        _buildMenuOption(
          icon: Icons.tune_rounded,
          title: 'App & Streaming Settings',
          subtitle: 'Quality preferences, audio spatialization & cache',
          onTap: () => _openAppSettingsModal(context),
        ),

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
                  style: AppFonts.sCoreDream(color: Colors.white),
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
              MaterialPageRoute(builder: (_) => const SignInScreen()),
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
              side: const BorderSide(color: Color(0xFF3F3F46)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: const Color(0xFF121214),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white70),
            label: Text(
              'SIGN OUT OF PURE CINEMA',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

  void _openUsageAnalyticsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Color(0xFF00E5FF), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'USAGE & STREAMING ANALYTICS',
                    style: AppFonts.sCoreDream(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Personalized telemetry & consumption insights across your devices',
                style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
              ),
              const Divider(color: Color(0xFF1F1F23), height: 24),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121216),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer_rounded, color: Colors.amber, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL WATCH TIME',
                                style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '48 hrs 24 mins',
                                style: AppFonts.sCoreDream(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '+6.2 hrs this week • Top 5% Cinephile',
                                style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'TOP GENRES WATCHED',
                      style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 10),
                    _buildGenreProgress('Sci-Fi & Cyberpunk', 0.45, '45%', Colors.cyanAccent),
                    _buildGenreProgress('Drama & Masterpieces', 0.28, '28%', Colors.amber),
                    _buildGenreProgress('Action & Thriller', 0.18, '18%', Colors.deepOrangeAccent),
                    _buildGenreProgress('Animation & Anime', 0.09, '9%', Colors.purpleAccent),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _buildMetricTile('AI CineBot Queries', '34 Requests', Icons.psychology_rounded, Colors.cyan),
                        const SizedBox(width: 12),
                        _buildMetricTile('Bandwidth Saved', '18.4 GB CDN', Icons.cloud_download_rounded, Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetricTile('4K Ultra HD Ratio', '82% Direct', Icons.high_quality_rounded, Colors.amber),
                        const SizedBox(width: 12),
                        _buildMetricTile('Active Sessions', 'Web & Android', Icons.devices_rounded, Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenreProgress(String genre, double progress, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(genre, style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 12)),
              Text(percent, style: AppFonts.sCoreDream(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF1E1E24),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121216),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(val, style: AppFonts.sCoreDream(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _openAppSettingsModal(BuildContext context) {
    bool autoplay = true;
    bool spatialAudio = true;
    bool hardwareAccel = true;
    String selectedQuality = '4K Ultra HD (2160p)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'APP & STREAMING PREFERENCES',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure playback quality, audio spatialization & local storage',
                    style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
                  ),
                  const Divider(color: Color(0xFF1F1F23), height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Default Streaming Bitrate', style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Master 60 FPS studio stream allocation', style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11)),
                          trailing: DropdownButton<String>(
                            dropdownColor: const Color(0xFF141418),
                            value: selectedQuality,
                            underline: const SizedBox(),
                            style: AppFonts.sCoreDream(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: '4K Ultra HD (2160p)', child: Text('4K Ultra HD')),
                              DropdownMenuItem(value: 'Full HD (1080p)', child: Text('1080p Full HD')),
                              DropdownMenuItem(value: 'HD Ready (720p)', child: Text('720p HD')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedQuality = val);
                            },
                          ),
                        ),
                        const Divider(color: Color(0xFF18181C)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Autoplay Next Episode', style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Seamless transition between TV series episodes', style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11)),
                          value: autoplay,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF3F3F46),
                          onChanged: (val) => setModalState(() => autoplay = val),
                        ),
                        const Divider(color: Color(0xFF18181C)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dolby Atmos Spatial Audio', style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Hardware spatial audio decoding for headphones', style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11)),
                          value: spatialAudio,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF3F3F46),
                          onChanged: (val) => setModalState(() => spatialAudio = val),
                        ),
                        const Divider(color: Color(0xFF18181C)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Hardware GPU Acceleration', style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Low-latency webGL & hardware video decoding', style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11)),
                          value: hardwareAccel,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF3F3F46),
                          onChanged: (val) => setModalState(() => hardwareAccel = val),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3F3F46)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.white70),
                            label: Text(
                              'CLEAR LOCAL CACHE & STORAGE (142 MB)',
                              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF18181C),
                                  content: Text('Cleared 142 MB cached assets & temporary data.', style: AppFonts.sCoreDream(color: Colors.white)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
