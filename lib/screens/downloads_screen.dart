import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/download_service.dart';
import '../models/movie.dart';
import '../theme/fonts.dart';
import 'watch_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUser();
    DownloadService.init();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
    });
  }

  void _playOfflineMovie(DownloadItem item) {
    final movie = Movie(
      id: item.movieId,
      title: item.title,
      posterPath: item.posterUrl,
      backdropPath: item.backdropUrl,
      overview: item.overview,
      releaseDate: '2026',
      voteAverage: 8.5,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatchScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111114),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222225)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white12,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: AppFonts.sCoreDream(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: AppFonts.sCoreDream(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Offline Theater Storage',
                            style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offline Downloads',
                    style: AppFonts.sCoreDream(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ValueListenableBuilder<List<DownloadItem>>(
                    valueListenable: DownloadService.downloadsNotifier,
                    builder: (context, downloads, _) {
                      if (downloads.isEmpty) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: () => DownloadService.clearAll(),
                        child: Text(
                          'CLEAR ALL',
                          style: AppFonts.sCoreDream(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Downloaded 4K titles stored locally on your device for instant offline playback.',
                style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Reactive Downloads List
              Expanded(
                child: ValueListenableBuilder<List<DownloadItem>>(
                  valueListenable: DownloadService.downloadsNotifier,
                  builder: (context, downloads, _) {
                    if (downloads.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_download_outlined, color: Colors.white24, size: 54),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Offline Downloads',
                              style: AppFonts.sCoreDream(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap the download button on any movie card or details modal to store titles offline.',
                              style: AppFonts.sCoreDream(color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: downloads.length,
                      itemBuilder: (context, index) {
                        final item = downloads[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111114),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF222225)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: item.posterUrl,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 50,
                                    height: 70,
                                    color: const Color(0xFF1F1F24),
                                    child: const Icon(Icons.movie, color: Colors.white24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppFonts.sCoreDream(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.fileSize} • 4K ULTRA HD',
                                          style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 11),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'DOWNLOADED',
                                            style: AppFonts.sCoreDream(
                                              color: const Color(0xFF10B981),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
                                onPressed: () => _playOfflineMovie(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                                onPressed: () => DownloadService.deleteDownload(item.movieId),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
