import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final Future<List<MovieModel>> popularMovies = ApiService.getPopularMovie();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(
            height: 100,
          ),
          makePopularMovies()
        ],
      ),
    );
  }

  Container makePopularMovies() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Movies",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.only(top: 15),
            height: 200,
            child: FutureBuilder(
              future: popularMovies,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return makeList(snapshot);
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

ListView makeList(AsyncSnapshot<List<MovieModel>> snapshot) {
  return ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: snapshot.data!.length,
    itemBuilder: (context, index) {
      var movies = snapshot.data![index];
      return PopularCard(
        backdropIamge: movies.backdropIamge,
        id: movies.id,
      );
    },
    separatorBuilder: (context, index) {
      return const SizedBox(width: 15);
    },
  );
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
                    color: Colors.black38,
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
                        child: const Column(
                          children: [
                            StarRating(),
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
  const StarRating({super.key});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _rating = 0;

  Widget _buildStar(int index) {
    Icon icon;
    if (index < _rating) {
      icon = const Icon(Icons.star, color: Colors.yellow);
    } else {
      icon = const Icon(Icons.star_border, color: Colors.grey);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _rating = index + 1;
        });
      },
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => _buildStar(index)),
    );
  }
}

class PopularCard extends StatelessWidget {
  final String id;
  final String backdropIamge;
  const PopularCard({super.key, required this.backdropIamge, required this.id});
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
        child: Container(
          width: 300,
          height: 170,
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
      ),
    );
  }
}

class ApiService {
  static Future<List<MovieModel>> getPopularMovie() async {
    List<MovieModel> popularInstance = [];
    const String baseUrl = "https://movies-api.nomadcoders.workers.dev";
    const String popular = "popular";
    final url = Uri.parse("$baseUrl/$popular");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final movies = jsonDecode(response.body)["results"];
      for (var movie in movies) {
        popularInstance.add(
          MovieModel.fromJson(movie),
        );
      }
      return popularInstance;
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
