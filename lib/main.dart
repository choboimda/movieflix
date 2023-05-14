import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  static const popularEndpoint = "popular";
  static const nowPlayingEndpoint = "now-playing";
  static const comingSoonEndpoint = "coming-soon";
  final Future<List<MovieModel>> popularMovies =
      ApiService.getMovie(endpoint: HomeScreen.popularEndpoint);
  final Future<List<MovieModel>> nowInMovies =
      ApiService.getMovie(endpoint: HomeScreen.nowPlayingEndpoint);
  final Future<List<MovieModel>> comingMovies =
      ApiService.getMovie(endpoint: HomeScreen.comingSoonEndpoint);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              makeMoviesSection(section: popularEndpoint, isPopular: true),
              makeMoviesSection(section: nowPlayingEndpoint, isPopular: false),
              makeMoviesSection(section: comingSoonEndpoint, isPopular: false),
            ],
          ),
        ),
      ),
    );
  }

  Container makeMoviesSection(
      {required String section, required bool isPopular}) {
    late Future<List<MovieModel>> apiFuture;
    late String sectionTitile;
    switch (section) {
      case popularEndpoint:
        apiFuture = popularMovies;
        sectionTitile = "Popular Movies";
        break;
      case nowPlayingEndpoint:
        apiFuture = nowInMovies;
        sectionTitile = "Now in Cinemas";
        break;
      case comingSoonEndpoint:
        apiFuture = comingMovies;
        sectionTitile = "Coming soon";
        break;
    }
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitile,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.only(top: 15),
            height: 220,
            child: FutureBuilder(
              future: apiFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return makeList(
                    snapshot: snapshot,
                    isPopular: isPopular,
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<DetailInfo> movie;
  @override
  void initState() {
    super.initState();
    movie = ApiService.getDetailInfo(id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Back to List"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: movie,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                    color: Colors.black54,
                    colorBlendMode: BlendMode.darken,
                    fit: BoxFit.cover,
                    "https://image.tmdb.org/t/p/w500/${snapshot.data!.posterImage}"),
                Column(
                  children: [
                    Flexible(
                      flex: 4,
                      child: Container(),
                    ),
                    Flexible(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                snapshot.data!.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            StarRating(id: widget.id),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                snapshot.data!.genres.join(", "),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
                              child: Text(
                                "Story Line",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              snapshot.data!.overview,
                              style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Container(),
                    )
                  ],
                )
              ],
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class StarRating extends StatefulWidget {
  final String id;
  const StarRating({super.key, required this.id});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late SharedPreferences prefs;
  int _rating = 0;

  Future initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final rating = prefs.getInt(widget.id);
    if (rating != null) {
      setState(() {
        _rating = rating;
      });
    } else {
      await prefs.setInt(widget.id, 0);
    }
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Widget _buildStar(int index) {
    Icon icon;
    if (index < _rating) {
      icon = const Icon(Icons.star, color: Colors.yellow);
    } else {
      icon = const Icon(Icons.star, color: Colors.grey);
    }

    return GestureDetector(
      onTap: () async {
        _rating = index + 1;
        setState(() {
          _rating;
        });
        await prefs.setInt(widget.id, _rating);
      },
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) => _buildStar(index)),
    );
  }
}

ListView makeList(
    {required AsyncSnapshot<List<MovieModel>> snapshot,
    required bool isPopular}) {
  return ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: snapshot.data!.length,
    itemBuilder: (context, index) {
      var movies = snapshot.data![index];
      return MovieCard(
        popular: isPopular,
        backdropIamge: movies.backdropIamge,
        id: movies.id,
        title: movies.title,
      );
    },
    separatorBuilder: (context, index) {
      return const SizedBox(width: 15);
    },
  );
}

class MovieCard extends StatelessWidget {
  final String title;
  final String id;
  final String backdropIamge;
  final bool popular;
  const MovieCard({
    super.key,
    required this.backdropIamge,
    required this.id,
    required this.popular,
    required this.title,
  });
  final String imageBaseUrl = "https://image.tmdb.org/t/p/w500";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(id: id),
          ),
        );
      },
      child: Center(
        child: Column(
          children: [
            Container(
              width: popular ? 300 : 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: 1,
                    color: Colors.grey.withOpacity(0.7),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                fit: BoxFit.cover,
                "$imageBaseUrl/$backdropIamge",
                headers: const {
                  "User-Agent":
                      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                },
              ),
            ),
            !popular
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                        width: 150,
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}

class ApiService {
  static Future<List<MovieModel>> getMovie({required String endpoint}) async {
    List<MovieModel> movieInstance = [];
    const String baseUrl = "https://movies-api.nomadcoders.workers.dev";
    final String endpointUrl = endpoint;
    final url = Uri.parse("$baseUrl/$endpointUrl");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final movies = jsonDecode(response.body)["results"];
      for (var movie in movies) {
        movieInstance.add(
          MovieModel.fromJson(movie),
        );
      }
      return movieInstance;
    }
    throw Error();
  }

  static Future<DetailInfo> getDetailInfo({required String id}) async {
    List genresList = [];
    String movieInfoUrl =
        "https://movies-api.nomadcoders.workers.dev/movie?id=$id";
    final url = Uri.parse(movieInfoUrl);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final info = jsonDecode(response.body);
      for (var genre in info["genres"]) {
        genresList.add(genre["name"]);
      }
      final movieInfo = DetailInfo.fromJson(genresList: genresList, json: info);
      return movieInfo;
    }
    throw Error();
  }
}

class MovieModel {
  final String title, backdropIamge, id;

  MovieModel.fromJson(Map<String, dynamic> json)
      : title = json["title"],
        backdropIamge = json["backdrop_path"],
        id = json["id"].toString();
}

class DetailInfo {
  final List genres;
  final String title, posterImage, overview;
  DetailInfo.fromJson(
      {required Map<String, dynamic> json, required List<dynamic> genresList})
      : title = json["original_title"],
        posterImage = json["poster_path"],
        genres = genresList,
        overview = json["overview"];
}
