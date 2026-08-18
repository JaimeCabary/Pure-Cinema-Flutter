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
  static const List<String> _candidateUrls = [
    'https://pure-cinema-backend.onrender.com',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
  ];

  static String _activeBaseUrl = 'https://pure-cinema-backend.onrender.com';

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
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Try fallback ports
      for (final candidate in _candidateUrls) {
        if (candidate == _activeBaseUrl) continue;
        try {
          final response = await http
              .post(Uri.parse('$candidate/api/agent/chat'), headers: headers, body: bodyStr)
              .timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            _activeBaseUrl = candidate;
            return json.decode(response.body) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
    }

    // Local client-side fallback if backend is starting or offline
    return _buildLocalFallbackResponse(message);
  }

  static Map<String, dynamic> _buildLocalFallbackResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('watchlist') || lower.contains('saved')) {
      return {
        'success': true,
        'reply': 'Taking you to your saved Watchlist!',
        'actions': [
          {'type': 'NAVIGATE_TAB', 'payload': {'index': 2}}
        ],
        'suggestedPrompts': ['Recommend Sci-Fi movies', 'Who is Nolan?', 'Back to Home']
      };
    }

    if (lower.contains('live') || lower.contains('channel')) {
      return {
        'success': true,
        'reply': 'Opening Live TV channels for you!',
        'actions': [
          {'type': 'NAVIGATE_TAB', 'payload': {'index': 3}}
        ],
        'suggestedPrompts': ['Search news', 'Recommend movies', 'Go to Home']
      };
    }

    if (lower.contains('interstellar')) {
      return {
        'success': true,
        'reply': '🚀 **Interstellar (2014)**\nDirected by Christopher Nolan. A team of explorers travel through a wormhole in space to ensure humanity\'s survival.',
        'actions': [
          {
            'type': 'OPEN_MOVIE',
            'payload': {'movieId': 157336, 'title': 'Interstellar'}
          }
        ],
        'suggestedPrompts': ['Who is Christopher Nolan?', 'Inception', 'Watchlist']
      };
    }

    return {
      'success': true,
      'reply': '🍿 **Pure Cinema AI Assistant**\nI am ready to help you discover top movies, navigate channels, or check your watchlist!',
      'actions': [],
      'suggestedPrompts': [
        'Recommend sci-fi movies',
        'Go to Watchlist',
        'Top rated action movies',
        'Live TV'
      ]
    };
  }
}
