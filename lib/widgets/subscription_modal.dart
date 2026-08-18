import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../theme/fonts.dart';

class SubscriptionModal extends StatefulWidget {
  const SubscriptionModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionModal(),
    );
  }

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  List<SubscriptionPlan> _plans = PaymentService.defaultPlans;
  int _selectedPlanIndex = 0;
  bool _isLoading = false;
  bool _mockMode = true; // Enabled by default for effortless testing without real money
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

    // Simulate brief network delay for realism
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
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment could not be completed.', style: AppFonts.sCoreDream()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D11),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(8),
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
                            'Paystack Secure Checkout',
                            style: AppFonts.sCoreDream(
                              color: const Color(0xFF00C3F7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1C1C24), height: 24),

            Expanded(
              child: _isSuccess ? _buildSuccessView() : _buildPlanSelectionView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Mode Switch Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _mockMode ? const Color(0xFF132219) : const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _mockMode ? const Color(0xFF00FF66).withValues(alpha: 0.4) : const Color(0xFF2E2E38),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _mockMode ? Icons.bolt_rounded : Icons.credit_card_rounded,
                  color: _mockMode ? const Color(0xFF00FF66) : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mockMode ? 'Mock Test Payment (Instant)' : 'Live Paystack Gateway',
                        style: AppFonts.sCoreDream(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _mockMode ? 'Simulates payment approval without debiting real card' : 'Connects to live Paystack checkout',
                        style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _mockMode,
                  activeColor: const Color(0xFF00FF66),
                  onChanged: (val) => setState(() => _mockMode = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'CHOOSE YOUR CINEMA PASS',
            style: AppFonts.sCoreDream(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // Plan Cards
          ...List.generate(_plans.length, (index) {
            final plan = _plans[index];
            final isSelected = _selectedPlanIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E1528) : const Color(0xFF14141A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE50914) : const Color(0xFF22222E),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: AppFonts.sCoreDream(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (plan.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  plan.badge!,
                                  style: AppFonts.sCoreDream(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '₦${plan.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                          style: AppFonts.sCoreDream(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Billed ${plan.period}',
                      style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    ...plan.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                f,
                                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11.5),
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

          const SizedBox(height: 16),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'PAY VIA PAYSTACK (₦${_plans[_selectedPlanIndex].price})',
                      style: AppFonts.sCoreDream(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF00FF66),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'VIP Access Activated!',
              style: AppFonts.sCoreDream(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Pure Cinema VIP Pass is now active. Enjoy ad-free 4K master streaming and offline downloads.',
              textAlign: TextAlign.center,
              style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_successRef != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF181822),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Reference: $_successRef',
                  style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 10),
                ),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'START WATCHING IN VIP',
                  style: AppFonts.sCoreDream(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
