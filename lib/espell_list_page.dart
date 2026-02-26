// lib/pages/espell_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'espell.dart';
import 'game.dart';
import 'local_data/local_data_loader.dart'; // ⭐ 로컬 JSON 로더 추가

/// 🔥 ESpell 전역 캐시 (이 파일 안에서만 사용)
List<ESpell>? _eSpellCache;

/// 주문(Spell) 목록 페이지 (댓글/네비 제거 버전)
class ESpellListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔹 본편 / DLC 필터
  final bool filterBase; // 본편 주문 표시 여부
  final bool filterDlc; // DLC 주문 표시 여부

  // 🔥 전설 주문 필터 — 기본값 false
  final bool filterLegend;

  // 🔥 spell / type 필터 추가
  // - spellKindFilter: "전체 / 주문 / 기도 / 마술" 등
  // - spellTypeFilter: "전체 / 두 손가락 / 황금 나무 신앙" 등
  final String spellKindFilter;
  final String spellTypeFilter;

  const ESpellListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.filterBase,
    required this.filterDlc,
    this.filterLegend = false,
    this.spellKindFilter = '전체',
    this.spellTypeFilter = '전체',
  });

  @override
  State<ESpellListPage> createState() => _ESpellListPageState();
}

class _ESpellListPageState extends State<ESpellListPage> {
  late Future<List<ESpell>> _futureESpells;
  int? _expandedId; // 확장된 카드의 아이템 id

  // ✅ 추가: 시전 모션(gif) 표시 여부를 아이템 id로 관리
  int? _gifExpandedId;

  @override
  void initState() {
    super.initState();
    _futureESpells = fetchESpells();
  }

  Future<List<ESpell>> fetchESpells() async {
    // ✅ 지금은 로컬 JSON(assets/data/ESpellv1.json)을 사용해서 불러옴
    return LocalDataLoader.loadSpells();

    /*
    // 🔥 [이전 버전] 서버에서 주문 데이터를 받아오던 코드 (백업용으로 남겨둠)

    // 1) 이미 캐시가 있으면 API 호출 없이 바로 반환
    if (_eSpellCache != null) {
      return _eSpellCache!;
    }

    // 백엔드 라우트에 맞춰 조정: /ESpell (다르면 여기만 변경)
    final response = await http.get(Uri.parse('$apiBaseUrl/ESpell'));

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<ESpell> data =
          body.map((dynamic item) => ESpell.fromJson(item)).toList();

      // 2) 첫 로딩 결과를 캐시에 저장
      _eSpellCache = data;
      return data;
    } else {
      throw Exception(
          '주문(ESpell) 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
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

    return FutureBuilder<List<ESpell>>(
      future: _futureESpells,
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

        final items = snapshot.data ?? [];

        final filtered = items.where((s) {
          final bool gameMatch = s.game == widget.game.title;

          final bool nameMatch = s.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          // 🔹 DLC 여부: 이름에 '◇'가 있으면 DLC 주문으로 취급
          final bool isDlc = s.title.contains('◇');

          // 🔥 전설 여부:
          // - 무기처럼 '☆' 마크가 있거나
          // - type/title에 '전설' 이라는 단어가 들어가면 전설 주문으로 취급
          final bool isLegend = s.title.contains('☆') ||
              s.type.contains('전설') ||
              s.title.contains('전설');

          // 🔹 본편 / DLC 매칭
          bool baseDlcMatch;
          if (widget.filterBase && !widget.filterDlc) {
            // 본편만 보기
            baseDlcMatch = !isDlc;
          } else if (!widget.filterBase && widget.filterDlc) {
            // DLC만 보기
            baseDlcMatch = isDlc;
          } else {
            // 둘 다 true 이거나 둘 다 false -> 본편/DLC 모두 허용
            baseDlcMatch = true;
          }

          // 🔥 전설 필터: 켜져 있으면 전설 주문만 통과
          bool legendMatch = true;
          if (widget.filterLegend) {
            legendMatch = isLegend;
          }

          // 🔥 spellKindFilter: spell 컬럼 값으로 필터 (기도 / 주문 / 마술 ...)
          bool spellKindMatch = true;
          if (widget.spellKindFilter != '전체') {
            // ESpell 모델에 'spell' 필드가 있다고 가정
            spellKindMatch = s.spell == widget.spellKindFilter;
          }

          // 🔥 spellTypeFilter: type 컬럼 값으로 필터 (두 손가락, 황금 나무 신앙 ...)
          bool spellTypeMatch = true;
          if (widget.spellTypeFilter != '전체') {
            spellTypeMatch = s.type == widget.spellTypeFilter;
          }

          return gameMatch &&
              nameMatch &&
              baseDlcMatch &&
              legendMatch &&
              spellKindMatch &&
              spellTypeMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.',
                style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, bottomPadding),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final spell = filtered[index];
            final isExpanded = _expandedId == spell.id;

            // ✅ 추가: 현재 아이템의 gif 표시 여부
            final bool showGif = _gifExpandedId == spell.id;

            // 설명을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(spell.description);

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
                  _expandedId = isExpanded ? null : spell.id;

                  if (isExpanded) {
                    if (_gifExpandedId == spell.id) {
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
                                context, spell.img, spell.title),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                spell.img,
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
                                    spell.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // 주문의 핵심 메타: type | slot | need
                                  Wrap(
                                    crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        spell.type,
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        '요구 슬롯: ${spell.slot}',
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        '${spell.need}',
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

                            // 현재 임시로 주석처리함 나중에 활성화
                            // ✅ 추가: '시전 모션 보기' 버튼 (gif 토글)
                            /*
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gifExpandedId = showGif ? null : spell.id;
                                });
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/detailground.png'),
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
                            */
                            

                            // ✅ 추가: JSON에 들어있는 gif URL(예: spell.gif)을 Image.network로 표시
                            if (showGif) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  spell.gif, // ✅ ESpell에 실제로 있는 gif 필드명으로 맞추세요
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