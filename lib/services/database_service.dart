import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

/// Zero-Latency Reactive In-Memory Watchlist & Storage Service
class DatabaseService {
  static const String _watchlistKey = 'pure_cinema_watchlist';
  static const String _historyKey = 'pure_cinema_history';

  static List<Movie> _cachedWatchlist = [];
  static final Set<int> _cachedWatchlistIds = {};
  static bool _isInitialized = false;

  /// Real-time reactive stream of saved movies
  static final ValueNotifier<List<Movie>> watchlistStream =
      ValueNotifier<List<Movie>>([]);

  /// Legacy notifier for backward compatibility
  static ValueNotifier<int> get watchlistNotifier => _legacyNotifier;
  static final ValueNotifier<int> _legacyNotifier = ValueNotifier<int>(0);

  /// Synchronous fast-read for instant UI checks (0ms latency)
  static bool isMovieInWatchlist(int movieId) {
    return _cachedWatchlistIds.contains(movieId);
  }

  /// Initialize and preload cache on app start
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_watchlistKey) ?? [];
      _cachedWatchlist = raw
          .map((item) {
            try {
              return Movie.fromJson(json.decode(item));
            } catch (_) {
              return null;
            }
          })
          .whereType<Movie>()
          .toList();
      _cachedWatchlistIds.clear();
      _cachedWatchlistIds.addAll(_cachedWatchlist.map((m) => m.id));
      _isInitialized = true;
      _dispatch();
    } catch (_) {}
  }

  static void _dispatch() {
    watchlistStream.value = List<Movie>.unmodifiable(_cachedWatchlist);
    _legacyNotifier.value++;
  }

  // ── Watchlist Operations ──
  static Future<List<Movie>> getWatchlist() async {
    if (!_isInitialized) {
      await init();
    }
    return List<Movie>.from(_cachedWatchlist);
  }

  static Future<bool> isInWatchlist(int movieId) async {
    if (!_isInitialized) {
      await init();
    }
    return _cachedWatchlistIds.contains(movieId);
  }

  static Future<void> addToWatchlist(Movie movie) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_cachedWatchlistIds.contains(movie.id)) {
      _cachedWatchlistIds.add(movie.id);
      _cachedWatchlist.insert(0, movie); // Newest on top
      _dispatch(); // INSTANT REAL-TIME UPDATE (0ms)

      // Background persist to disk
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = _cachedWatchlist.map((m) => json.encode(m.toJson())).toList();
        await prefs.setStringList(_watchlistKey, raw);
      } catch (_) {}
    }
  }

  static Future<void> removeFromWatchlist(int movieId) async {
    if (!_isInitialized) {
      await init();
    }

    if (_cachedWatchlistIds.contains(movieId)) {
      _cachedWatchlistIds.remove(movieId);
      _cachedWatchlist.removeWhere((m) => m.id == movieId);
      _dispatch(); // INSTANT REAL-TIME UPDATE (0ms)

      // Background persist to disk
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = _cachedWatchlist.map((m) => json.encode(m.toJson())).toList();
        await prefs.setStringList(_watchlistKey, raw);
      } catch (_) {}
    }
  }

  static Future<bool> toggleWatchlist(Movie movie) async {
    if (!_isInitialized) {
      await init();
    }

    if (_cachedWatchlistIds.contains(movie.id)) {
      await removeFromWatchlist(movie.id);
      return false;
    } else {
      await addToWatchlist(movie);
      return true;
    }
  }

  // ── Playback History ──
  static Future<void> saveWatchProgress(int movieId, int positionSeconds, int durationSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_historyKey}_$movieId';
    await prefs.setString(key, json.encode({
      'movieId': movieId,
      'position': positionSeconds,
      'duration': durationSeconds,
      'updatedAt': DateTime.now().toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> getWatchProgress(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_historyKey}_$movieId';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }
}
