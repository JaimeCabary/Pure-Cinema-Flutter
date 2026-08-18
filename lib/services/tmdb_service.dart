import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/cast_member.dart';

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _defaultApiKey = '119f057993052814896eff7bb55e03db';
  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: _defaultApiKey);
  static const String _backendUrl = 'https://pure-cinema-backend.onrender.com/api/movies';

  static final Map<String, dynamic> _cache = {};

  // ── DISTINCT CATEGORIZED MASTER DATASETS (Guarantees zero row repetition) ──

  static final List<Movie> bestPicksFallbacks = [
    Movie(
      id: 157336,
      title: 'Interstellar',
      overview: 'A team of explorers travel through a newly discovered wormhole in space to surpass the limitations on human space travel and ensure humanity\'s survival.',
      posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      backdropPath: '/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
      releaseDate: '2014-11-05',
      voteAverage: 8.4,
    ),
    Movie(
      id: 27205,
      title: 'Inception',
      overview: 'Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets, is offered a chance to regain his old life.',
      posterPath: '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
      backdropPath: '/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg',
      releaseDate: '2010-07-15',
      voteAverage: 8.4,
    ),
    Movie(
      id: 872585,
      title: 'Oppenheimer',
      overview: 'The story of J. Robert Oppenheimer’s role in the development of the atomic bomb during World War II.',
      posterPath: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      backdropPath: '/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
      releaseDate: '2023-07-19',
      voteAverage: 8.1,
    ),
    Movie(
      id: 335984,
      title: 'Blade Runner 2049',
      overview: 'Thirty years after the events of the first film, a new blade runner, LAPD Officer K, unearths a long-buried secret that has the potential to plunge what\'s left of society into chaos.',
      posterPath: '/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
      backdropPath: '/sAtoMqDVhNDQBc3QJL3RF6hlxGq.jpg',
      releaseDate: '2017-10-04',
      voteAverage: 8.0,
    ),
    Movie(
      id: 693134,
      title: 'Dune: Part Two',
      overview: 'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.',
      posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520QIq.jpg',
      releaseDate: '2024-02-27',
      voteAverage: 8.2,
    ),
  ];

  static final List<Movie> trendingFallbacks = [
    Movie(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary behind him. But when his homeworld faces an existential threat, Wade must reluctantly suit-up again.',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/yDHYTfA3R0jFYba16jBB1jv8uaC.jpg',
      releaseDate: '2024-07-24',
      voteAverage: 7.7,
    ),
    Movie(
      id: 945961,
      title: 'Alien: Romulus',
      overview: 'While scavenging the deep ends of a derelict space station, a group of young space colonizers come face to face with the most terrifying life form in the universe.',
      posterPath: '/b33nnKl1GSFbao8l3fZkyR4wsAc.jpg',
      backdropPath: '/9SSEUrSqhljBMzRe4aBTh17rUaC.jpg',
      releaseDate: '2024-08-13',
      voteAverage: 7.3,
    ),
    Movie(
      id: 1022789,
      title: 'Inside Out 2',
      overview: 'Teenager Riley\'s mind headquarters is undergoing a sudden demolition to make room for something entirely unexpected: new Emotions!',
      posterPath: '/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      backdropPath: '/stKGOm8wqGGOvRTjF8VnhGKTniE.jpg',
      releaseDate: '2024-06-11',
      voteAverage: 7.6,
    ),
    Movie(
      id: 786892,
      title: 'Furiosa: A Mad Max Saga',
      overview: 'As the world fell, young Furiosa is snatched from the Green Place of Many Mothers and falls into the hands of a great Biker Horde led by the Warlord Dementus.',
      posterPath: '/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
      backdropPath: '/wNAhuOZ3Zf86J7qqGQ5AurcwCS.jpg',
      releaseDate: '2024-05-22',
      voteAverage: 7.6,
    ),
    Movie(
      id: 558449,
      title: 'Gladiator II',
      overview: 'Years after witnessing the death of the revered hero Maximus at the hands of his uncle, Lucius must enter the Colosseum after his home is conquered.',
      posterPath: '/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      backdropPath: '/euYIwmwkmz95mnXvufEmbL6ovhA.jpg',
      releaseDate: '2024-11-13',
      voteAverage: 7.8,
    ),
  ];

  static final List<Movie> popularFallbacks = [
    Movie(
      id: 299534,
      title: 'Avengers: Endgame',
      overview: 'After the devastating events of Infinity War, the universe is in ruins. With the help of remaining allies, the Avengers assemble once more to reverse Thanos\' actions.',
      posterPath: '/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
      backdropPath: '/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
      releaseDate: '2019-04-24',
      voteAverage: 8.3,
    ),
    Movie(
      id: 603,
      title: 'The Matrix',
      overview: 'Set in the 22nd century, The Matrix tells the story of a computer hacker who joins a group of underground insurgents fighting the vast computers who rule the earth.',
      posterPath: '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
      backdropPath: '/easkWjhK5d7E871vE3q2J6oZf6U.jpg',
      releaseDate: '1999-03-30',
      voteAverage: 8.2,
    ),
    Movie(
      id: 155,
      title: 'The Dark Knight',
      overview: 'Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations.',
      posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      backdropPath: '/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg',
      releaseDate: '2008-07-16',
      voteAverage: 8.5,
    ),
    Movie(
      id: 603692,
      title: 'John Wick: Chapter 4',
      overview: 'With the price on his head ever increasing, John Wick uncovers a path to defeating The High Table. But before he can earn his freedom, Wick must face off against a new enemy.',
      posterPath: '/vZloFAK7NKnMGKEslbb5VSAvqSQ.jpg',
      backdropPath: '/7I6VUdPj6tQECNHdviJkUHD2389.jpg',
      releaseDate: '2023-03-22',
      voteAverage: 7.8,
    ),
    Movie(
      id: 361743,
      title: 'Top Gun: Maverick',
      overview: 'After more than thirty years of service as one of the Navy’s top aviators, Pete Mitchell is where he belongs, pushing the envelope as a courageous test pilot.',
      posterPath: '/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
      backdropPath: '/AaV1YIdWKnjAIAOe8UUKBFm327v.jpg',
      releaseDate: '2022-05-24',
      voteAverage: 8.2,
    ),
  ];

  static final List<Movie> topRatedFallbacks = [
    Movie(
      id: 278,
      title: 'The Shawshank Redemption',
      overview: 'Imprisoned in the 1940s for the double murder of his wife and her lover, upstanding banker Andy Dufresne begins a new life at the Shawshank prison.',
      posterPath: '/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg',
      backdropPath: '/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
      releaseDate: '1994-09-23',
      voteAverage: 8.7,
    ),
    Movie(
      id: 238,
      title: 'The Godfather',
      overview: 'Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family. When organized crime family patriarch, Vito Corleone barely survives an attempt on his life, his youngest son steps in.',
      posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
      backdropPath: '/tmU7whstejGRRa8ZGFFtV8Y5bbu.jpg',
      releaseDate: '1972-03-14',
      voteAverage: 8.7,
    ),
    Movie(
      id: 424,
      title: 'Schindler\'s List',
      overview: 'The true story of how businessman Oskar Schindler saved over a thousand Jewish lives from the Nazis while they worked as slaves in his factory during World War II.',
      posterPath: '/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg',
      backdropPath: '/zb6fM1CX41D9rF9hdgAv0W49XZY.jpg',
      releaseDate: '1993-12-15',
      voteAverage: 8.6,
    ),
    Movie(
      id: 680,
      title: 'Pulp Fiction',
      overview: 'A burger-loving hit man, his philosophical partner, a drug-addled gangster\'s moll and a washed-up boxer converge in this sprawling, comedic crime caper.',
      posterPath: '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
      backdropPath: '/suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg',
      releaseDate: '1994-09-10',
      voteAverage: 8.5,
    ),
    Movie(
      id: 550,
      title: 'Fight Club',
      overview: 'A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.',
      posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      backdropPath: '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
      releaseDate: '1999-10-15',
      voteAverage: 8.4,
    ),
  ];

  static final List<Movie> animationFallbacks = [
    Movie(
      id: 569094,
      title: 'Spider-Man: Across the Spider-Verse',
      overview: 'After reuniting with Gwen Stacy, Brooklyn’s full-time, friendly neighborhood Spider-Man is catapulted across the Multiverse, where he encounters the Spider Society.',
      posterPath: '/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
      backdropPath: '/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg',
      releaseDate: '2023-05-31',
      voteAverage: 8.4,
    ),
    Movie(
      id: 129,
      title: 'Spirited Away',
      overview: 'A young girl, Chihiro, becomes trapped in a strange new world of spirits. When her parents undergo a mysterious transformation, she must call upon the courage she never knew she had.',
      posterPath: '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
      backdropPath: '/bXNvzjYE21F9dF4bV2L4j75fBfL.jpg',
      releaseDate: '2001-07-20',
      voteAverage: 8.5,
    ),
    Movie(
      id: 372058,
      title: 'Your Name.',
      overview: 'High schoolers Mitsuha and Taki are complete strangers living separate lives. But one night, they suddenly switch places, embarking on a cosmic search for each other.',
      posterPath: '/q719qXXEzOoYaps6XZawPWhOi98.jpg',
      backdropPath: '/dIWwZWOPmtjjIPCWm29cbwgs92m.jpg',
      releaseDate: '2016-08-26',
      voteAverage: 8.5,
    ),
    Movie(
      id: 508442,
      title: 'Soul',
      overview: 'Joe Gardner is a middle school band teacher whose true passion is playing jazz. After a freak accident, his soul is separated from his body and transported to The Great Before.',
      posterPath: '/hm58Jw4Lw8OIYECIq5qyPYhAeRJ.jpg',
      backdropPath: '/kf456ZqeC45XTvo6W9pWJH1o2Y0.jpg',
      releaseDate: '2020-12-25',
      voteAverage: 8.1,
    ),
    Movie(
      id: 150540,
      title: 'Inside Out',
      overview: 'Growing up can be a bumpy road, and it\'s no exception for Riley, who is uprooted from her Midwest life when her father starts a new job in San Francisco.',
      posterPath: '/2H1TmgdfNtsKlU9qGeodAoxzz5f.jpg',
      backdropPath: '/j2AeqGj4U4Wwh8Nfc5XyA79L57y.jpg',
      releaseDate: '2015-06-09',
      voteAverage: 7.9,
    ),
  ];

  static List<Movie> get fallbackMovies => bestPicksFallbacks;

  // ── TMDB API WITH LIVE BACKEND & DIRECT TMDB FAILOVER ──

  static Future<List<Movie>> _fetchEndpoint(
    String endpoint, {
    Map<String, String>? params,
    required List<Movie> fallbackList,
  }) async {
    final key = '$endpoint:${params?.toString()}';
    if (_cache.containsKey(key)) {
      return (_cache[key] as List<Movie>);
    }

    // 1. Attempt direct TMDB v3 API call with active key
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: {
          'api_key': _apiKey.isNotEmpty ? _apiKey : _defaultApiKey,
          'include_adult': 'false',
          'language': 'en-US',
          ...?params,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List<dynamic>?)
                ?.map((item) => Movie.fromJson(item as Map<String, dynamic>))
                .where((m) => m.posterPath != null && m.posterPath!.isNotEmpty)
                .toList() ??
            [];
        if (results.isNotEmpty) {
          _cache[key] = results;
          return results;
        }
      }
    } catch (e) {
      debugPrint('Direct TMDB endpoint $endpoint failed: $e. Trying backend...');
    }

    // 2. Fallback to Render FastAPI Backend
    try {
      final backendPath = endpoint.replaceAll('/', '-').replaceFirst('-', '');
      final bUri = Uri.parse('$_backendUrl/$backendPath');
      final bRes = await http.get(bUri).timeout(const Duration(seconds: 4));
      if (bRes.statusCode == 200) {
        final data = json.decode(bRes.body) as List<dynamic>;
        final results = data.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
        if (results.isNotEmpty) {
          _cache[key] = results;
          return results;
        }
      }
    } catch (_) {}

    return fallbackList;
  }

  static Future<List<Movie>> fetchTrending() =>
      _fetchEndpoint('/trending/movie/week', fallbackList: trendingFallbacks);

  static Future<List<Movie>> fetchPopular() =>
      _fetchEndpoint('/movie/popular', fallbackList: popularFallbacks);

  static Future<List<Movie>> fetchNowPlaying() =>
      _fetchEndpoint('/movie/now_playing', fallbackList: bestPicksFallbacks);

  static Future<List<Movie>> fetchTopRated() =>
      _fetchEndpoint('/movie/top_rated', fallbackList: topRatedFallbacks);

  static Future<List<Movie>> fetchAnimation() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '16', 'sort_by': 'popularity.desc'}, fallbackList: animationFallbacks);

  static Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return fetchPopular();
    return _fetchEndpoint('/search/movie', params: {'query': query.trim()}, fallbackList: trendingFallbacks);
  }

  static Future<List<Movie>> fetchSimilar(int movieId) =>
      _fetchEndpoint('/movie/$movieId/similar', fallbackList: popularFallbacks);

  static Future<List<CastMember>> fetchCredits(int movieId) async {
    final key = 'credits:$movieId';
    if (_cache.containsKey(key)) {
      return (_cache[key] as List<CastMember>);
    }

    try {
      final uri = Uri.parse('$_baseUrl/movie/$movieId/credits').replace(
        queryParameters: {'api_key': _apiKey.isNotEmpty ? _apiKey : _defaultApiKey},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final castList = (data['cast'] as List<dynamic>?)
                ?.map((item) => CastMember.fromJson(item as Map<String, dynamic>))
                .take(12)
                .toList() ??
            [];
        _cache[key] = castList;
        return castList;
      }
    } catch (_) {}

    return [];
  }

  static Future<String?> fetchTrailerKey(int movieId) async {
    final key = 'trailer:$movieId';
    if (_cache.containsKey(key)) {
      return _cache[key] as String?;
    }

    try {
      final uri = Uri.parse('$_baseUrl/movie/$movieId/videos').replace(
        queryParameters: {'api_key': _apiKey.isNotEmpty ? _apiKey : _defaultApiKey},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        final trailer = results.firstWhere(
          (v) => (v['type'] == 'Trailer' || v['type'] == 'Teaser') && v['site'] == 'YouTube',
          orElse: () => results.isNotEmpty ? results.first : null,
        );
        final trailerKey = trailer != null ? trailer['key'] as String? : null;
        _cache[key] = trailerKey;
        return trailerKey;
      }
    } catch (_) {}

    return null;
  }
}
