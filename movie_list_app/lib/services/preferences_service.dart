import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {

  // Get instance of SharedPreferences
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // Save last opened movie ID
  Future<void> saveLastOpenedMovieId(String movieId) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('lastOpenedMovieId', movieId);
  }

  // Load last opened movie ID
  Future<String?> loadLastOpenedMovieId() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('lastOpenedMovieId');
  }

  // Save list of deleted movie IDs
  Future<void> saveDeletedMovieIds(List<String> movieIds) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setStringList('deletedMovieIds', movieIds);
  }

  // Load list of deleted movie IDs
  Future<List<String>> loadDeletedMovieIds() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getStringList('deletedMovieIds') ?? [];
  }

  // Save the last opened screen (for simplicity, using 'list' or 'details')
  Future<void> saveLastOpenedScreen(String screen) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('lastOpenedScreen', screen);
  }

  // Load the last opened screen
  Future<String?> loadLastOpenedScreen() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('lastOpenedScreen');
  }

  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
  }
}
