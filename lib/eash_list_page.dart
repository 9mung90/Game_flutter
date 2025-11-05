// lib/pages/eash_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../api_config.dart';
import 'eash.dart';            // ✅ EAsh DTO 사용
import 'game.dart';

/// 재료(재, Ash) 목록 페이지 - 댓글/네비 제거 버전
class EAshListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  const EAshListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
  });

  @override
  State<EAshListPage> createState() => _EAshListPageState();
}

class _EAshListPageState extends State<EAshListPage> {
  late Future<List<EAsh>> _futureEAshes;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureEAshes = fetchEAshes();
  }

  Future<List<EAsh>> fetchEAshes() async {
    // ✅ 백엔드 라우트에 맞춰 경로 확인 (예: /EAsh)
    final response = await http.get(Uri.parse('$apiBaseUrl/EAsh'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => EAsh.fromJson(item)).toList();
    } else {
      throw Exception('EAsh 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // 디버그용
    // print('Screen Width: $screenWidth');
    // print('Screen Height: $screenHeight');

    return FutureBuilder<List<EAsh>>(
      future: _futureEAshes,
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

        final items = snapshot.data ?? [];

        final filtered = items
            .where((e) =>
        e.game == widget.game.title &&
            e.title.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final ash = filtered[index];
            final isExpanded = _expandedId == ash.id;

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
                  _expandedId = isExpanded ? null : ash.id;
                }),
                child: Column(
                  children: [
                    SizedBox(
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => widget.showImageDialog(context, ash.img, ash.title),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                ash.img,
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
                                    ash.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // ✅ EAsh에는 part/aset이 없고 property만 있다고 가정
                                  Row(
                                    children: [
                                      Text(
                                        ash.property, // 속성
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 댓글/네비 버튼 없음
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
                              ash.description,
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
