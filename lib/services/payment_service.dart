import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SubscriptionPlan {
  final String id;
  final String name;
  final int price; // in Naira (e.g. 2500)
  final String currency;
  final String period;
  final List<String> features;
  final String? badge;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.period,
    required this.features,
    this.badge,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String? ?? 'vip_monthly',
      name: json['name'] as String? ?? 'VIP Pass',
      price: (json['price'] as num?)?.toInt() ?? 2500,
      currency: json['currency'] as String? ?? 'NGN',
      period: json['period'] as String? ?? 'Monthly',
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      badge: json['badge'] as String?,
    );
  }
}

class PaymentService {
  static const String _productionUrl = 'https://pure-cinema-backend.onrender.com/api/payment';

  static String get baseUrl {
    if (kIsWeb) {
      if (Uri.base.host.isNotEmpty && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
        if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(Uri.base.host)) {
          return 'http://${Uri.base.host}:3000/api/payment';
        }
      }
      return _productionUrl;
    }
    return _productionUrl;
  }

  // Fallback / Default VIP plans
  static const List<SubscriptionPlan> defaultPlans = [
    SubscriptionPlan(
      id: 'vip_monthly',
      name: 'Pure Cinema VIP Pass',
      price: 2500,
      currency: 'NGN',
      period: 'Monthly',
      features: [
        '4K HDR 60 FPS Master Bitrate',
        'Ad-Free on all 10,000+ Live Channels',
        'Unlimited Offline Downloads',
        'AI CineBot Unlimited Recommendations',
        'Dolby Atmos Spatial Audio',
      ],
      badge: 'MOST POPULAR',
    ),
    SubscriptionPlan(
      id: 'ultra_quarterly',
      name: 'Cinema Ultra Pass',
      price: 6500,
      currency: 'NGN',
      period: '3 Months',
      features: [
        'Everything in VIP Pass',
        '4 Concurrent Screens / Family Sharing',
        'Priority Low-Latency IPTV Transcoding',
        'Early Access to Curated Film Premieres',
      ],
      badge: 'BEST VALUE',
    ),
    SubscriptionPlan(
      id: 'founder_lifetime',
      name: 'Founder Lifetime Pass',
      price: 25000,
      currency: 'NGN',
      period: 'Lifetime',
      features: [
        'Lifetime Access to All Features',
        'VIP Gold Founder Badge on Profile',
        'Direct Studio Master Streaming',
        'Exclusive Discord & Early Feature Access',
      ],
      badge: 'FOUNDER',
    ),
  ];

  /// Fetch plans from backend or fallback to defaults
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/plans')).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['plans'] as List<dynamic>? ?? [];
        return list.map((p) => SubscriptionPlan.fromJson(p)).toList();
      }
    } catch (_) {}
    return defaultPlans;
  }

  /// Initialize Paystack transaction (or mock session)
  static Future<Map<String, dynamic>> initializePayment({
    required String email,
    required int amountInNaira,
    String planId = 'vip_monthly',
    bool useMock = true,
  }) async {
    final amountInKobo = amountInNaira * 100;
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'amount': amountInKobo,
          'plan': planId,
          'currency': 'NGN',
          'mock': useMock,
        }),
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Instant local client mock fallback
    final mockRef = 'pstk_mock_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'status': true,
      'message': 'Simulated Mock Authorization',
      'data': {
        'authorization_url': 'https://purecinema.app/checkout/mock/$mockRef',
        'reference': mockRef,
        'mock': true,
      }
    };
  }

  /// Verify Paystack transaction reference
  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/verify/$reference'),
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Simulated verified receipt
    return {
      'status': true,
      'message': 'Payment Verified (Simulated)',
      'data': {
        'reference': reference,
        'status': 'success',
        'gateway_response': 'Approved',
        'channel': 'card',
        'mock': true,
      }
    };
  }
}
