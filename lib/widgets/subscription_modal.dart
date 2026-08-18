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

class _SubscriptionModalState extends State<SubscriptionModal> {
  List<SubscriptionPlan> _plans = PaymentService.defaultPlans;
  int _selectedPlanIndex = 0;
  bool _isLoading = false;
  bool _mockMode = true; // Paystack test mock by default
  bool _isSuccess = false;
  String? _successRef;

  @override
  void initState() {
    super.initState();
    _loadPlans();
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

    // Simulate brief network verification delay for realism
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
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3F3F46)),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pure Cinema VIP',
                            style: AppFonts.sCoreDream(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Paystack 4K Ultra Checkout',
                            style: AppFonts.sCoreDream(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1F1F23), height: 20),

            // Content
            Expanded(
              child: _isSuccess ? _buildSuccessView() : _buildPlanSelectionView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelectionView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        // Mode switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Paystack Test Mock Mode',
                    style: AppFonts.sCoreDream(color: Colors.white, fontSize: 12),
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

        // Plans List
        Text(
          'SELECT A MEMBERSHIP PLAN',
          style: AppFonts.sCoreDream(
            color: const Color(0xFFA1A1AA),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(_plans.length, (index) {
          final plan = _plans[index];
          final isSelected = _selectedPlanIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFF0F0F11),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF27272A),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.white : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            plan.name,
                            style: AppFonts.sCoreDream(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (plan.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.badge!,
                            style: AppFonts.sCoreDream(
                              color: Colors.black,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₦${plan.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${plan.period}',
                        style: AppFonts.sCoreDream(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF27272A), height: 1),
                  const SizedBox(height: 10),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: AppFonts.sCoreDream(color: const Color(0xFFD4D4D8), fontSize: 12),
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

        const SizedBox(height: 10),

        // Paystack security badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(
              'Secured by Paystack 256-Bit SSL Encryption',
              style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Checkout Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _processPayment,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  'Subscribe Now • ₦${_plans[_selectedPlanIndex].price}',
                  style: AppFonts.sCoreDream(fontSize: 15, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You now have unlimited 4K Ultra streaming, ad-free live IPTV, and AI CineBot access.',
            textAlign: TextAlign.center,
            style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF121214),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Text(
              'Ref: ${_successRef ?? "PSTK_VIP"}',
              style: AppFonts.sCoreDream(color: const Color(0xFFA1A1AA), fontSize: 11),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Start Watching 4K Cinema', style: AppFonts.sCoreDream(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
