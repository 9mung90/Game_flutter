// lib/pages/eweapon_list_page.dart (수정)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'eweapon.dart';
import 'game.dart';
import 'detail_view_page.dart';
import 'detail_image_view_page.dart';

// EWeaponListPage는 이제 무기 목록만 담당합니다.
class EWeaponListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 검색어를 상위 위젯에서 받음
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백
  final Function(EWeapon) navigateToDetailViewer; // 상세 뷰어 콜백

  const EWeaponListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.navigateToDetailViewer,
  });

  @override
  State<EWeaponListPage> createState() => _EWeaponListPageState();
}

class _EWeaponListPageState extends State<EWeaponListPage> {
  late Future<List<EWeapon>> _futureEWeapons;
  int? _expandedId; // 확장된 아이템 ID는 이 위젯 내부에서 관리

  @override
  void initState() {
    super.initState();
    _futureEWeapons = fetchEWeapons();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EWeapon>>(
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
            weapon.title.toLowerCase().contains(widget.searchQuery.toLowerCase())) // widget.searchQuery 사용
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => widget.showImageDialog(context, weapon.img, weapon.title), // 콜백 사용
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: 90,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                weapon.img,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                const Icon(Icons.image_not_supported, color: Colors.white24),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
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
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
                            child: GestureDetector(
                              onTap: () => widget.navigateToDetailViewer(weapon), // 콜백 사용
                              behavior: HitTestBehavior.translucent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/comment.png',
                                    width: 40.0,
                                    height: 40.0,
                                  ),
                                  const SizedBox(height: 2.0),
                                  const Text(
                                    '댓글 확인',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 1, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(color: Colors.white24, height: 1, thickness: 0.5),
                            const SizedBox(height: 10),
                            Text(
                              weapon.description,
                              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                if (weapon.img2.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailImageViewerPage(
                                        imageUrl: weapon.img2,
                                        title: weapon.title,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('상세 이미지가 없습니다.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/detailground.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '상세 이미지 보기',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
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
    );
  }
}