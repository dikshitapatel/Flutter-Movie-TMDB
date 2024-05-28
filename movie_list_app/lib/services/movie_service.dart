import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiKey = '2901959a9dffb462647a8f3182b0c428';
const baseUrl = 'http://api.themoviedb.org/3/movie/popular?api_key=$apiKey';

class MovieService {
  static Future<List<dynamic>> fetchMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('moviesCache');
    List<dynamic> movies;

    // Load list of deleted movie IDs
    List<String> deletedMovieIds = prefs.getStringList('deletedMovieIds') ?? [];

    if (cachedData != null) {
      // Decode the cached string into a Map, then extract the 'results' List
      final Map<String, dynamic> decodedData = json.decode(cachedData);
      if (decodedData is Map<String, dynamic> && decodedData.containsKey('results')) {
        movies = decodedData['results'];
      } else {
        throw Exception('Cached data format is not as expected');
      }
    } else {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        await prefs.setString('moviesCache', response.body);
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          movies = data['results'];
        } else {
          throw Exception('Response data format is not as expected');
        }
      } else {
        throw Exception('Failed to load movies');
      }
    }

    // Filter out deleted movies
    return movies.where((movie) => !deletedMovieIds.contains(movie['id'].toString())).toList();
  }

  static Future<Map<String, dynamic>?> fetchMovieById(String movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('movieDetailsCache_$movieId');

    if (cachedData != null) {
      // Return cached movie details if available
      return json.decode(cachedData);
    } else {
      // Construct the URL for fetching movie details by ID
      final url = 'http://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Cache the response for future use
        await prefs.setString('movieDetailsCache_$movieId', response.body);
        // Decode and return the movie details
        return json.decode(response.body);
      } else {
        // Handle error or return null if the movie is not found
        print('Failed to load movie details');
        return null;
      }
    }
  }
}
