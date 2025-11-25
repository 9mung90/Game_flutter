// lib/pages/ebone_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'ebone.dart';
import 'game.dart';

/// EBone 전역 캐시 (이 파일 안에서만 사용)
List<EBone>? _eBoneCache;

/// 뼈(EBone) 아이템 목록 페이지
class EBoneListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 상위에서 전달받는 검색어
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백

  // 🔥 무기와 동일한 추가 필터 (강화 방식 / DLC / 전설 / 본편)
  final bool filterNormalEnhance;   // 일반 강화
  final bool filterSpecialEnhance;  // 특수 강화
  final bool filterLegend;          // 전설 뼛가루
  final bool filterBase;            // 본편 뼛가루
  final bool filterDlc;             // DLC 뼛가루

  const EBoneListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    this.filterNormalEnhance = false,
    this.filterSpecialEnhance = false,
    this.filterLegend = false,
    this.filterBase = true,
    this.filterDlc = false,
  });

  @override
  State<EBoneListPage> createState() => _EBoneListPageState();
}

class _EBoneListPageState extends State<EBoneListPage> {
  late Future<List<EBone>> _futureEBones;
  int? _expandedId; // 확장된 카드의 아이템 id

  @override
  void initState() {
    super.initState();
    _futureEBones = fetchEBones();
  }

  Future<List<EBone>> fetchEBones() async {
    // 🔥 1) 캐시가 이미 있으면 API 호출 없이 바로 반환
    if (_eBoneCache != null) {
      return _eBoneCache!;
    }

    final response = await http.get(Uri.parse('$apiBaseUrl/EBone'));

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
      final List<EBone> data =
      body.map((dynamic item) => EBone.fromJson(item)).toList();

      // 🔥 2) 최초 한 번 로딩한 데이터를 캐시에 저장
      _eBoneCache = data;
      return data;
    } else {
      throw Exception('뼛가루 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
    }
  }

  /// description 파싱:
  /// 1) 기본적으로 '.'를 기준으로 문장 분리
  /// 2) 단, '.' 뒤의 첫 non-space 문자가 '(' 이면, ')' 나올 때까지 같은 줄로 묶고
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

    return FutureBuilder<List<EBone>>(
      future: _futureEBones,
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

        // ============================
        // 🔥 무기 페이지와 동일한 필터 로직
        //  1) 일반/특수/전설 뼛가루
        //  2) 본편 / DLC
        // ============================
        final filtered = items.where((b) {
          final bool gameMatch = b.game == widget.game.title;
          final bool nameMatch = b.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          final String title = b.title;

          // DLC / 전설 플래그
          final bool isDlc = title.contains('◇');
          final bool isLegend = title.contains('☆');
          final bool isBase = !isDlc;

          // 강화 방식 판별
          //  - '○' 포함 → 특수 강화
          //  - '○' 없음 → 일반 강화
          final bool hasCircle = title.contains('○');
          final bool isSpecialEnhance = hasCircle;
          final bool isNormalEnhance = !hasCircle;

          // 선택된 강화/전설 모드 (서로 배타적)
          String enhanceMode = 'none';
          if (widget.filterNormalEnhance) {
            enhanceMode = 'normal';
          } else if (widget.filterSpecialEnhance) {
            enhanceMode = 'special';
          } else if (widget.filterLegend) {
            enhanceMode = 'legend';
          }

          // 1) 강화/전설 필터 매칭
          bool matchesEnhance = true;
          switch (enhanceMode) {
            case 'normal':
              matchesEnhance = isNormalEnhance;
              break;
            case 'special':
              matchesEnhance = isSpecialEnhance;
              break;
            case 'legend':
              matchesEnhance = isLegend;
              break;
            case 'none':
            default:
              matchesEnhance = true; // 필터 안 쓰면 무시
          }

          // 2) 본편 / DLC 필터 매칭
          final bool baseFlag = widget.filterBase;
          final bool dlcFlag = widget.filterDlc;

          bool matchesBaseDlc = true;
          if (baseFlag && dlcFlag) {
            matchesBaseDlc = true; // 둘 다 ON → 둘 다 허용
          } else if (baseFlag && !dlcFlag) {
            matchesBaseDlc = isBase; // 본편만
          } else if (!baseFlag && dlcFlag) {
            matchesBaseDlc = isDlc; // DLC만
          } else {
            matchesBaseDlc = true; // 둘 다 OFF → 제약 없음
          }

          return gameMatch &&
              nameMatch &&
              matchesEnhance &&
              matchesBaseDlc;
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
            final bone = filtered[index];
            final isExpanded = _expandedId == bone.id;

            // bget에 내용이 있는지 체크 (null → '' 로 들어온 것도 걸러짐)
            final bool hasBget = bone.bget.trim().isNotEmpty;

            // description을 규칙에 맞게 분리
            final List<String> descriptionLines =
            _splitDescriptionWithParens(bone.description);

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
                  _expandedId = isExpanded ? null : bone.id;
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
                                context, bone.img, bone.title),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                bone.img,
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
                                    bone.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // 메타 정보: 용도만 위에 표시
                                  Wrap(
                                    crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '소비: ${bone.buse}',
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
                        ],
                      ),
                    ),
                    // 확장 영역: 설명 + (있다면) 획득
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

                            // 상세 설명: 문장별 Text + SizedBox로 한 칸씩
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                for (final line in descriptionLines)
                                  if (line.trim().isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0), // 👉 여기서 오른쪽으로 살짝 밀기
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

                            const SizedBox(height: 8),
                            const SizedBox(height: 8),

                            // --- bget이 있을 때만 표시 ---
                            if (hasBget)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0), // 👈 설명이랑 같은 들여쓰기
                                child: Text(
                                  bone.bget,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            // -------------------------------

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
