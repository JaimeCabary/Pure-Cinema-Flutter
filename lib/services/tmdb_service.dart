import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = '119f057993052814896eff7bb55e03db';

  static final Map<String, List<Movie>> _cache = {};

  static final List<Movie> fallbackMovies = [
    Movie(
      id: 157336,
      title: 'Interstellar',
      overview: 'The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel.',
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
      id: 550,
      title: 'Fight Club',
      overview: 'A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.',
      posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      backdropPath: '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
      releaseDate: '1999-10-15',
      voteAverage: 8.4,
    ),
    Movie(
      id: 299534,
      title: 'Avengers: Endgame',
      overview: 'After the devastating events of Infinity War, the universe is in ruins. With the help of remaining allies, the Avengers assemble once more.',
      posterPath: '/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
      backdropPath: '/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
      releaseDate: '2019-04-24',
      voteAverage: 8.3,
    ),
    Movie(
      id: 603,
      title: 'The Matrix',
      overview: 'Set in the 22nd century, The Matrix tells the story of a computer hacker who joins a group of underground insurgents fighting the vast and powerful computers who now rule the earth.',
      posterPath: '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
      backdropPath: '/easkWjhK5d7E871vE3q2J6oZf6U.jpg',
      releaseDate: '1999-03-30',
      voteAverage: 8.2,
    ),
    Movie(
      id: 155,
      title: 'The Dark Knight',
      overview: 'Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations that plague the streets.',
      posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      backdropPath: '/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg',
      releaseDate: '2008-07-16',
      voteAverage: 8.5,
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
      id: 122,
      title: 'The Lord of the Rings',
      overview: 'As armies mass for a final battle that will decide the fate of the world--and powerful, ancient forces of Light and Dark compete to determine the outcome.',
      posterPath: '/rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg',
      backdropPath: '/2u7zbn8EudG6kLlBzUYqP8RyFU4.jpg',
      releaseDate: '2003-12-01',
      voteAverage: 8.5,
    ),
  ];

  static Future<List<Movie>> _fetchEndpoint(String endpoint, [Map<String, String>? params]) async {
    final key = '$endpoint:${params?.toString()}';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: {
          'api_key': _apiKey,
          ...?params,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List<dynamic>?)
                ?.map((item) => Movie.fromJson(item as Map<String, dynamic>))
                .where((m) => m.posterPath != null)
                .toList() ??
            fallbackMovies;
        _cache[key] = results;
        return results;
      }
    } catch (_) {}

    return fallbackMovies;
  }

  static Future<List<Movie>> fetchTrending() => _fetchEndpoint('/trending/movie/week');
  static Future<List<Movie>> fetchPopular() => _fetchEndpoint('/movie/popular');
  static Future<List<Movie>> fetchNowPlaying() => _fetchEndpoint('/movie/now_playing');
  static Future<List<Movie>> fetchTopRated() => _fetchEndpoint('/movie/top_rated');
  static Future<List<Movie>> fetchAnimation() => _fetchEndpoint('/discover/movie', {'with_genres': '16', 'sort_by': 'popularity.desc'});
  
  static Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return fetchPopular();
    return _fetchEndpoint('/search/movie', {'query': query.trim()});
  }
}
