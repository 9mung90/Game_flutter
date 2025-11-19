// lib/pages/eetc_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'eetc.dart';
import 'game.dart';

/// 기타(EEtc) 아이템 목록 페이지
class EEtcListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔹 타입 필터 추가 (예: 소모품 / 키 아이템 / 제작 재료 등)
  final String typeFilter;

  const EEtcListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    this.typeFilter = '전체',          // 기본값: 전체
  });

  @override
  State<EEtcListPage> createState() => _EEtcListPageState();
}

class _EEtcListPageState extends State<EEtcListPage> {
  late Future<List<EEtc>> _futureEEtcs;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureEEtcs = fetchEEtcs();
  }

  Future<List<EEtc>> fetchEEtcs() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/EEtc'));

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => EEtc.fromJson(item)).toList();
    } else {
      throw Exception('기타 아이템(EEtc) 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
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

        // '.' 다음에 '(' 이면: 괄호 내용까지 같은 문장으로 묶기
        if (j < len && text[j] == '(') {
          // 사이 공백들까지 이미 buf에 들어와 있음
          // 이제 '(' 포함해서 ')'까지 읽어오기
          // j는 '(' 위치
          while (i + 1 < len && i + 1 <= j) {
            i++;
            buf.write(text[i]);
          }

          // 이제 ')' 나올 때까지 계속 읽기
          while (i + 1 < len) {
            i++;
            buf.write(text[i]);
            if (text[i] == ')') {
              break; // 여기서 한 문장 끝
            }
          }

          // 하나의 문장 완성
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

    // 마지막 버퍼에 남아 있는 내용 처리
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

    return FutureBuilder<List<EEtc>>(
      future: _futureEEtcs,
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

        // 게임 이름 + 검색어 + 타입 필터로 필터링
        final filtered = items
            .where((e) =>
        e.game == widget.game.title &&
            (widget.typeFilter == '전체' || e.type == widget.typeFilter) &&
            e.title.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              '항목이 없습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final etc = filtered[index];
            final isExpanded = _expandedId == etc.id;

            // ability가 비어있는지 체크 (null → '' 로 들어온 것도 걸러짐)
            final bool hasAbility = etc.ability.trim().isNotEmpty;

            // 새 규칙으로 description 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(etc.description);

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
                    _expandedId = isExpanded ? null : etc.id;
                  });
                },
                child: Column(
                  children: [
                    // 상단: 썸네일 + 제목 + 메타 정보
                    SizedBox(
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 왼쪽 썸네일
                          GestureDetector(
                            onTap: () =>
                                widget.showImageDialog(context, etc.img, etc.title),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                etc.img,
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
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 제목
                                  Text(
                                    etc.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // 메타 정보: 타입만 표시
                                  Text(
                                    etc.type,
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

                            // 설명: 문장마다 Text + SizedBox로 한 칸씩 띄우기
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

                            // 능력이 있을 때만: 2칸 띄우고 + 능력 내용
                            if (hasAbility) ...[
                              const SizedBox(height: 16),
                              Text(
                                etc.ability,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                  height: 1.4,
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
