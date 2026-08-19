import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'tmdb_service.dart';

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
  static const String _fallbackGeminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Gemini model priority matching the new standout models
  static const List<String> _geminiModels = [
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
  ];

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
    final cleanMessage = message.trim();
    final lowerMessage = cleanMessage.toLowerCase();

    // 1. Direct In-App Navigation Shortcuts
    if (lowerMessage.contains('watchlist') || lowerMessage == 'my list') {
      return {
        'success': true,
        'reply': '🎬 Taking you straight to your **Watchlist**! Here you can find all your saved cinema titles.',
        'actions': [
          {'type': 'NAVIGATE_TAB', 'payload': {'index': 3}}
        ],
        'suggestedPrompts': ['What should I watch next?', 'Search sci-fi movies', 'Go back to Home']
      };
    }

    if (lowerMessage.contains('live tv') || lowerMessage.contains('iptv') || lowerMessage.contains('channels')) {
      return {
        'success': true,
        'reply': '📺 Switching over to **Live TV Channels** with 10,000+ global broadcasts!',
        'actions': [
          {'type': 'NAVIGATE_TAB', 'payload': {'index': 1}}
        ],
        'suggestedPrompts': ['Find sports channels', 'Find news channels', 'Go to Home']
      };
    }

    // 2. Try FastAPI Backend (Fast Swarm)
    try {
      final payload = {
        'message': cleanMessage,
        'history': history.map((h) => {'role': h.role, 'content': h.content}).toList(),
        'currentScreen': currentScreen ?? 'Home',
        'currentMovieId': currentMovieId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/agent/chat'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // 3. Direct Client-Side Gemini Rotator Swarm
    for (final model in _geminiModels) {
      try {
        final contents = [];
        for (final h in history.take(4)) {
          contents.add({
            'role': h.role == 'user' ? 'user' : 'model',
            'parts': [{'text': h.content}]
          });
        }
        contents.add({
          'role': 'user',
          'parts': [{'text': 'You are Pure Cinema CineBot, an expert movie concierge. Give a concise, friendly recommendation or answer in clean markdown without robotic boilerplate.\n\nUser: $cleanMessage'}]
        });

        final geminiUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_fallbackGeminiKey');
        final geminiRes = await http.post(
          geminiUri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': contents,
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500}
          }),
        ).timeout(const Duration(seconds: 4));

        if (geminiRes.statusCode == 200) {
          final data = json.decode(geminiRes.body);
          final candidates = data['candidates'] as List<dynamic>? ?? [];
          if (candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List<dynamic>? ?? [];
            final reply = parts.map((p) => p['text'] ?? '').join('');
            if (reply.isNotEmpty) {
              return {
                'success': true,
                'reply': reply,
                'actions': [],
                'suggestedPrompts': ['Recommend sci-fi movies', 'Open Watchlist', 'Live TV']
              };
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    // 4. TMDB Search Fallback
    try {
      final searchResults = await TMDBService.searchMovies(cleanMessage);
      if (searchResults.isNotEmpty) {
        final top = searchResults.first;
        final listStr = searchResults.take(3).map((m) => '• **${m.title}** (${m.releaseYear}) — ⭐ ${m.voteAverage}/10\n  _${m.overview}_').join('\n\n');
        return {
          'success': true,
          'reply': '🎬 Here are top cinema matches for **"$cleanMessage"**:\n\n$listStr',
          'actions': [
            {'type': 'OPEN_MOVIE', 'payload': {'movieId': top.id, 'title': top.title}}
          ],
          'suggestedPrompts': ['Explore more', 'Open Watchlist', 'Go to Live TV']
        };
      }
    } catch (_) {}

    return {
      'success': true,
      'reply': '🎬 I can help you find blockbusters, search directors, and explore live channels. What genre or movie mood are you looking for today?',
      'actions': [],
      'suggestedPrompts': ['Recommend top sci-fi', 'Show action movies', 'Open Watchlist']
    };
  }
}
