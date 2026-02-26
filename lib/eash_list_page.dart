// lib/pages/eash_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;   // 🔹 예전 서버 방식(주석 코드에서만 사용)
import 'dart:convert';

import '../api_config.dart';
import 'local_data/local_data_loader.dart';        // ✅ 로컬 JSON 로더
import 'eash.dart';            // ✅ EAsh DTO 사용
import 'game.dart';

/// ⭐ EAsh 전역 캐시 (이 파일 안에서만 사용)
List<EAsh>? _eAshCache;

/// 재료(재, Ash) 목록 페이지 - 댓글/네비 제거 버전
class EAshListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔹 전투 기술(재) 속성 필터 값 (예: '전체', '물리', '화염' ...)
  final String propertyFilter;

  // 🔥 본편 / DLC 필터
  //  - title에 '◇' 포함 → DLC
  //  - 포함 안 됨 → 본편
  final bool filterBase; // 본편 전투 기술
  final bool filterDlc;  // DLC 전투 기술

  const EAshListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.propertyFilter,
    this.filterBase = true,   // 기본: 본편 ON
    this.filterDlc = false,   // 기본: DLC OFF
  });

  @override
  State<EAshListPage> createState() => _EAshListPageState();
}

class _EAshListPageState extends State<EAshListPage> {
  late Future<List<EAsh>> _futureEAshes;
  int? _expandedId; // 확장된 카드의 아이템 id

  // ✅ 추가: 시전 모션(gif) 표시 여부를 아이템 id로 관리
  int? _gifExpandedId;

  @override
  void initState() {
    super.initState();
    _futureEAshes = fetchEAshes();
  }

  Future<List<EAsh>> fetchEAshes() async {
    // 🔥 이제는 서버가 아니라, 로컬 JSON(assets/data/EAshv1.json)에서 불러온다.
    return await LocalDataLoader.loadAshes();

    /*
    // 📌 예전: 백엔드 API에서 불러오던 방식 (참고용으로 남김)
    // ⭐ 1) 캐시가 이미 있으면 그대로 반환 (API 호출 안 함)
    if (_eAshCache != null) {
      return _eAshCache!;
    }

    // ✅ 백엔드 라우트에 맞춰 경로 확인 (예: /EAsh)
    final response = await http.get(Uri.parse('$apiBaseUrl/EAsh'));
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<EAsh> data =
          body.map((dynamic item) => EAsh.fromJson(item)).toList();

      // ⭐ 2) 처음 로딩한 데이터 캐시에 저장
      _eAshCache = data;
      return data;
    } else {
      throw Exception('EAsh 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
    */
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

        final filtered = items.where((e) {
          final bool gameMatch = e.game == widget.game.title;
          final bool nameMatch = e.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          // 🔹 속성 필터 (기존 로직 유지)
          final bool propertyMatch = widget.propertyFilter == '전체'
              ? true
              : e.property == widget.propertyFilter;

          // 🔥 본편 / DLC 판별
          final String title = e.title;
          final bool isDlc = title.contains('◇'); // DLC
          final bool isBase = !isDlc;             // 본편

          final bool baseFlag = widget.filterBase;
          final bool dlcFlag = widget.filterDlc;

          bool matchesBaseDlc = true;

          // - 둘 다 true  → 둘 다 허용
          // - base만 true → 본편만
          // - dlc만 true  → DLC만
          // - 둘 다 false → 제한 없음
          if (baseFlag && dlcFlag) {
            matchesBaseDlc = true;
          } else if (baseFlag && !dlcFlag) {
            matchesBaseDlc = isBase;
          } else if (!baseFlag && dlcFlag) {
            matchesBaseDlc = isDlc;
          } else {
            matchesBaseDlc = true;
          }

          return gameMatch && nameMatch && propertyMatch && matchesBaseDlc;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, bottomPadding),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final ash = filtered[index];
            final isExpanded = _expandedId == ash.id;

            // ✅ 추가: 현재 아이템의 gif 표시 여부
            final bool showGif = _gifExpandedId == ash.id;

            // 설명을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(ash.description);

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
                  // ✅ 기존 확장/축소 로직 유지 + 접을 때 gif도 같이 닫기만 추가
                  _expandedId = isExpanded ? null : ash.id;

                  if (isExpanded) {
                    if (_gifExpandedId == ash.id) {
                      _gifExpandedId = null;
                    }
                  } else {
                    _gifExpandedId = null;
                  }
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
                              context,
                              ash.img,
                              ash.title,
                            ),
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
                              padding: const EdgeInsets.only(right: 12.0),
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
                                  Row(
                                    children: [
                                      Text(
                                        ash.property, // 속성
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
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
                            const Divider(
                              color: Colors.white24,
                              height: 1,
                              thickness: 0.5,
                            ),
                            const SizedBox(height: 10),

                            // 설명: 문장별로 나눠서 한 줄씩 + 줄마다 SizedBox
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final line in descriptionLines)
                                  if (line.trim().isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
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

                            const SizedBox(height: 12),

                            // ✅ 추가: '시전 모션 보기' 버튼
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gifExpandedId = showGif ? null : ash.id;
                                });
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
                                    '시전 모션 보기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ✅ 추가: JSON에 들어있는 gif URL(예: ash.gif)을 Image.network로 표시
                            if (showGif) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  ash.gif, // ✅ EAsh에 실제로 있는 gif 필드명으로 맞추세요
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
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