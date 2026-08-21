import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class DownloadItem {
  final int movieId;
  final String title;
  final String posterUrl;
  final String backdropUrl;
  
  final String overview;
  final String videoUrl;
  final String fileSize;
  final String downloadedAt;
  final double progress; // 1.0 when finished

  DownloadItem({
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.backdropUrl,
    required this.overview,
    required this.videoUrl,
    required this.fileSize,
    required this.downloadedAt,
    this.progress = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'title': title,
    'posterUrl': posterUrl,
    'backdropUrl': backdropUrl,
    'overview': overview,
    'videoUrl': videoUrl,
    'fileSize': fileSize,
    'downloadedAt': downloadedAt,
    'progress': progress,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    movieId: json['movieId'] as int? ?? 0,
    title: json['title'] as String? ?? 'Untitled',
    posterUrl: json['posterUrl'] as String? ?? '',
    backdropUrl: json['backdropUrl'] as String? ?? '',
    overview: json['overview'] as String? ?? '',
    videoUrl: json['videoUrl'] as String? ?? '',
    fileSize: json['fileSize'] as String? ?? '1.4 GB',
    downloadedAt: json['downloadedAt'] as String? ?? 'Just now',
    progress: (json['progress'] as num?)?.toDouble() ?? 1.0,
  );
}

class DownloadService {
  static const String _storageKey = 'pure_cinema_offline_downloads';
  static final ValueNotifier<List<DownloadItem>> downloadsNotifier = ValueNotifier([]);

  /// Initialize and load saved downloads
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (json.decode(raw) as List<dynamic>)
            .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
            .toList();
        downloadsNotifier.value = list;
      } catch (e) {
        debugPrint('Error parsing saved downloads: $e');
      }
    }
  }

  static bool isDownloaded(int movieId) {
    return downloadsNotifier.value.any((item) => item.movieId == movieId);
  }

  /// Trigger offline download stream
  static Future<void> downloadMovie(Movie movie, {Function(String msg)? onStatus}) async {
    if (isDownloaded(movie.id)) {
      onStatus?.call('${movie.title} is already saved for offline viewing.');
      return;
    }

    onStatus?.call('Starting offline 4K stream cache for ${movie.title}...');

    // Simulate chunk stream caching
    final newItem = DownloadItem(
      movieId: movie.id,
      title: movie.title,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      overview: movie.overview,
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      fileSize: '1.6 GB',
      downloadedAt: 'Today',
      progress: 1.0,
    );

    final current = List<DownloadItem>.from(downloadsNotifier.value);
    current.insert(0, newItem);
    downloadsNotifier.value = current;

    await _saveToStorage();
    onStatus?.call('Successfully downloaded ${movie.title} for offline viewing!');
  }

  static Future<void> deleteDownload(int movieId) async {
    final current = List<DownloadItem>.from(downloadsNotifier.value);
    current.removeWhere((item) => item.movieId == movieId);
    downloadsNotifier.value = current;
    await _saveToStorage();
  }

  static Future<void> clearAll() async {
    downloadsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(downloadsNotifier.value.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
