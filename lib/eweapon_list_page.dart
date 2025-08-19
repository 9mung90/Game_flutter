import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'eweapon.dart';
import 'game.dart';
import 'detail_view_page.dart';

// --- 수정된 전체 화면 이미지 뷰어 페이지 ---
class FullScreenImageViewer extends StatelessWidget {
  final EWeapon weapon;

  const FullScreenImageViewer({
    super.key,
    required this.weapon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 1. AppBar가 콘텐츠와 겹치지 않도록 수정
      appBar: AppBar(
        title: Text(weapon.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900], // 배경색 지정
        elevation: 1, // 그림자 효과
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // extendBodyBehindAppBar: true, // 이 속성 제거

      // 2. body를 Column으로 변경하여 이미지와 댓글 영역을 수직으로 배치
      body: Column(
        children: [
          // 3. 이미지는 남은 공간을 모두 차지하도록 Expanded로 감싸기
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  weapon.img2,
                  fit: BoxFit.contain,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error_outline, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
          ),

          // 4. 하단에 댓글 입력 섹션 추가
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '댓글',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24, height: 12),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[850],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send, color: Colors.grey[400]),
                      onPressed: () {
                        // TODO: 댓글 전송 로직 구현
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class EWeaponListPage extends StatefulWidget {
  final Game game;
  const EWeaponListPage({super.key, required this.game});

  @override
  State<EWeaponListPage> createState() => _EWeaponListPageState();
}

class _EWeaponListPageState extends State<EWeaponListPage> {
  late Future<List<EWeapon>> _futureEWeapons;
  final TextEditingController _searchController = TextEditingController();
  int? _expandedId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureEWeapons = fetchEWeapons();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<EWeapon>> fetchEWeapons() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/EWeapon'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => EWeapon.fromJson(item)).toList();
    } else {
      throw Exception('무기 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 이미지가 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.fill,
                  ),
                  Center(
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported, color: Colors.white38, size: 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToFullScreenViewer(EWeapon weapon) {
    if (weapon.img2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 이미지가 없습니다.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailViewerPage(
          weapon : weapon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: Text(widget.game.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '아이템 이름으로 검색...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                filled: true,
                fillColor: const Color.fromRGBO(33, 33, 33, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EWeapon>>(
              future: _futureEWeapons,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final filteredWeapons = snapshot.data
                    ?.where((weapon) =>
                weapon.game == widget.game.title &&
                    weapon.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList() ??
                    [];

                if (filteredWeapons.isEmpty) {
                  return const Center(
                    child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: filteredWeapons.length,
                  itemBuilder: (context, index) {
                    final weapon = filteredWeapons[index];
                    final isExpanded = _expandedId == weapon.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/background.png'),
                          fit: BoxFit.fill,
                          alignment: Alignment.center,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() {
                          _expandedId = isExpanded ? null : weapon.id;
                        }),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 80.0,
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showImageDialog(context, weapon.img, weapon.title),
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 3),
                                        width: 90,
                                        height: double.infinity,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.network(
                                            weapon.img,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) =>
                                            const Icon(Icons.image_not_supported, color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              weapon.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              weapon.type,
                                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _navigateToFullScreenViewer(weapon),
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Center(
                                          child: Text(
                                            "상세보기",
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                child: Column(
                                  children: [
                                    const Divider(color: Colors.white24, height: 1, thickness: 0.5),
                                    const SizedBox(height: 10),
                                    Text(
                                      weapon.description,
                                      style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}