import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

/// Local Repository & Storage Manager mirroring Prisma Models
/// (User, MovieWatchlist, PlaybackHistory, CustomPlaylist)
class DatabaseService {
  static const String _watchlistKey = 'pure_cinema_watchlist';
  static const String _historyKey = 'pure_cinema_history';

  /// Reactive Notifier so all screens instantly update when watchlist changes
  static final ValueNotifier<int> watchlistNotifier = ValueNotifier<int>(0);

  // ── Watchlist Operations (mirrors Prisma MovieWatchlist) ──
  static Future<List<Movie>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_watchlistKey) ?? [];
    return raw.map((item) => Movie.fromJson(json.decode(item))).toList();
  }

  static Future<bool> isInWatchlist(int movieId) async {
    final list = await getWatchlist();
    return list.any((m) => m.id == movieId);
  }

  static Future<void> addToWatchlist(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWatchlist();
    if (!list.any((m) => m.id == movie.id)) {
      list.add(movie);
      final raw = list.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_watchlistKey, raw);
      watchlistNotifier.value++;
    }
  }

  static Future<void> removeFromWatchlist(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWatchlist();
    list.removeWhere((m) => m.id == movieId);
    final raw = list.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList(_watchlistKey, raw);
    watchlistNotifier.value++;
  }

  static Future<bool> toggleWatchlist(Movie movie) async {
    final inList = await isInWatchlist(movie.id);
    if (inList) {
      await removeFromWatchlist(movie.id);
      return false;
    } else {
      await addToWatchlist(movie);
      return true;
    }
  }

  // ── Playback History (mirrors Prisma PlaybackHistory) ──
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
