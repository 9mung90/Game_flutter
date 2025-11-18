// lib/pages/eweapon_list_page.dart (수정)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'eweapon.dart';
import 'game.dart';
import 'detail_view_page.dart';
import 'detail_image_view_page.dart';

// 무기 목록 보여주는 페이지 나중에 방어구 페이지 같은거도 이거 복붙하면 됨

// EWeaponListPage는 이제 무기 목록만 담당합니다.
class EWeaponListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 검색어를 상위 위젯에서 받음
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이어로그 콜백
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

  /// description 파싱:
  /// 1) 기본적으로 '.'를 기준으로 문장 분리
  /// 2) 단, '.' 뒤의 첫 non-space 문자가 '(' 이면, ')' 나올 때까지 한 줄로 묶고
  ///    ')' 뒤에서 줄바꿈
  List<String> _splitDescriptionWithParens(String text) {
    final List<String> result = [];
    final StringBuffer buf = StringBuffer();
    int i = 0;
    final int len = text.length;

    while (i < len) {
      final String ch = text[i];
      buf.write(ch);

      if (ch == '.') {
        // '.' 뒤의 첫 non-space 문자 확인
        int j = i + 1;
        while (j < len && text[j] == ' ') {
          j++;
        }

        // '.' 다음이 '(' 이면: 괄호 내용까지 한 문장으로
        if (j < len && text[j] == '(') {
          // j까지 이미 buf에 들어가게 i를 옮김
          while (i + 1 < len && i + 1 <= j) {
            i++;
            buf.write(text[i]);
          }

          // ')' 나올 때까지 읽기
          while (i + 1 < len) {
            i++;
            buf.write(text[i]);
            if (text[i] == ')') {
              break;
            }
          }

          final line = buf.toString().trim();
          if (line.isNotEmpty) {
            result.add(line);
          }
          buf.clear();
        } else {
          // 그냥 '.'이면 여기서 문장 종료
          final line = buf.toString().trim();
          if (line.isNotEmpty) {
            result.add(line);
          }
          buf.clear();
        }
      }

      i++;
    }

    // 마지막에 남은 것 처리
    final tail = buf.toString().trim();
    if (tail.isNotEmpty) {
      result.add(tail);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // ✅ print() 함수를 사용해 변수 값을 출력합니다.
    print('Screen Width: $screenWidth');
    print('Screen Height: $screenHeight');
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
            weapon.title
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase())) // widget.searchQuery 사용
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

            // 설명을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(weapon.description);

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
                      // [수정] 고정값 80.0 -> 화면 높이의 10% (80.0 / 800.0)
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                widget.showImageDialog(context, weapon.img, weapon.title), // 콜백 사용
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              // [수정] 고정값 90 -> 화면 너비의 25% (90.0 / 360.0)
                              width: screenWidth * 0.25,
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
                                  Row(
                                    children: [
                                      Text(
                                        weapon.type,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                      // 구분 기호와 좌우 공백을 추가합니다.
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        weapon.genre,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                    ],
                                  )
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
                                    // [수정] 고정값 40.0 -> 화면 너비의 약 11% (40.0 / 360.0)
                                    width: screenWidth * 0.11,
                                    height: screenWidth * 0.11,
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

                            // 🔹 설명: 문장별로 나눠서 한 줄씩 + 줄마다 SizedBox로 간격
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final line in descriptionLines)
                                  if (line.trim().isNotEmpty) ...[
                                    Text(
                                      line.trim(),
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                              ],
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
