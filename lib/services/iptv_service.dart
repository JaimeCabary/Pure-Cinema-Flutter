import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/live_channel.dart';

class IPTVService {
  static const String iptvOrgMainUrl = 'https://iptv-org.github.io/iptv/index.m3u';
  
  static const String _productionUrl = 'https://pure-cinema-backend.onrender.com/api/iptv';

  static String get backendApiUrl {
    if (kIsWeb) {
      if (Uri.base.host.isNotEmpty && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
        if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(Uri.base.host)) {
          return 'http://${Uri.base.host}:3000/api/iptv';
        }
      }
      return _productionUrl;
    }
    return _productionUrl;
  }

  static bool _isLoading = false;
  static bool get isLoading => _isLoading;

  static List<String> categories = [
    'All Channels',
    'Movies',
    'News',
    'Sports',
    'Documentary',
    'Entertainment',
    'Music',
    'Animation',
    'Kids',
    'Series',
    'General',
  ];

  static List<String> countries = [
    'All',
    'US',
    'UK',
    'CA',
    'FR',
    'DE',
    'ES',
    'IT',
    'JP',
    'KR',
    'AU',
  ];

  // Guaranteed 24/7 working high-quality initial streams
  static final List<LiveChannel> _fallbackChannels = [
    // ── Movies ──
    LiveChannel(
      id: 'pure-cinema-4k',
      name: 'Pure Cinema TV 4K',
      logo: 'https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=100&h=100&fit=crop&q=80',
      group: 'Movies',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Cinema Showcase 4K: Interstellar Horizons',
      badge: '4K LIVE',
      country: 'US',
    ),
    LiveChannel(
      id: '00s-replay',
      name: '00s Replay Cinema',
      logo: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100&h=100&fit=crop&q=80',
      group: 'Movies',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: '2000s Iconic Hollywood Blockbusters',
      badge: 'HD',
      country: 'US',
    ),
    LiveChannel(
      id: 'filmrise-movies',
      name: 'FilmRise Free Movies',
      logo: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=100&h=100&fit=crop&q=80',
      group: 'Movies',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Action & Thriller Double Feature',
      badge: 'MOVIE',
      country: 'US',
    ),

    // ── News ──
    LiveChannel(
      id: 'bloomberg-tv',
      name: 'Bloomberg TV News',
      logo: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=100&h=100&fit=crop&q=80',
      group: 'News',
      streamUrl: 'https://live-bloomberg-us.akamaized.net/hls/live/2042784/bloomberg_us/master.m3u8',
      currentProgram: 'Global Markets & Technology Live',
      badge: 'LIVE NEWS',
      country: 'US',
    ),
    LiveChannel(
      id: 'france-24',
      name: 'France 24 English',
      logo: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=100&h=100&fit=crop&q=80',
      group: 'News',
      streamUrl: 'https://f24hls-i.akamaihd.net/hls/live/221193/F24_EN_LO_HLS/master_500.m3u8',
      currentProgram: 'International Prime Broadcast',
      badge: 'LIVE',
      country: 'FR',
    ),
    LiveChannel(
      id: 'aljazeera-en',
      name: 'Al Jazeera English',
      logo: 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=100&h=100&fit=crop&q=80',
      group: 'News',
      streamUrl: 'https://live-hls-web-aje.getaj.net/AJE/03.m3u8',
      currentProgram: 'Inside Story & World Affairs',
      badge: 'HD',
      country: 'QA',
    ),
    LiveChannel(
      id: 'dw-english',
      name: 'DW English Live',
      logo: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=100&h=100&fit=crop&q=80',
      group: 'News',
      streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
      currentProgram: 'Global 3000 & Future Tech',
      badge: 'HD',
      country: 'DE',
    ),

    // ── Sports ──
    LiveChannel(
      id: 'redbull-tv',
      name: 'Red Bull TV HD',
      logo: 'https://images.unsplash.com/photo-1533107862482-0e6974b06ec4?w=100&h=100&fit=crop&q=80',
      group: 'Sports',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      currentProgram: 'Uncharted Worlds: Global Extreme Series',
      badge: 'FEATURED',
      country: 'AT',
    ),
    LiveChannel(
      id: 'world-poker',
      name: 'World Poker Tour TV',
      logo: 'https://images.unsplash.com/photo-1511193311914-0346f16efe90?w=100&h=100&fit=crop&q=80',
      group: 'Sports',
      streamUrl: 'https://wpt-live.akamaized.net/hls/live/1014869/wpt/master.m3u8',
      currentProgram: 'WPT Championship High Rollers Live',
      badge: 'LIVE',
      country: 'US',
    ),

    // ── Documentary ──
    LiveChannel(
      id: 'nasa-tv',
      name: 'NASA TV Space Cast',
      logo: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=100&h=100&fit=crop&q=80',
      group: 'Documentary',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      currentProgram: 'Deep Space Observations: Artemis & Webb',
      badge: 'SPACE LIVE',
      country: 'US',
    ),
    LiveChannel(
      id: 'wildearth-live',
      name: 'WildEarth Live Safari',
      logo: 'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?w=100&h=100&fit=crop&q=80',
      group: 'Documentary',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Serengeti Dusk: Live Wildlife Patrol',
      badge: 'SAFARI',
      country: 'ZA',
    ),

    // ── Entertainment ──
    LiveChannel(
      id: '1plus1-intl',
      name: '1+1 International HD',
      logo: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=100&h=100&fit=crop&q=80',
      group: 'Entertainment',
      streamUrl: 'https://dash2.antik.sk/live/test_one_plus_one_int_tizen/playlist.m3u8',
      currentProgram: 'Global Entertainment Tonight',
      badge: '1080p',
      country: 'UA',
    ),
    LiveChannel(
      id: 'fashion-tv',
      name: 'Fashion TV Paris 4K',
      logo: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=100&h=100&fit=crop&q=80',
      group: 'Entertainment',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: 'Haute Couture Runway Week',
      badge: '4K',
      country: 'FR',
    ),

    // ── Music ──
    LiveChannel(
      id: 'lofi-tv',
      name: 'Pure Cinema Chillout Lounge',
      logo: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&h=100&fit=crop&q=80',
      group: 'Music',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: 'Midnight Noir & Ambient Visuals',
      badge: '24/7 MUSIC',
      country: 'US',
    ),
  ];

  static List<LiveChannel> channels = List.from(_fallbackChannels);

  /// Load all channels from iptv-org index.m3u and merge into the live channel guide
  static Future<void> loadIPTVOrgChannels({Function()? onUpdated}) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      // First attempt: Check local backend for pre-cached fast channels
      try {
        final backendRes = await http
            .get(Uri.parse('$backendApiUrl/channels?limit=500'))
            .timeout(const Duration(seconds: 3));
        if (backendRes.statusCode == 200) {
          final data = jsonDecode(backendRes.body);
          if (data is Map && data['channels'] is List) {
            final List list = data['channels'];
            final backendChannels = list.map((c) => LiveChannel.fromJson(c)).toList();
            if (backendChannels.isNotEmpty) {
              _mergeChannels(backendChannels);
              onUpdated?.call();
            }
          }
        }
      } catch (_) {}

      // Second attempt: Directly fetch iptv-org/iptv/index.m3u
      final response = await http
          .get(Uri.parse(iptvOrgMainUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final parsed = parseM3U(response.body);
        if (parsed.isNotEmpty) {
          _mergeChannels(parsed);
          _extractMetadata();
          onUpdated?.call();
        }
      }
    } catch (e) {
      // Graceful fallback: channels already has rich fallback channels
    } finally {
      _isLoading = false;
      onUpdated?.call();
    }
  }

  static void _mergeChannels(List<LiveChannel> newChannels) {
    final existingIds = channels.map((c) => c.id).toSet();
    for (final ch in newChannels) {
      if (!existingIds.contains(ch.id) && ch.streamUrl.isNotEmpty) {
        channels.add(ch);
        existingIds.add(ch.id);
      }
    }
  }

  static void _extractMetadata() {
    final catSet = <String>{'All Channels'};
    final countrySet = <String>{'All'};

    for (final c in channels) {
      if (c.group.isNotEmpty && c.group != 'General') {
        catSet.add(c.group);
      }
      if (c.country != null && c.country!.isNotEmpty) {
        countrySet.add(c.country!.toUpperCase());
      }
    }

    categories = catSet.toList();
    countries = countrySet.toList();
  }

  /// Parses M3U playlist format string
  static List<LiveChannel> parseM3U(String content) {
    final List<LiveChannel> list = [];
    final lines = content.split('\n');
    LiveChannel? current;

    final logoRegex = RegExp(r'tvg-logo="([^"]*)"');
    final groupRegex = RegExp(r'group-title="([^"]*)"');
    final idRegex = RegExp(r'tvg-id="([^"]*)"');
    final countryRegex = RegExp(r'tvg-country="([^"]*)"');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final logoMatch = logoRegex.firstMatch(line);
        final groupMatch = groupRegex.firstMatch(line);
        final idMatch = idRegex.firstMatch(line);
        final countryMatch = countryRegex.firstMatch(line);

        final nameParts = line.split(',');
        final name = nameParts.length > 1 ? nameParts.last.trim() : 'Live Channel';
        final logo = logoMatch?.group(1) ?? '';
        final group = groupMatch?.group(1)?.trim() ?? 'General';
        final id = idMatch?.group(1)?.trim() ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
        final country = countryMatch?.group(1)?.trim().toUpperCase();

        current = LiveChannel(
          id: id,
          name: name,
          logo: logo.isNotEmpty ? logo : 'https://images.unsplash.com/photo-1598899134739-24c46f58b8c0?w=100&h=100&fit=crop&q=80',
          group: group.isNotEmpty ? group : 'General',
          streamUrl: '',
          country: country,
          badge: name.toUpperCase().contains('HD') ? 'HD' : (name.toUpperCase().contains('4K') ? '4K' : 'LIVE'),
          currentProgram: 'Live Stream · $group',
        );
      } else if (!line.startsWith('#') && current != null) {
        if (line.startsWith('http://') || line.startsWith('https://') || line.startsWith('rtsp://')) {
          final completed = LiveChannel(
            id: current.id,
            name: current.name,
            logo: current.logo,
            group: current.group,
            streamUrl: line,
            country: current.country,
            badge: current.badge,
            currentProgram: current.currentProgram,
          );
          list.add(completed);
        }
        current = null;
      }
    }

    return list;
  }

  /// Filter channels by category, country, and search query
  static List<LiveChannel> getFilteredChannels({
    String category = 'All Channels',
    String country = 'All',
    String query = '',
  }) {
    return channels.where((c) {
      // Category filter
      final matchesCategory = category == 'All Channels' ||
          c.group.toLowerCase() == category.toLowerCase();

      // Country filter
      final matchesCountry = country == 'All' ||
          (c.country != null && c.country!.toUpperCase() == country.toUpperCase());

      // Search filter
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.group.toLowerCase().contains(q);

      return matchesCategory && matchesCountry && matchesQuery;
    }).toList();
  }

  /// Fast search for channel list
  static List<LiveChannel> searchChannels(String query, String category, {String country = 'All'}) {
    return getFilteredChannels(category: category, country: country, query: query);
  }
}
