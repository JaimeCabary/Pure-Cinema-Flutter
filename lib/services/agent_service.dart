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

  // ADK Model Swarm Priority
  static const List<String> _geminiModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite-preview-06-17',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
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

    // 1. Navigation Intents
    if (lowerMessage.contains('watchlist') || lowerMessage == 'my list' || lowerMessage.contains('saved movies')) {
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
        'reply': '📺 Switching over to **Live TV Channels** with 10,000+ global broadcasts and sports streams!',
        'actions': [
          {'type': 'NAVIGATE_TAB', 'payload': {'index': 1}}
        ],
        'suggestedPrompts': ['Find sports channels', 'Find news channels', 'Go to Home']
      };
    }

    // 2. Try FastAPI Backend (ADK Cognitive Swarm)
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
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // 3. Direct Client-Side Gemini Rotator Swarm (If client key provided)
    if (_fallbackGeminiKey.isNotEmpty) {
      for (final model in _geminiModels) {
        try {
          final contents = [];
          for (final h in history.take(6)) {
            contents.add({
              'role': h.role == 'user' ? 'user' : 'model',
              'parts': [{'text': h.content}]
            });
          }
          contents.add({
            'role': 'user',
            'parts': [{
              'text': 'You are Pure Cinema CineBot, an autonomous, film-savvy, and deeply conversational AI agent. Talk warmly, conversationally, and insightfully like a knowledgeable film buff friend without dry robotic boilerplate.\n\nUser: $cleanMessage'
            }]
          });

          final geminiUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_fallbackGeminiKey');
          final geminiRes = await http.post(
            geminiUri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': contents,
              'generationConfig': {'temperature': 0.85, 'maxOutputTokens': 800}
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
    }

    // 4. Conversational Identity & Banter Responses (Never blind-search TMDB for conversation)
    if (lowerMessage.contains('who am i') || lowerMessage.contains('who i am')) {
      return {
        'success': true,
        'reply': '🎬 You\'re the master curator of Pure Cinema! Whether you\'re in the mood for mind-bending sci-fi, heart-racing thrillers, or relaxing late-night TV, I\'m here to serve your cinematic taste.',
        'actions': [],
        'suggestedPrompts': ['Recommend a sci-fi movie', 'Open my Watchlist', 'Explore Live TV']
      };
    }

    if (lowerMessage.contains('who are you') || lowerMessage.contains('what are you') || lowerMessage.contains('what is this app')) {
      return {
        'success': true,
        'reply': '👋 I\'m **AI CineBot**, your personal film concierge and cinematic companion inside Pure Cinema. Ask me for movie recommendations, trivia, plot explanations, or help exploring live channels!',
        'actions': [],
        'suggestedPrompts': ['Recommend top sci-fi', 'Show action blockbusters', 'Open Watchlist']
      };
    }

    if (lowerMessage == 'hi' || lowerMessage == 'hello' || lowerMessage == 'hey') {
      return {
        'success': true,
        'reply': '🍿 Hey! Great to see you. What kind of movie vibe are you in the mood for today?',
        'actions': [],
        'suggestedPrompts': ['Something like Interstellar', 'Cozy comedy movie', 'Top rated thrillers']
      };
    }

    // 5. Explicit Movie Search Fallback (Only when user explicitly searches)
    final isSearch = ['search', 'find', 'recommend', 'show me', 'movies like', 'suggest'].any((w) => lowerMessage.contains(w));
    if (isSearch) {
      try {
        final searchResults = await TMDBService.searchMovies(cleanMessage);
        if (searchResults.isNotEmpty) {
          final top = searchResults.first;
          final listStr = searchResults.take(3).map((m) => '• **${m.title}** (${m.releaseYear}) — ⭐ ${m.voteAverage}/10\n  _${m.overview}_').join('\n\n');
          return {
            'success': true,
            'reply': '🎬 Here are curated cinema matches for **"$cleanMessage"**:\n\n$listStr',
            'actions': [
              {'type': 'OPEN_MOVIE', 'payload': {'movieId': top.id, 'title': top.title}}
            ],
            'suggestedPrompts': ['Explore more', 'Open Watchlist', 'Go to Live TV']
          };
        }
      } catch (_) {}
    }

    return {
      'success': true,
      'reply': '🎬 I\'m your Pure Cinema companion. Ask me for movie recommendations, tell me what mood you\'re in, or explore live channels!',
      'actions': [],
      'suggestedPrompts': ['Recommend mind-bending sci-fi', 'Show action blockbusters', 'Open Watchlist']
    };
  }
}
