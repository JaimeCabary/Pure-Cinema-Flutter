import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AgentChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final List<dynamic> actions;

  AgentChatMessage({
    required this.role,
    required this.content,
    this.actions = const [],
  });
}

class AgentService {
  static const String _productionUrl = 'https://pure-cinema-backend.onrender.com';

  static String get baseUrl {
    if (kIsWeb) {
      if (Uri.base.host.isNotEmpty && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
        if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(Uri.base.host)) {
          return 'http://${Uri.base.host}:3000';
        }
      }
      return _productionUrl;
    }
    return _productionUrl;
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    List<AgentChatMessage> history = const [],
    String? currentScreen,
    int? currentMovieId,
  }) async {
    final payload = {
      'message': message,
      'history': history.map((h) => {'role': h.role, 'content': h.content}).toList(),
      'currentScreen': currentScreen ?? 'Home',
      'currentMovieId': currentMovieId,
    };

    final bodyStr = json.encode(payload);
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http
          .post(Uri.parse('$baseUrl/api/agent/chat'), headers: headers, body: bodyStr)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'reply': '⚠️ Backend returned status ${response.statusCode}. Please verify your Gemini API key in Render.',
          'actions': [],
          'suggestedPrompts': ['Recommend sci-fi movies', 'Go to Watchlist', 'Live TV']
        };
      }
    } catch (e) {
      debugPrint('Agent chat network error: $e');
      return {
        'success': false,
        'reply': '⚠️ Could not connect to AI backend. Make sure https://pure-cinema-backend.onrender.com is online.',
        'actions': [],
        'suggestedPrompts': ['Recommend movies', 'Open Watchlist', 'Live TV']
      };
    }
  }
}
