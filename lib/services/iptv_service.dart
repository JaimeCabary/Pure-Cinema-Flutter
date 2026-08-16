import '../models/live_channel.dart';

class IPTVService {
  static final List<String> categories = [
    'All Channels',
    'Movies & Cinema',
    'News & Tech',
    'Sports & Action',
    'Documentary & World',
    'Entertainment',
    'Music & Vibes',
  ];

  static final List<LiveChannel> channels = [
    // ── Movies & Cinema ──
    LiveChannel(
      id: 'pure-cinema-4k',
      name: 'Pure Cinema TV 4K',
      logo: 'https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=100&h=100&fit=crop&q=80',
      group: 'Movies & Cinema',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Cinema Showcase 4K: Interstellar Horizons',
      badge: '4K LIVE',
    ),
    LiveChannel(
      id: '00s-replay',
      name: '00s Replay Cinema',
      logo: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100&h=100&fit=crop&q=80',
      group: 'Movies & Cinema',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: '2000s Iconic Hollywood Blockbusters',
      badge: 'HD',
    ),
    LiveChannel(
      id: 'filmrise-movies',
      name: 'FilmRise Free Movies',
      logo: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=100&h=100&fit=crop&q=80',
      group: 'Movies & Cinema',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Action & Thriller Double Feature',
      badge: 'MOVIE',
    ),
    LiveChannel(
      id: 'scifi-central',
      name: 'Sci-Fi Central TV',
      logo: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=100&h=100&fit=crop&q=80',
      group: 'Movies & Cinema',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Cyberpunk Odyssey: Beyond The Grid',
      badge: 'SCI-FI',
    ),

    // ── News & Tech ──
    LiveChannel(
      id: 'bloomberg-tv',
      name: 'Bloomberg TV News',
      logo: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=100&h=100&fit=crop&q=80',
      group: 'News & Tech',
      streamUrl: 'https://live-bloomberg-us.akamaized.net/hls/live/2042784/bloomberg_us/master.m3u8',
      currentProgram: 'Global Markets & Technology Live',
      badge: 'LIVE NEWS',
    ),
    LiveChannel(
      id: 'france-24',
      name: 'France 24 English',
      logo: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=100&h=100&fit=crop&q=80',
      group: 'News & Tech',
      streamUrl: 'https://f24hls-i.akamaihd.net/hls/live/221193/F24_EN_LO_HLS/master_500.m3u8',
      currentProgram: 'International Prime Broadcast',
      badge: 'LIVE',
    ),
    LiveChannel(
      id: 'aljazeera-en',
      name: 'Al Jazeera English',
      logo: 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=100&h=100&fit=crop&q=80',
      group: 'News & Tech',
      streamUrl: 'https://live-hls-web-aje.getaj.net/AJE/03.m3u8',
      currentProgram: 'Inside Story & World Affairs',
      badge: 'HD',
    ),
    LiveChannel(
      id: 'dw-english',
      name: 'DW English Live',
      logo: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=100&h=100&fit=crop&q=80',
      group: 'News & Tech',
      streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
      currentProgram: 'Global 3000 & Future Tech',
      badge: 'HD',
    ),

    // ── Sports & Action ──
    LiveChannel(
      id: 'redbull-tv',
      name: 'Red Bull TV HD',
      logo: 'https://images.unsplash.com/photo-1533107862482-0e6974b06ec4?w=100&h=100&fit=crop&q=80',
      group: 'Sports & Action',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      currentProgram: 'Uncharted Worlds: Global Extreme Series',
      badge: 'FEATURED',
    ),
    LiveChannel(
      id: 'world-poker',
      name: 'World Poker Tour TV',
      logo: 'https://images.unsplash.com/photo-1511193311914-0346f16efe90?w=100&h=100&fit=crop&q=80',
      group: 'Sports & Action',
      streamUrl: 'https://wpt-live.akamaized.net/hls/live/1014869/wpt/master.m3u8',
      currentProgram: 'WPT Championship High Rollers Live',
      badge: 'LIVE',
    ),

    // ── Documentary & World ──
    LiveChannel(
      id: 'nasa-tv',
      name: 'NASA TV Space Cast',
      logo: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=100&h=100&fit=crop&q=80',
      group: 'Documentary & World',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      currentProgram: 'Deep Space Observations: Artemis & Webb',
      badge: 'SPACE LIVE',
    ),
    LiveChannel(
      id: 'wildearth-live',
      name: 'WildEarth Live Safari',
      logo: 'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?w=100&h=100&fit=crop&q=80',
      group: 'Documentary & World',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      currentProgram: 'Serengeti Dusk: Live Wildlife Patrol',
      badge: 'SAFARI',
    ),

    // ── Entertainment ──
    LiveChannel(
      id: '1plus1-intl',
      name: '1+1 International HD',
      logo: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=100&h=100&fit=crop&q=80',
      group: 'Entertainment',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: 'Global Entertainment Tonight',
      badge: '1080p',
    ),
    LiveChannel(
      id: 'fashion-tv',
      name: 'Fashion TV Paris 4K',
      logo: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=100&h=100&fit=crop&q=80',
      group: 'Entertainment',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: 'Haute Couture Runway Week',
      badge: '4K',
    ),

    // ── Music & Vibes ──
    LiveChannel(
      id: 'lofi-tv',
      name: 'Pure Cinema Chillout Lounge',
      logo: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&h=100&fit=crop&q=80',
      group: 'Music & Vibes',
      streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      currentProgram: 'Midnight Noir & Ambient Visuals',
      badge: '24/7 MUSIC',
    ),
  ];

  static List<LiveChannel> getChannelsByCategory(String category) {
    if (category == 'All Channels') return channels;
    return channels.where((c) => c.group == category).toList();
  }

  static List<LiveChannel> searchChannels(String query, String category) {
    final list = getChannelsByCategory(category);
    if (query.trim().isEmpty) return list;
    return list.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
