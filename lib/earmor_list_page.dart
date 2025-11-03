// lib/pages/earmor_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'earmor.dart';
import 'game.dart';
import 'detail_image_view_page.dart';

/// 방어구 목록 페이지 (댓글 기능 제거 버전)
class EArmorListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  const EArmorListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
  });

  @override
  State<EArmorListPage> createState() => _EArmorListPageState();
}

class _EArmorListPageState extends State<EArmorListPage> {
  late Future<List<EArmor>> _futureEArmors;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureEArmors = fetchEArmors();
  }

  Future<List<EArmor>> fetchEArmors() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/EArmor'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => EArmor.fromJson(item)).toList();
    } else {
      throw Exception('방어구 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    print('Screen Width: $screenWidth');
    print('Screen Height: $screenHeight');

    return FutureBuilder<List<EArmor>>(
      future: _futureEArmors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '에러 발생: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final filteredArmors = snapshot.data
            ?.where((armor) =>
        armor.game == widget.game.title &&
            armor.title.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList() ??
            [];

        if (filteredArmors.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: filteredArmors.length,
          itemBuilder: (context, index) {
            final armor = filteredArmors[index];
            final isExpanded = _expandedId == armor.id;

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
                  _expandedId = isExpanded ? null : armor.id;
                }),
                child: Column(
                  children: [
                    SizedBox(
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => widget.showImageDialog(context, armor.img, armor.title),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                armor.img,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white24,
                                ),
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
                                    armor.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        armor.part,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        armor.aset, // genre가 없다면 DTO에 맞춰 제거/변경
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ✅ 댓글 버튼(및 네비게이션) 완전히 제거됨
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
                              armor.description,
                              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 12),

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
