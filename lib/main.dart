import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'game.dart';
import 'etc.dart';
import 'eweapon_list_page.dart';
import 'list_Top.dart';
import 'login_page.dart';

// 메인페이지, 어차피 엘든링 말고는 작동 안함

ValueNotifier<int> homePageRefreshNotifier = ValueNotifier(0);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔹 앱 켜지자마자 ListTop으로 바로 이동
      initialRoute: '/listTop',

      routes: {
        // 원래 메인 페이지 (나중에 다시 쓸 수 있게 유지)
        '/main': (context) => const MainPage(),

        // 🔹 Elden Ring용 ListTop 라우트
        '/listTop': (context) {
          // 여기서 임시 Elden Ring Game 하나 만들어서 넘김
          final Game eldenRing = Game(
            id: 18,
            title: '엘든 링',
            genre1: '소울라이크',
            genre2: '모험',
            genre3: '어드벤쳐',
            img: 'https://coddingswitch.s3.ap-northeast-2.amazonaws.com/test/Elden-Ring-KF01.jpg',
            price: 49800,
            // Game 클래스에 다른 필드 있으면 거기도 채워줘
          );

          return ListTop(game: eldenRing);
        },
      },

      theme: ThemeData(
        fontFamily: 'OptimusPrinceps',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),

      // 🔹 initialRoute를 쓰고 있으니까 home은 굳이 안 써도 됨 (써도 무시됨)
      // home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: "게임 목록"),
      body: const SafeArea(child: GameListPage()),
      bottomNavigationBar: Bottom(),
    );
  }
}

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  late Future<List<Game>> futureGames;

  @override
  void initState() {
    super.initState();
    futureGames = fetchGames();
    homePageRefreshNotifier.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    homePageRefreshNotifier.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    setState(() {
      futureGames = fetchGames();
    });
  }

  Future<List<Game>> fetchGames() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/api/game'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => Game.fromJson(item)).toList();
    } else {
      throw Exception("게임 데이터를 불러올 수 없습니다: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // [추가] 화면 크기를 가져옵니다.
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return FutureBuilder<List<Game>>(
      future: futureGames,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('게임 데이터가 없습니다.'));
        }

        final games = snapshot.data!;
        return Padding(
          // [수정] 고정값 -> 화면 비율에 따른 값
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.025, // 20.0 / 800.0
            horizontal: screenWidth * 0.033, // 12.0 / 360.0
          ),
          child: SizedBox(
            // [수정] 고정값 -> 화면 높이 비율에 따른 값
            height: screenHeight * 0.325, // 260.0 / 800.0
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // 🔹 GameItemMasterPage → ListTop으로 변경
                        builder: (context) => ListTop(game: game),
                      ),
                    );
                  },
                  child: Container(
                    // [수정] 고정값 -> 화면 너비 비율에 따른 값
                    width: screenWidth * 0.444, // 160.0 / 360.0
                    // [수정] 고정값 -> 화면 너비 비율에 따른 값
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.022), // 8.0 / 360.0
                    decoration: BoxDecoration(
                      // [수정] 고정값 -> 화면 너비 비율에 따른 값
                      borderRadius: BorderRadius.circular(screenWidth * 0.044), // 16.0 / 360.0
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          // [수정] 고정값 -> 화면 너비 비율에 따른 값
                          blurRadius: screenWidth * 0.016, // 6.0 / 360.0
                          // [수정] 고정값 -> 화면 높이 비율에 따른 값
                          offset: Offset(0, screenHeight * 0.005), // 4.0 / 800.0
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      // [수정] 고정값 -> 화면 너비 비율에 따른 값
                      borderRadius: BorderRadius.circular(screenWidth * 0.044), // 16.0 / 360.0
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              game.img,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image)),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          ),
                          Positioned(
                            // [수정] 고정값 -> 화면 너비 비율에 따른 값
                            left: screenWidth * 0.022, // 8.0 / 360.0
                            bottom: screenWidth * 0.022, // 8.0 / 360.0
                            child: CircleAvatar(
                              // [수정] 고정값 -> 화면 너비 비율에 따른 값
                              radius: screenWidth * 0.038, // 14.0 / 360.0
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  // [수정] 고정값 -> 화면 높이 비율에 따른 값
                                  fontSize: screenHeight * 0.015, // 12.0 / 800.0
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            // [수정] 고정값 -> 화면 너비 비율에 따른 값
                            bottom: screenWidth * 0.022, // 8.0 / 360.0
                            right: screenWidth * 0.022, // 8.0 / 360.0
                            child: Container(
                              // [수정] 고정값 -> 화면 비율에 따른 값
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.016, // 6.0 / 360.0
                                vertical: screenHeight * 0.005, // 4.0 / 800.0
                              ),
                              color: Colors.black.withOpacity(0.5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    game.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenHeight * 0.015,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${game.price}원',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenHeight * 0.013,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
