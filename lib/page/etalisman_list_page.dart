// lib/pages/etalisman_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../api_config.dart';
import '../DTO/etalisman.dart';
import '../DTO/game.dart';
import '../local_data/local_data_loader.dart'; // ⭐ 로컬 JSON 로더 추가

/// 🔥 ETalisman 전역 캐시 (이 파일 안에서만 사용)
List<ETalisman>? _eTalismanCache;

/// 탈리스만(ETalisman) 목록 페이지
class ETalismanListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔹 본편 / DLC 필터
  final bool filterBase; // 본편 탈리스만 표시 여부
  final bool filterDlc;  // DLC 탈리스만 표시 여부

  // 🔥 전설 탈리스만 필터 (주문이랑 동일 구조)
  final bool filterLegend; // 전설만 보기 여부

  const ETalismanListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.filterBase,
    required this.filterDlc,
    this.filterLegend = false, // 🔥 기본값: 전설 필터 OFF
  });

  @override
  State<ETalismanListPage> createState() => _ETalismanListPageState();
}

class _ETalismanListPageState extends State<ETalismanListPage> {
  late Future<List<ETalisman>> _futureETalismans;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureETalismans = fetchETalismans();
  }

  Future<List<ETalisman>> fetchETalismans() async {
    // ✅ 이제는 탈리스만 데이터도 로컬 JSON(ETalismanv1.json)에서 읽어온다.
    return LocalDataLoader.loadTalismans();

    /*
    // 🔥 [이전 버전] 서버에서 탈리스만 데이터를 받아오던 코드 (백업용으로 남겨둠)

    // 1) 이미 캐시가 있으면 API 호출 없이 바로 반환
    if (_eTalismanCache != null) {
      return _eTalismanCache!;
    }

    // 컨트롤러에서 매핑한 URL에 맞춰 수정하면 됨 (예: /ETalisman)
    final response = await http.get(Uri.parse('$apiBaseUrl/ETalisman'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<ETalisman> data =
          body.map((dynamic item) => ETalisman.fromJson(item)).toList();

      // 2) 첫 로딩 결과를 캐시에 저장
      _eTalismanCache = data;
      return data;
    } else {
      throw Exception('탈리스만 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
    */
  }

  /// description 파싱:
  /// 1) 기본적으로 '.'를 기준으로 문장 분리
  /// 2) 단, '.' 뒤의 첫 non-space 문자가 '(' 이면, ')' 나올 때까지 같은 문장으로 묶고
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

        // '.' 다음이 '(' 이면: 괄호 끝까지 같은 줄로 묶기
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
          // 일반적인 '.' → 문장 끝
          final line = buf.toString().trim();
          if (line.isNotEmpty) {
            result.add(line);
          }
          buf.clear();
        }
      }

      i++;
    }

    // 마지막 남은 부분 처리
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

    return FutureBuilder<List<ETalisman>>(
      future: _futureETalismans,
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        // 에러
        else if (snapshot.hasError) {
          return Center(
            child: Text(
              '에러 발생: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final items = snapshot.data ?? [];

        // 🔥 게임 이름 + 검색어 + 본편/DLC + 전설 필터링
        final filtered = items.where((e) {
          final bool gameMatch = e.game == widget.game.title;
          final bool nameMatch = e.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          // 이름에 '◇' 있으면 DLC로 취급
          final bool isDlc = e.title.contains('◇');

          // 🔥 전설 판정 규칙
          //  - 제목에 '☆' 포함
          //  - 제목에 '전설' 이라는 단어 포함
          final bool isLegend =
              e.title.contains('☆') || e.title.contains('전설');

          bool baseDlcMatch;
          if (widget.filterBase && !widget.filterDlc) {
            // 본편만 보기
            baseDlcMatch = !isDlc;
          } else if (!widget.filterBase && widget.filterDlc) {
            // DLC만 보기
            baseDlcMatch = isDlc;
          } else {
            // 둘 다 true 또는 둘 다 false → 둘 다 허용
            baseDlcMatch = true;
          }

          // 🔥 전설 필터: 켜져 있으면 전설만 통과
          bool legendMatch = true;
          if (widget.filterLegend) {
            legendMatch = isLegend;
          }

          return gameMatch && nameMatch && baseDlcMatch && legendMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              '항목이 없습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, bottomPadding),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final talisman = filtered[index];
            final isExpanded = _expandedId == talisman.id;

            // ability가 비어있는지 체크
            final bool hasAbility = talisman.ability.trim().isNotEmpty;

            // 설명을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(talisman.description);

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
                onTap: () {
                  setState(() {
                    _expandedId = isExpanded ? null : talisman.id;
                  });
                },
                child: Column(
                  children: [
                    // 상단: 썸네일 + 제목 + 태그
                    SizedBox(
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 왼쪽 썸네일
                          GestureDetector(
                            onTap: () => widget.showImageDialog(
                              context,
                              talisman.img,
                              talisman.title,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                talisman.img,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                          // 오른쪽 텍스트 영역
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 제목
                                  Text(
                                    talisman.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // 작은 태그 느낌으로 "탈리스만"
                                  Text(
                                    '탈리스만',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 아래: 확장 영역(설명 + 능력)
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
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 10),

                            // 설명: 문장마다 Text + SizedBox로 한 칸씩 띄우기
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final line in descriptionLines)
                                  if (line.trim().isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0), // 👉 설명 들여쓰기
                                      child: Text(
                                        line.trim(),
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                              ],
                            ),

                            // 능력이 있을 때만: 여백 + 능력 출력
                            if (hasAbility) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  talisman.ability,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
