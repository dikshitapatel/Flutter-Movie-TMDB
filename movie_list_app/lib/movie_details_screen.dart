import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovieDetailsScreen extends StatelessWidget {
  final dynamic movie;
  const MovieDetailsScreen({Key? key, required this.movie}) : super(key: key);

  // Helper method to generate star icons based on the rating
  List<Widget> _buildStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating ~/ 2; // Calculate the number of full stars
    bool halfStar = (rating % 2) != 0; // Determine if there is a half star
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber, size: 20));
    }
    if (halfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.amber, size: 20));
    }
    // Fill the remaining slots with empty stars to always have 5 stars in total
    for (int i = stars.length; i < 5; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.amber, size: 20));
    }
    return stars;
  }
  

  @override
  Widget build(BuildContext context) {
    // Parse the release date from the movie details and format it
    final releaseDate = movie['release_date'] != null
        ? DateFormat('yyyy-MM-dd').parse(movie['release_date'])
        : null;
    final formattedReleaseDate = releaseDate != null
        ? DateFormat.yMMMMd('en_US').format(releaseDate)
        : 'Unknown release date';

    var imagePaths = [
      if (movie['poster_path'] != null) movie['poster_path'],
      if (movie['backdrop_path'] != null) movie['backdrop_path'],
    ];

    // Replicate the Swift logic of showing each image twice
    var repeatedImagePaths = List.from(imagePaths)..addAll(imagePaths);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // Navigates back to the previous screen
        ),
        title: Text(movie['title']), // Movie title on the AppBar
      ),
      body: SingleChildScrollView( // Allows the content to be scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Add the horizontal image scroller here
              if (repeatedImagePaths.isNotEmpty)
                SizedBox(
                  height: 300.0, // Fixed height for the scroller
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: repeatedImagePaths.length,
                    itemBuilder: (BuildContext context, int index) {
                      String imagePath = repeatedImagePaths[index];
                      return Container(
                        width: 300.0, // Fixed width for each image container
                        padding: EdgeInsets.all(4.0), // Optional padding between images
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0), // Optional corner radius
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png', // Placeholder image
                            image: 'http://image.tmdb.org/t/p/w500$imagePath',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 16.0),
              Text(
                movie['title'],
                style: Theme.of(context).textTheme.headline5, // Styling the movie title
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  ..._buildStars((movie['vote_average'] as double)), // Displays star ratings based on the movie's average votes
                  SizedBox(width: 10),
                  Text('${movie['vote_average']}/10'), // Shows the numeric rating
                ],
              ),
              SizedBox(height: 8.0),
              Text(
                'Release Date: $formattedReleaseDate', // Displays the formatted release date
                style: Theme.of(context).textTheme.subtitle1,
              ),
              SizedBox(height: 16.0),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headline6, // Styling the "Overview" section heading
              ),
              SizedBox(height: 8.0),
              Text(
                movie['overview'], // Displays the movie's overview text
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
