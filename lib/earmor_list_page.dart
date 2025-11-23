// lib/pages/earmor_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'earmor.dart';
import 'game.dart';
import 'detail_image_view_page.dart';

/// ⭐ 파일 전역 캐시: 이 파일 안에서만 쓰이는 방어구 캐시
List<EArmor>? _eArmorCache;

/// 방어구 목록 페이지 (댓글 기능 제거 버전)
class EArmorListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔹 방어구 필터 값 (ex. '전체', '머리', '몸통' ...)
  final String partFilter;

  // 🔥 본편 / DLC 필터 (이름에 ◇ 포함 여부로 구분)
  //  - filterBase: 본편 방어구
  //  - filterDlc : DLC 방어구 (이름에 ◇ 포함)
  final bool filterBase;
  final bool filterDlc;

  const EArmorListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.partFilter,  // 🔹 기존 필터
    this.filterBase = true,    // 🔥 기본값: 본편만 ON
    this.filterDlc = false,    // 🔥 기본값: DLC OFF
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
    // ⭐ 1) 캐시가 있으면 그대로 반환 (API 안 탐)
    if (_eArmorCache != null) {
      return _eArmorCache!;
    }

    // ⭐ 2) 캐시가 없을 때만 실제 API 호출
    final response = await http.get(Uri.parse('$apiBaseUrl/EArmor'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<EArmor> data =
      body.map((dynamic item) => EArmor.fromJson(item)).toList();

      // ⭐ 3) 결과를 캐시에 저장
      _eArmorCache = data;
      return data;
    } else {
      throw Exception('방어구 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  /// description 파싱:
  /// 1) 기본적으로 '.'를 기준으로 문장 분리
  /// 2) 단, '.' 뒤의 첫 non-space 문자가 '(' 이면, ')'까지 한 줄로 묶고
  ///    그 다음부터 줄바꿈
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

        // '.' 다음이 '(' 이면: 괄호 끝까지 같은 줄로
        if (j < len && text[j] == '(') {
          // j 위치까지 버퍼에 들어가도록 i 이동
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
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 16.0;

    return FutureBuilder<List<EArmor>>(
      future: _futureEArmors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '에러 발생: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final filteredArmors = snapshot.data
        // 🔹 기존 조건 + partFilter + 본편/DLC 필터까지 함께 적용
            ?.where((armor) {
          final bool gameMatch = armor.game == widget.game.title;
          final bool nameMatch = armor.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          // 🔹 부위 필터 ('전체'면 모두 통과)
          final bool partMatch = widget.partFilter == '전체'
              ? true
              : armor.part == widget.partFilter;

          // 🔥 본편 / DLC 판별
          //  - 제목에 '◇' 포함: DLC
          //  - 그 외: 본편
          final String title = armor.title;
          final bool isDlc = title.contains('◇');
          final bool isBase = !isDlc;

          final bool baseFlag = widget.filterBase;
          final bool dlcFlag = widget.filterDlc;

          bool matchesBaseDlc = true;

          // - 둘 다 true  → 제약 없음 (본편+ DLC 모두 허용)
          // - base만 true → 본편만
          // - dlc만 true  → DLC만
          // - 둘 다 false → 제약 없음 (둘 다 허용)
          if (baseFlag && dlcFlag) {
            matchesBaseDlc = true;
          } else if (baseFlag && !dlcFlag) {
            matchesBaseDlc = isBase;
          } else if (!baseFlag && dlcFlag) {
            matchesBaseDlc = isDlc;
          } else {
            matchesBaseDlc = true;
          }

          return gameMatch && nameMatch && partMatch && matchesBaseDlc;
        }).toList() ??
            [];

        if (filteredArmors.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, bottomPadding),
          itemCount: filteredArmors.length,
          itemBuilder: (context, index) {
            final armor = filteredArmors[index];
            final isExpanded = _expandedId == armor.id;

            // 설명 문장을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(armor.description);

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
                            onTap: () => widget.showImageDialog(
                                context, armor.img, armor.title),
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
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12.0),
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
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        armor.aset,
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ✅ 댓글 버튼 없음
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(8, 1, 12, 12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            const Divider(
                                color: Colors.white24,
                                height: 1,
                                thickness: 0.5),
                            const SizedBox(height: 10),

                            // 설명: 문장별로 나눠 한 줄씩 + 줄마다 SizedBox
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
