// lib/pages/egesture_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'egesture.dart';
import 'game.dart';

/// 🔥 EGesture 전역 캐시 (이 파일 안에서만 사용)
List<EGesture>? _eGestureCache;

/// 제스처(EGesture) 아이템 목록 페이지
class EGestureListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔥 본편 / DLC 필터
  final bool filterBase; // 본편
  final bool filterDlc;  // DLC (이름에 ◇)

  const EGestureListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    this.filterBase = false,
    this.filterDlc = false,
  });

  @override
  State<EGestureListPage> createState() => _EGestureListPageState();
}

class _EGestureListPageState extends State<EGestureListPage> {
  late Future<List<EGesture>> _futureEGestures;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureEGestures = fetchEGestures();
  }

  Future<List<EGesture>> fetchEGestures() async {
    // ⭐ 1) 캐시가 이미 있으면 API 호출 안 하고 바로 반환
    if (_eGestureCache != null) {
      return _eGestureCache!;
    }

    // 서버 제스처 목록 엔드포인트
    final response = await http.get(Uri.parse('$apiBaseUrl/EGesture'));

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<EGesture> data =
      body.map((dynamic item) => EGesture.fromJson(item)).toList();

      // ⭐ 2) 처음 불러온 데이터를 캐시에 저장
      _eGestureCache = data;
      return data;
    } else {
      throw Exception('제스처 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  /// description 파싱 (EBone과 비슷하게 문장 단위로 나누기)
  List<String> _splitDescriptionWithParens(String text) {
    final List<String> result = [];
    final StringBuffer buf = StringBuffer();
    int i = 0;
    final int len = text.length;

    while (i < len) {
      final String ch = text[i];
      buf.write(ch);

      if (ch == '.') {
        int j = i + 1;
        while (j < len && text[j] == ' ') {
          j++;
        }

        if (j < len && text[j] == '(') {
          while (i + 1 < len && i + 1 <= j) {
            i++;
            buf.write(text[i]);
          }

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
          final line = buf.toString().trim();
          if (line.isNotEmpty) {
            result.add(line);
          }
          buf.clear();
        }
      }

      i++;
    }

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

    return FutureBuilder<List<EGesture>>(
      future: _futureEGestures,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '에러 발생: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final items = snapshot.data ?? [];

        // 게임 이름 + 검색어 + 본편/DLC 필터링
        final filtered = items.where((g) {
          final bool gameMatch = g.game == widget.game.title;
          final bool nameMatch = g.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          final String title = g.title;
          final bool isDlc = title.contains('◇');
          final bool isBase = !isDlc;

          final bool baseFlag = widget.filterBase;
          final bool dlcFlag = widget.filterDlc;

          bool matchesBaseDlc;

          if (baseFlag && dlcFlag) {
            matchesBaseDlc = true;
          } else if (baseFlag && !dlcFlag) {
            matchesBaseDlc = isBase;
          } else if (!baseFlag && dlcFlag) {
            matchesBaseDlc = isDlc;
          } else {
            matchesBaseDlc = true; // 둘 다 false → 제약 없음
          }

          return gameMatch && nameMatch && matchesBaseDlc;
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
            final gesture = filtered[index];
            final isExpanded = _expandedId == gesture.id;

            final List<String> descriptionLines =
            _splitDescriptionWithParens(gesture.description);

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
                  _expandedId = isExpanded ? null : gesture.id;
                }),
                child: Column(
                  children: [
                    SizedBox(
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 왼쪽 썸네일 이미지
                          GestureDetector(
                            onTap: () => widget.showImageDialog(
                              context,
                              gesture.img,
                              gesture.title,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                gesture.img,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 제목
                                  Text(
                                    gesture.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 확장 영역: 상세 설명
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
