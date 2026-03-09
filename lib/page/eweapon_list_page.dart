// lib/pages/eweapon_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../api_config.dart';
import '../DTO/eweapon.dart';
import '../DTO/game.dart';
import 'weapon_detail_page.dart';
import 'detail_image_view_page.dart';
import '../local_data/local_data_loader.dart';  // ✅ 로컬 JSON 로더 추가

/// 🔥 EWeapon 전역 캐시 (이 파일 안에서만 사용)
List<EWeapon>? _eWeaponCache;

// EWeaponListPage는 이제 무기 목록만 담당합니다.
class EWeaponListPage extends StatefulWidget {
  final Game game;
  final String searchQuery; // 검색어를 상위 위젯에서 받음
  final Function(BuildContext, String, String) showImageDialog; // 이미지 다이얼로그 콜백
  final Function(EWeapon) navigateToDetailViewer; // 상세 뷰어 콜백

  // 🔹 상위/하위 필터 값
  final String genreFilter; // 소형 무기 / 대형 무기 / 원거리 무기 / 촉매 / 방패 ...
  final String subTypeFilter; // 단검 / 직검 / 대검 ...

  // 🔥 새 추가 필터들 (강화 방식 / DLC / 전설 / 본편)
  final bool filterNormalEnhance;   // 일반 강화
  final bool filterSpecialEnhance;  // 특수 강화
  final bool filterLegend;          // 전설 무기
  final bool filterBase;            // 본편 무기
  final bool filterDlc;             // DLC 무기

  const EWeaponListPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.showImageDialog,
    required this.navigateToDetailViewer,
    required this.genreFilter,
    required this.subTypeFilter,
    this.filterNormalEnhance = false,
    this.filterSpecialEnhance = false,
    this.filterLegend = false,
    this.filterBase = true,
    this.filterDlc = false,
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
    // ✅ 이제는 서버가 아니라 로컬 JSON(assets)에서 로드
    _futureEWeapons = fetchEWeapons();
  }

  // 🔥 지금부터는 오프라인(assets)에서 로드하는 버전
  Future<List<EWeapon>> fetchEWeapons() async {
    // 오프라인 모드: assets/data/elden_weapons_v1.json에서 로드
    return LocalDataLoader.loadWeapons();

    /*
    // ✅ [기존 서버에서 받아오던 코드] — 나중에 다시 쓸 수 있게 아예 남겨둠

    Future<List<EWeapon>> fetchEWeapons() async {
      // 🔥 1) 이미 캐시가 있으면 API 호출 없이 바로 사용
      if (_eWeaponCache != null) {
        return _eWeaponCache!;
      }

      final response = await http.get(Uri.parse('$apiBaseUrl/EWeapon'));
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        final List<EWeapon> data =
            body.map((dynamic item) => EWeapon.fromJson(item)).toList();

        // 🔥 2) 첫 로딩 결과를 캐시에 저장
        _eWeaponCache = data;
        return data;
      } else {
        throw Exception('무기 데이터를 불러오는 데 실패했습니다: ${response.statusCode}');
      }
    }
    */
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

    print('screen width = $screenWidth, height = $screenHeight');

    return FutureBuilder<List<EWeapon>>(
      future: _futureEWeapons,
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

        final filteredWeapons = snapshot.data
            ?.where((weapon) {
          final bool gameMatch = weapon.game == widget.game.title;
          final bool nameMatch = weapon.title
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase());

          // 🔹 상위 필터(genre: 소형 무기 / 대형 무기 …)
          final String currentGenreFilter = widget.genreFilter;
          final bool genreMatch = (currentGenreFilter == '전체')
              ? true
              : (weapon.genre == currentGenreFilter);

          // 🔹 하위 필터(type: 단검 / 직검 / 대검 …)
          final String currentSubFilter = widget.subTypeFilter;
          final bool subMatch = (currentSubFilter == '전체')
              ? true
              : (weapon.type == currentSubFilter);

          // ============================
          // 🔥 새 필터 로직 (강화 / 전설 / 본편 / DLC)
          // ============================
          final String title = weapon.title;

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
            // 일반 강화만
              matchesEnhance = isNormalEnhance;
              break;
            case 'special':
            // 특수 강화만
              matchesEnhance = isSpecialEnhance;
              break;
            case 'legend':
            // 전설 무기만 (☆)
              matchesEnhance = isLegend;
              break;
            case 'none':
            default:
              matchesEnhance = true; // 강화 필터 안 쓰면 무시
          }

          // 2) 본편 / DLC 필터 매칭
          final bool baseFlag = widget.filterBase;
          final bool dlcFlag = widget.filterDlc;

          bool matchesBaseDlc = true;

          // - 본편 / DLC 버튼 둘 다 꺼져 있으면 → 제약 없음 (둘 다 허용)
          // - 본편만 켜져 있으면 → 본편만
          // - DLC만 켜져 있으면 → DLC만
          // - 둘 다 켜져 있으면 → 둘 다 허용
          if (baseFlag && dlcFlag) {
            matchesBaseDlc = true;
          } else if (baseFlag && !dlcFlag) {
            matchesBaseDlc = isBase;
          } else if (!baseFlag && dlcFlag) {
            matchesBaseDlc = isDlc;
          } else {
            matchesBaseDlc = true; // 둘 다 false → 제약 없음
          }

          // 최종
          return gameMatch &&
              nameMatch &&
              genreMatch &&
              subMatch &&
              matchesEnhance &&
              matchesBaseDlc;
        })
            .toList() ??
            [];

        if (filteredWeapons.isEmpty) {
          return const Center(
            child: Text('항목이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, bottomPadding),
          itemCount: filteredWeapons.length,
          itemBuilder: (context, index) {
            final weapon = filteredWeapons[index];
            final isExpanded = _expandedId == weapon.id;

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
                      height: screenHeight * 0.1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => widget.showImageDialog(
                              context,
                              weapon.img,
                              weapon.title,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: screenWidth * 0.25,
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                weapon.img,
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
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: Text(
                                          '|',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        weapon.genre,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          // 댓글 버튼은 주석 처리 유지
                          /*
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 12.0, right: 16.0),
                            child: GestureDetector(
                              onTap: () => widget.navigateToDetailViewer(weapon),
                              behavior: HitTestBehavior.translucent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/comment.png',
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
                          */
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
                            GestureDetector(
                              // 전에 무기 상세 이미지 보여주던 코드
                              /*
                              onTap: () {
                                if (weapon.img2.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailImageViewerPage(
                                            imageUrl: weapon.img2,
                                            title: weapon.title,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('상세 이미지가 없습니다.'),
                                    ),
                                  );
                                }
                              },
                              */
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeaponDetailPage(
                                      weaponTitle: weapon.title,
                                      weaponImage: weapon.img,
                                    ),
                                  ),
                                );
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
                                    '상세 정보 보기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
