import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../theme/fonts.dart';

class SubscriptionModal extends StatefulWidget {
  final VoidCallback? onCompleted;

  const SubscriptionModal({super.key, this.onCompleted});

  static Future<void> show(BuildContext context, {VoidCallback? onCompleted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionModal(onCompleted: onCompleted),
    );
  }

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> with SingleTickerProviderStateMixin {
  List<SubscriptionPlan> _plans = PaymentService.defaultPlans;
  int _selectedPlanIndex = 0;
  bool _isLoading = false;
  bool _mockMode = true; // Paystack test mock by default
  bool _isSuccess = false;
  String? _successRef;

  late AnimationController _animController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadPlans();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final plans = await PaymentService.getPlans();
    if (mounted) {
      setState(() => _plans = plans);
    }
  }

  Future<void> _processPayment() async {
    final plan = _plans[_selectedPlanIndex];
    final user = await AuthService.getCurrentUser();
    final email = user?.email ?? 'subscriber@purecinema.app';

    setState(() => _isLoading = true);

    // 1. Initialize Transaction (Live or Mock)
    final initRes = await PaymentService.initializePayment(
      email: email,
      amountInNaira: plan.price,
      planId: plan.id,
      useMock: _mockMode,
    );

    final data = initRes['data'] as Map<String, dynamic>? ?? {};
    final ref = data['reference'] as String? ?? 'pstk_mock_${DateTime.now().millisecondsSinceEpoch}';

    await Future.delayed(const Duration(milliseconds: 900));

    // 2. Verify Transaction
    final verifyRes = await PaymentService.verifyPayment(ref);
    if (!mounted) return;

    final verifyData = verifyRes['data'] as Map<String, dynamic>? ?? {};
    final status = verifyData['status'] as String? ?? 'success';

    if (status == 'success') {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _successRef = ref;
      });
      widget.onCompleted?.call();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment could not be completed.', style: AppFonts.sCoreDream(color: Colors.white)),
          backgroundColor: const Color(0xFF18181B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1.2),
        ),
      ),
      child: Stack(
        children: [
          // Background Custom Whorls & Geometric Patterns
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: VIPGeometricWhorlPainter(
                      glowFactor: _glowAnimation.value,
                      progress: _animController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PURE CINEMA VIP',
                                style: AppFonts.sCoreDream(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              Text(
                                'PAYSTACK 4K MASTER PASS',
                                style: AppFonts.sCoreDream(
                                  color: const Color(0xFFA1A1AA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(color: Color(0xFF1F1F23), height: 1),

                // Content
                Expanded(
                  child: _isSuccess ? _buildSuccessView() : _buildPlanSelectionView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      children: [
        // Mode Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF27272A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Paystack Mock / Test Mode',
                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Switch(
                value: _mockMode,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF3F3F46),
                onChanged: (val) => setState(() => _mockMode = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Plans Header
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SELECT MEMBERSHIP PASS',
              style: AppFonts.sCoreDream(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Plan Cards
        ...List.generate(_plans.length, (index) {
          final plan = _plans[index];
          final isSelected = _selectedPlanIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF141418).withValues(alpha: 0.9)
                    : const Color(0xFF0B0B0E).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF27272A),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white38,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 14, color: Colors.black),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            plan.name,
                            style: AppFonts.sCoreDream(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (plan.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.badge!,
                            style: AppFonts.sCoreDream(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₦${plan.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${plan.period}',
                        style: AppFonts.sCoreDream(color: const Color(0xFFA1A1AA), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF1F1F23), height: 1),
                  const SizedBox(height: 10),

                  // Feature bullets
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: AppFonts.sCoreDream(color: const Color(0xFFD4D4D8), fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Paystack SSL badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 13),
            const SizedBox(width: 6),
            Text(
              'Secured with Paystack 256-Bit SSL · Instant Activation',
              style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Primary Checkout CTA Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onPressed: _isLoading ? null : _processPayment,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    'SUBMIT & ACTIVATE • ₦${_plans[_selectedPlanIndex].price}',
                    style: AppFonts.sCoreDream(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'VIP Membership Activated!',
            style: AppFonts.sCoreDream(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your account is now upgraded to 4K Ultra streaming, Dolby Atmos, and ad-free IPTV broadcast suite.',
            textAlign: TextAlign.center,
            style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Text(
              'Ref: ${_successRef ?? "PSTK_VIP"}',
              style: AppFonts.sCoreDream(color: const Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'START WATCHING 4K CINEMA',
                style: AppFonts.sCoreDream(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Geometric Whorls & Spiral Contour Line Painter
class VIPGeometricWhorlPainter extends CustomPainter {
  final double glowFactor;
  final double progress;

  VIPGeometricWhorlPainter({required this.glowFactor, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Top-Right Luminous Whorl Spirals
    final centerTopRight = Offset(size.width * 0.90, size.height * 0.15);
    for (int i = 1; i <= 14; i++) {
      final radius = i * 22.0 + math.sin(progress * math.pi * 2 + i) * 6.0;
      paint.color = Colors.white.withValues(alpha: 0.02 + (i % 3 == 0 ? 0.04 : 0.01));
      
      final rect = Rect.fromCircle(center: centerTopRight, radius: radius);
      canvas.drawArc(rect, 0.5 + progress * 0.2, math.pi * 1.4, false, paint);
    }

    // 2. Bottom-Left Parametric Wave Curves
    final path = Path();
    for (double i = 0; i < 6; i++) {
      paint.color = Colors.white.withValues(alpha: 0.03 + (i * 0.008));
      path.reset();
      path.moveTo(0, size.height * 0.65 + i * 25);
      path.cubicTo(
        size.width * 0.35,
        size.height * 0.50 + math.sin(progress * math.pi + i) * 30,
        size.width * 0.65,
        size.height * 0.85 + math.cos(progress * math.pi + i) * 30,
        size.width,
        size.height * 0.70 + i * 20,
      );
      canvas.drawPath(path, paint);
    }

    // 3. Subtle Dot Matrix Nodes
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 6; y++) {
        dotPaint.color = Colors.white.withValues(alpha: 0.035);
        canvas.drawCircle(
          Offset(size.width * 0.1 + x * 40, size.height * 0.05 + y * 40),
          1.2,
          dotPaint,
        );
      }
    }

    // 4. Soft Top Ambient Radial Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: glowFactor * 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: centerTopRight, radius: size.width * 0.6));

    canvas.drawCircle(centerTopRight, size.width * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant VIPGeometricWhorlPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.glowFactor != glowFactor;
  }
}
