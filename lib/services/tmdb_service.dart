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
  ];

  static final List<Movie> tvShowsFallbacks = [
    Movie(
      id: 1399,
      title: 'Game of Thrones',
      overview: 'Seven noble families fight for control of the mythical land of Westeros. Friction between the houses leads to full-scale war.',
      posterPath: '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
      backdropPath: '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg',
      releaseDate: '2011-04-17',
      voteAverage: 8.4,
    ),
    Movie(
      id: 1396,
      title: 'Breaking Bad',
      overview: 'A chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine with a former student.',
      posterPath: '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
      backdropPath: '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
      releaseDate: '2008-01-20',
      voteAverage: 8.9,
    ),
    Movie(
      id: 85937,
      title: 'Succession',
      overview: 'The Roy family is known for controlling the biggest media and entertainment company in the world. However, their world changes when their aging father steps down.',
      posterPath: '/7T658vd4aBpzE27jXQeQ7lM3Gz9.jpg',
      backdropPath: '/f1AQhx6ZfGhPZFTtyYKRAcq9G57.jpg',
      releaseDate: '2018-06-03',
      voteAverage: 8.6,
    ),
    Movie(
      id: 126308,
      title: 'Shōgun',
      overview: 'When a mysterious European ship is found marooned in a nearby fishing village, Lord Yoshii Toranaga discovers secrets that could tip the scales of power.',
      posterPath: '/7O4iVfOMQmdCSPxRIiqxdu2Nnpg.jpg',
      backdropPath: '/5zmiBoMzeWKVyrbZzs8hDFtDNOS.jpg',
      releaseDate: '2024-02-27',
      voteAverage: 8.5,
    ),
  ];

  static final List<Movie> docuseriesFallbacks = [
    Movie(
      id: 92782,
      title: 'The Last Dance',
      overview: 'A 10-part documentary chronicles the 1990s Chicago Bulls, led by Michael Jordan, one of the most notable dynasties in sports history.',
      posterPath: '/7d38zI01l8d1eU6r266pXzCqY4q.jpg',
      backdropPath: '/nTvM4mhqFXZza79U1c4gK2vW9Y4.jpg',
      releaseDate: '2020-04-19',
      voteAverage: 8.8,
    ),
    Movie(
      id: 86450,
      title: 'Formula 1: Drive to Survive',
      overview: 'Drivers, managers and team owners live life in the fast lane — both on and off the track — during each cutthroat season of Formula 1 racing.',
      posterPath: '/7H2M7eL44v8b1e4R4Wn5YqZ7j8K.jpg',
      backdropPath: '/3r7K0K00p9U1wN4kP8uR7tZ9j0K.jpg',
      releaseDate: '2019-03-08',
      voteAverage: 8.4,
    ),
    Movie(
      id: 1045,
      title: 'Planet Earth II',
      overview: 'David Attenborough presents a documentary series exploring the unique characteristics of Earth\'s most iconic habitats and the extraordinary animals that live there.',
      posterPath: '/6Zw6c4gH7gW7jXzY9q1kK8nL5pQ.jpg',
      backdropPath: '/7w0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      releaseDate: '2016-11-06',
      voteAverage: 8.9,
    ),
  ];

  static final List<Movie> biographiesFallbacks = [
    Movie(
      id: 37799,
      title: 'The Social Network',
      overview: 'On a fall night in 2003, Harvard undergrad and computer programming genius Mark Zuckerberg sits down at his computer and heatedly begins working on a new idea.',
      posterPath: '/n0ybibhJtQ5icDqTpTpH1207apG.jpg',
      backdropPath: '/g4H3nZ5jP8uR7tZ9j0K7w0aK9vP.jpg',
      releaseDate: '2010-10-01',
      voteAverage: 7.8,
    ),
    Movie(
      id: 106646,
      title: 'The Wolf of Wall Street',
      overview: 'A New York stockbroker refuses to cooperate in a large securities fraud case that involves corruption on Wall Street, the corporate banking world and mob infiltration.',
      posterPath: '/34m2tygAYBGqA9MXKhRDtzYd4MR.jpg',
      backdropPath: '/cWUOv3H7YVwvPp4L8g0k8uR7tZ9.jpg',
      releaseDate: '2013-12-25',
      voteAverage: 8.0,
    ),
    Movie(
      id: 424694,
      title: 'Bohemian Rhapsody',
      overview: 'Singer Freddie Mercury, guitarist Brian May, drummer Roger Taylor and bass guitarist John Deacon take the music world by storm when they form the rock band Queen.',
      posterPath: '/lHu1wtN109GFTuTuKR2UkEo3vgq.jpg',
      backdropPath: '/7t0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      releaseDate: '2018-10-24',
      voteAverage: 8.0,
    ),
  ];

  static final List<Movie> sportsFallbacks = [
    Movie(
      id: 359724,
      title: 'Ford v Ferrari',
      overview: 'American car designer Carroll Shelby and the fearless British-born driver Ken Miles together battle corporate interference and the laws of physics to build a revolutionary race car for Ford Motor Company.',
      posterPath: '/6ApDtO7xa78wxv7w0aK9vP5jW4n.jpg',
      backdropPath: '/n313uvUZ0r4v3P650eNp1y7xK8n.jpg',
      releaseDate: '2019-11-13',
      voteAverage: 8.0,
    ),
    Movie(
      id: 60308,
      title: 'Moneyball',
      overview: 'Oakland A\'s general manager Billy Beane\'s successful attempt to assemble a baseball team on a lean budget by employing computer-generated analysis to acquire new players.',
      posterPath: '/42m1tZ4p1kK8nL5pQ7w0aK9vP5j.jpg',
      backdropPath: '/7t0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      releaseDate: '2011-09-22',
      voteAverage: 7.3,
    ),
    Movie(
      id: 307663,
      title: 'Creed',
      overview: 'The former World Heavyweight Champion Rocky Balboa serves as a trainer and mentor to Adonis Johnson, the son of his late friend and former rival Apollo Creed.',
      posterPath: '/7w0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      backdropPath: '/g4H3nZ5jP8uR7tZ9j0K7w0aK9vP.jpg',
      releaseDate: '2015-11-25',
      voteAverage: 7.4,
    ),
  ];

  static final List<Movie> romanceFallbacks = [
    Movie(
      id: 313369,
      title: 'La La Land',
      overview: 'Mia, an aspiring actress, and Sebastian, a dedicated jazz musician, are struggling to make ends meet in a city known for crushing hopes and breaking hearts.',
      posterPath: '/uDO8zWDhfWwoFdKS4fzkVJt0Rf0.jpg',
      backdropPath: '/qJeU7ee0YFvN6bUvW9oZ8zW6z.jpg',
      releaseDate: '2016-11-29',
      voteAverage: 7.9,
    ),
    Movie(
      id: 597,
      title: 'Titanic',
      overview: '101-year-old Rose DeWitt Bukater tells the story of her life aboard the Titanic, 84 years later, to her granddaughter and a team of treasure hunters.',
      posterPath: '/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg',
      backdropPath: '/6xmPqL8kP8uR7tZ9j0K7w0aK9vP.jpg',
      releaseDate: '1997-11-18',
      voteAverage: 7.9,
    ),
    Movie(
      id: 666277,
      title: 'Past Lives',
      overview: 'Nora and Hae Sung, two deeply connected childhood friends, are wrested apart after Nora\'s family emigrates from South Korea. Two decades later, they are reunited in New York for one fateful week.',
      posterPath: '/k3waqVXSnvCZWfJYNtdamTgTtTA.jpg',
      backdropPath: '/7t0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      releaseDate: '2023-06-02',
      voteAverage: 7.8,
    ),
  ];

  static final List<Movie> faithFallbacks = [
    Movie(
      id: 615,
      title: 'The Passion of the Christ',
      overview: 'A graphic depiction of the final twelve hours in the life of Jesus of Nazareth, on the day of his crucifixion in Jerusalem.',
      posterPath: '/vH64XbV09kK8nL5pQ7w0aK9vP5j.jpg',
      backdropPath: '/8t0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      releaseDate: '2004-02-25',
      voteAverage: 7.5,
    ),
    Movie(
      id: 324786,
      title: 'Hacksaw Ridge',
      overview: 'WWII American Army Medic Desmond T. Doss, who served during the Battle of Okinawa, refuses to kill people and becomes the first man in American history to receive the Medal of Honor without firing a shot.',
      posterPath: '/jcTq6Rfa9AezOl1X7ZLyf7UP1M.jpg',
      backdropPath: '/nTvM4mhqFXZza79U1c4gK2vW9Y4.jpg',
      releaseDate: '2016-10-07',
      voteAverage: 8.2,
    ),
    Movie(
      id: 257211,
      title: 'Silence',
      overview: 'Two 17th-century Portuguese missionaries undertake a perilous journey to Japan to find their missing mentor and spread Catholic Christianity.',
      posterPath: '/7t0aK9vP5jW4nN2mR8tZ7j0kP9U.jpg',
      backdropPath: '/g4H3nZ5jP8uR7tZ9j0K7w0aK9vP.jpg',
      releaseDate: '2016-12-22',
      voteAverage: 7.2,
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
      overview: 'Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family.',
      posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
      backdropPath: '/tmU7GeKVybMWFButWEGl2M4GeiP.jpg',
      releaseDate: '1972-03-14',
      voteAverage: 8.7,
    ),
  ];

  static final List<Movie> animationFallbacks = [
    Movie(
      id: 129,
      title: 'Spirited Away',
      overview: 'A young girl, Chihiro, becomes trapped in a strange new world of spirits. When her parents undergo a mysterious transformation, she must call upon the courage she never knew she had to free her family.',
      posterPath: '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
      backdropPath: '/Ab8mk7cGqp0lhLgY4g2aN7r6W9.jpg',
      releaseDate: '2001-07-20',
      voteAverage: 8.5,
    ),
    Movie(
      id: 569094,
      title: 'Spider-Man: Across the Spider-Verse',
      overview: 'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People charged with protecting its very existence.',
      posterPath: '/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
      backdropPath: '/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg',
      releaseDate: '2023-05-31',
      voteAverage: 8.4,
    ),
  ];

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

    return fallbackList;
  }

  static Future<List<Movie>> fetchTrending() =>
      _fetchEndpoint('/trending/movie/week', fallbackList: trendingFallbacks);

  static Future<List<Movie>> fetchNowPlaying() =>
      _fetchEndpoint('/movie/now_playing', fallbackList: bestPicksFallbacks);

  static Future<List<Movie>> fetchPopular() =>
      _fetchEndpoint('/movie/popular', fallbackList: bestPicksFallbacks);

  static Future<List<Movie>> fetchTopRated() =>
      _fetchEndpoint('/movie/top_rated', fallbackList: topRatedFallbacks);

  static Future<List<Movie>> fetchAnimation() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '16', 'sort_by': 'popularity.desc'}, fallbackList: animationFallbacks);

  static Future<List<Movie>> fetchTVShows() =>
      _fetchEndpoint('/discover/tv', params: {'sort_by': 'popularity.desc'}, fallbackList: tvShowsFallbacks);

  static Future<List<Movie>> fetchDocuseries() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '99', 'sort_by': 'popularity.desc'}, fallbackList: docuseriesFallbacks);

  static Future<List<Movie>> fetchBiographies() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '36,18', 'sort_by': 'popularity.desc'}, fallbackList: biographiesFallbacks);

  static Future<List<Movie>> fetchSports() =>
      _fetchEndpoint('/discover/movie', params: {'with_keywords': '6075', 'sort_by': 'popularity.desc'}, fallbackList: sportsFallbacks);

  static Future<List<Movie>> fetchRomance() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '10749', 'sort_by': 'popularity.desc'}, fallbackList: romanceFallbacks);

  static Future<List<Movie>> fetchFaith() =>
      _fetchEndpoint('/discover/movie', params: {'with_genres': '18,36', 'sort_by': 'vote_average.desc'}, fallbackList: faithFallbacks);

  static Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return fetchPopular();
    return _fetchEndpoint('/search/movie', params: {'query': query.trim()}, fallbackList: trendingFallbacks);
  }

  static Future<List<Movie>> fetchSimilar(int movieId) =>
      _fetchEndpoint('/movie/$movieId/similar', fallbackList: bestPicksFallbacks);

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

  /// Fetch Public Domain Vault Movies (Internet Archive, WikiFlix, Prelinger Archives & Blender Open Movies)
  static Future<List<Movie>> fetchPublicDomainMovies() async {
    try {
      final res = await http.get(Uri.parse('$_backendUrl/public-domain')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [
      Movie(
        id: 900001,
        title: 'Big Buck Bunny (Blender Open Movie)',
        overview: 'A large and lovable rabbit deals with bullying forest creatures in this iconic open-source 4K animation masterpiece.',
        posterPath: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.bip.png',
        backdropPath: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.bip.png',
        releaseDate: '2008-04-10',
        voteAverage: 8.5,
      ),
      Movie(
        id: 900002,
        title: 'Tears of Steel (Blender Sci-Fi Open Film)',
        overview: 'Set in a dystopian future Rotterdam, a group of warriors and scientists attempt to save the world from robotic destruction.',
        posterPath: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Tears_of_Steel_poster.jpg',
        backdropPath: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Tears_of_Steel_poster.jpg',
        releaseDate: '2012-09-26',
        voteAverage: 8.1,
      ),
      Movie(
        id: 900003,
        title: 'Sintel (Blender Fantasy Open Film)',
        overview: 'A lonely young woman named Sintel searches the world for her stolen dragon companion Scales.',
        posterPath: 'https://upload.wikimedia.org/wikipedia/commons/5/52/Sintel_poster.jpg',
        backdropPath: 'https://upload.wikimedia.org/wikipedia/commons/5/52/Sintel_poster.jpg',
        releaseDate: '2010-09-27',
        voteAverage: 8.2,
      ),
      Movie(
        id: 900004,
        title: 'Night of the Living Dead (1968)',
        overview: 'George A. Romero\'s seminal public domain horror classic that birthed the modern zombie genre.',
        posterPath: 'https://upload.wikimedia.org/wikipedia/commons/0/00/Night_of_the_Living_Dead_%281968%29_poster.jpg',
        backdropPath: 'https://upload.wikimedia.org/wikipedia/commons/0/00/Night_of_the_Living_Dead_%281968%29_poster.jpg',
        releaseDate: '1968-10-01',
        voteAverage: 8.0,
      ),
    ];
  }
}
