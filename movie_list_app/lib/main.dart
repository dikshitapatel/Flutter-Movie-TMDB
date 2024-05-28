import 'package:flutter/material.dart';
import 'package:movie_list_app/services/preferences_service.dart';
import 'services/movie_service.dart';
import 'movie_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefsService = PreferencesService();
  final isDarkMode = await prefsService.loadThemeMode();
  final lastScreen = await prefsService.loadLastOpenedScreen();
  final lastMovieId = await prefsService.loadLastOpenedMovieId();
  runApp(MyApp(
    initialTheme: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    initialScreen: lastScreen,
    lastMovieId: lastMovieId,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialTheme;
  final String? initialScreen;
  final String? lastMovieId;

  MyApp({required this.initialTheme, this.initialScreen, this.lastMovieId});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
    // Delay navigation until after initial render
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateIfLastScreenWasMovieDetails());
  }

  Future<void> _navigateIfLastScreenWasMovieDetails() async {
  // Async retrieval of preferences before making a navigation decision
  String? lastScreen = await PreferencesService().loadLastOpenedScreen();
  String? lastMovieId = await PreferencesService().loadLastOpenedMovieId();

  if (lastScreen == 'details' && lastMovieId != null) {
    var movie = await MovieService.fetchMovieById(lastMovieId);
    if (movie != null) {
      // Push MovieListScreen first without animation
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => MovieListScreen(onToggleTheme: (bool isDark) {
              setState(() {
                _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
                PreferencesService().saveThemeMode(isDark);
              });
            })),
      );

      // Then push MovieDetailsScreen, ensuring there's a screen in the stack to go back to
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
      );
    }
  } else {
    // If not resuming to 'details', just go to the movie list screen
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => MovieListScreen(onToggleTheme: (bool isDark) {
              setState(() {
                _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
                PreferencesService().saveThemeMode(isDark);
              });
            })),
    );
  }
}

 final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: widget.initialScreen == 'details' && widget.lastMovieId != null
          ? FutureBuilder<dynamic>(
              future: MovieService.fetchMovieById(widget.lastMovieId!),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    // Directly navigate to MovieDetailsScreen with actual movie data
                    return MovieDetailsScreen(movie: snapshot.data);
                  } else {
                    // Fallback to MovieListScreen if details couldn't be fetched
                    return Scaffold(body: Center(child: Text('Error loading movie details')));
                  }
                }
                // Show a loading spinner while waiting for movie details
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              },
            )
          : MovieListScreen(onToggleTheme: (bool isDark) {
              setState(() {
                _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
                PreferencesService().saveThemeMode(isDark);
              });
            }),
    );
  }
}

class MovieDetailsLoaderScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailsLoaderScreen({Key? key, required this.movieId}) : super(key: key);

  @override
  _MovieDetailsLoaderScreenState createState() => _MovieDetailsLoaderScreenState();
}

class _MovieDetailsLoaderScreenState extends State<MovieDetailsLoaderScreen> {
  @override
  void initState() {
     super.initState();
    _loadMovieAndNavigate();
  }

  Future<void> _loadMovieAndNavigate() async {
    var movie = await MovieService.fetchMovieById(widget.movieId);
    if (movie != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MovieDetailsScreen(movie: movie)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


class MovieListScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;

  MovieListScreen({required this.onToggleTheme});

  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<List<dynamic>> moviesFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    moviesFuture = MovieService.fetchMovies(); // Load movies
  }

 void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 15.0), 
        child: Text(
          'TMDB Popular Movies',
          style: TextStyle(
          ),
        ),
      ),
      TextField(
        onChanged: _updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search movies...',
          hintStyle: TextStyle(color: Colors.white),
          border: InputBorder.none,
        ),
        style: TextStyle(color: Colors.white, fontSize: 16.0),
      ),
    ],
  ),
        actions: [
            
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: widget.onToggleTheme,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: moviesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

           // Filter movies based on the search query
        final movies = snapshot.data!.where((movie) {
          return movie['title'].toLowerCase().contains(_searchQuery);
        }).toList();
        
          if (snapshot.hasData) {
            return ListView.builder(
               itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
                return ListTile(
                  contentPadding: EdgeInsets.all(8.0), // Padding around the list tile
                  leading: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: 'http://image.tmdb.org/t/p/w500/${movie['poster_path']}',
                    fit: BoxFit.cover,
                    width: 50.0,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          movie['title'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: _buildStars((movie['vote_average'] as double)),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await PreferencesService().saveLastOpenedScreen('details');

    // Save the movieId as the last opened movie before navigating
  await PreferencesService().saveLastOpenedMovieId(movie['id'].toString());
    var movies = await MovieService.fetchMovieById(movie['id'].toString());
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MovieDetailsScreen(movie: movies)),
    );
  },
                  onLongPress: () async {
                    List<String> deletedMovieIds = await PreferencesService().loadDeletedMovieIds();
                    deletedMovieIds.add(movie['id'].toString());
                    await PreferencesService().saveDeletedMovieIds(deletedMovieIds);
                    setState(() {
                      moviesFuture = MovieService.fetchMovies(); // Refresh the movie list to exclude deleted movies
                    });
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}

// Helper method to generate star icons based on the rating
List<Widget> _buildStars(double rating) {
  List<Widget> stars = [];
  int fullStars = rating ~/ 2; // Full stars
  bool halfStar = (rating % 2) != 0; // Half star if the rating is odd
  for (int i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, color: Colors.amber));
  }
  if (halfStar) {
    stars.add(Icon(Icons.star_half, color: Colors.amber));
  }
  // Add empty stars so the total count is 5
  for (int i = stars.length; i < 5; i++) {
    stars.add(Icon(Icons.star_border, color: Colors.amber));
  }
  return stars;
}

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
);


