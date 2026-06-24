// lib/pages/list_Top.dart (검색창 내부 필터 아이콘 + 바텀시트 + 필터 타이틀 앞 대표 이미지)

import 'package:flutter/material.dart';
import 'package:forspeech/page/eweapon_list_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:forspeech/api_config.dart';
import 'package:forspeech/DTO/eweapon.dart';
import 'package:forspeech/DTO/game.dart';
import 'package:forspeech/page/detail_view_page.dart';
import 'package:forspeech/page/detail_image_view_page.dart';

import 'package:forspeech/DTO/earmor.dart';
import 'package:forspeech/page/earmor_list_page.dart';

import 'package:forspeech/DTO/eash.dart';
import 'package:forspeech/page/eash_list_page.dart';

import 'package:forspeech/DTO/espell.dart';
import 'package:forspeech/page/espell_list_page.dart';

import 'page/ebone_list_page.dart';
import 'page/eetc_list_page.dart';
import 'page/etalisman_list_page.dart';
import 'page/map_page.dart';

// ⭐ 제스처 리스트 페이지
import 'page/egesture_list_page.dart';

// ✅ 업데이트 알림용 추가 import
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:forspeech/app_version_info.dart';
import 'package:forspeech/update_service.dart';

// 웨폰 리스트 페이지 위의 이름/검색창/필터?
class ListTop extends StatefulWidget {
  final Game game;

  const ListTop({super.key, required this.game});

  @override
  State<ListTop> createState() => _ListTopState();
}

class _ListTopState extends State<ListTop> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  final ScrollController _tabScrollController = ScrollController();

  // 🔥 검색창 포커스 제어용 FocusNode 추가
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  int _selectedIndex = 0; // 0: 무기, 1: 방어구, 2: 전투 기술, ...

  // ✅ 업데이트 알림용 상태 추가
  bool _showUpdateNotice = false;
  AppVersionInfo? _versionInfo;

  // 🔹 무기 전용 2단계 필터
  String _weaponMainFilter = '전체'; // 소형 무기 / 대형 무기 / 원거리 무기 / 촉매 / 방패 ...
  String _weaponSubFilter = '전체'; // 단검 / 직검 / 대검 ... (상위 선택에 따라 달라짐)

  // 🔹 방어구 전용 부위 필터 (머리 / 몸통 / 손 / 다리 등)
  String _armorPartFilter = '전체';

  // 🔹 전투 기술(EAsh) 전용 속성 필터
  String _ashPropertyFilter = '전체';

  // 🔹 기타(EEtc) 전용 타입 필터
  String _etcTypeFilter = '전체';

  // 🔥 무기 전용 추가 필터 (강화 방식 / DLC / 전설 / 본편)
  bool _weaponFilterNormalEnhance = false; // 일반 강화
  bool _weaponFilterSpecialEnhance = false; // 특수 강화
  bool _weaponFilterLegend = false; // 전설 무기
  bool _weaponFilterBase = false; // 본편 무기 (기본: 선택 안 됨)
  bool _weaponFilterDlc = false; // DLC 무기 (기본: 선택 안 됨)

  // 🔥 방어구 전용 본편 / DLC 필터
  bool _armorFilterBase = false; // 본편 방어구
  bool _armorFilterDlc = false; // DLC 방어구

  // 🔥 전투 기술 전용 본편 / DLC 필터
  bool _ashFilterBase = false; // 본편 전투 기술
  bool _ashFilterDlc = false; // DLC 전투 기술

  // 🔥 주문(ESpell) 전용 본편 / DLC + 전설 필터
  bool _spellFilterBase = false; // 본편 주문
  bool _spellFilterDlc = false; // DLC 주문
  bool _spellFilterLegend = false; // 전설 주문

  // 🔥 주문(ESpell) 전용 "기존 필터" (spell / type)
  // - spellKindFilter: "전체 / 마술 / 기도" 중 하나
  // - spellTypeFilter: "전체 / (선택된 종류에 따라 변화하는 type)" 중 하나
  String _spellKindFilter = '전체';
  String _spellTypeFilter = '전체';

  // 🔥 탈리스만(ETalisman) 전용 본편 / DLC 필터
  bool _talismanFilterBase = false; // 본편 탈리스만
  bool _talismanFilterDlc = false; // DLC 탈리스만
  bool _talismanFilterLegend = false;

  // 🔥 뼛가루(EBone) 전용 필터 (일반/특수/전설 + 본편/DLC)
  bool _boneFilterNormalEnhance = false;
  bool _boneFilterSpecialEnhance = false;
  bool _boneFilterLegend = false;
  bool _boneFilterBase = false;
  bool _boneFilterDlc = false;

  // 🔥 기타(EEtc) 전용 본편 / DLC 필터
  bool _etcFilterBase = false;
  bool _etcFilterDlc = false;

  // 🔥 제스처(EGesture) 전용 본편 / DLC 필터
  bool _gestureFilterBase = false;
  bool _gestureFilterDlc = false;

  Set<String> _enabledMapMarkerCategories = {
    ...MapMarkerData.defaultCategoryKeys,
  };
  Set<String> _enabledMapMarkerDetailKeys = <String>{};
  String _selectedMapRegion = 'surface';

  @override
  void initState() {
    super.initState();
    _selectedIndex = _pageController.initialPage;

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    /*
    // ✅ 화면이 그려진 뒤 업데이트 알림 확인
    // 현재는 서버가 없어서 주석처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateNotice();
    });

    */
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    _searchFocusNode.dispose(); // 🔥 FocusNode도 잊지 말고 해제 (메모리 누수 방지)
    super.dispose();
  }

  // ✅ 업데이트 알림 체크
  Future<void> _checkUpdateNotice() async {
    final versionInfo = await UpdateService.fetchVersionInfo();
    if (versionInfo == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString('skip_version');

    // 이미 다시 보지 않기 누른 버전이면 종료
    if (skippedVersion == versionInfo.latestVersion) {
      return;
    }

    // 서버 버전이 현재 앱 버전보다 높을 때만 표시
    if (_isNewerVersion(versionInfo.latestVersion, currentVersion)) {
      if (!mounted) return;
      setState(() {
        _versionInfo = versionInfo;
        _showUpdateNotice = true;
      });
    }
  }

  // ✅ 버전 비교 함수
  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    final maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    while (latestParts.length < maxLength) {
      latestParts.add(0);
    }
    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    return false;
  }

  // ✅ 작은 업데이트 알림 박스
  Widget _buildUpdateNoticeBox() {
    if (_versionInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 33, 33, 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amberAccent.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.system_update_alt,
                color: Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _versionInfo!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _showUpdateNotice = false;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _versionInfo!.message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                    'skip_version',
                    _versionInfo!.latestVersion,
                  );

                  if (!mounted) return;
                  setState(() {
                    _showUpdateNotice = false;
                  });
                },
                child: const Text('다시 보지 않기', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(_versionInfo!.storeUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(72, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  '업데이트',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ 선택된 카테고리가 항상 화면 안에 들어오도록 스크롤
  void _scrollToCategory(int index) {
    if (!_tabScrollController.hasClients) return;

    const double itemWidth = 58.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    final int visualIndex = index == 8 ? 0 : index + 1;
    double targetOffset =
        itemWidth * visualIndex - (screenWidth - itemWidth) / 2;

    if (targetOffset < 0) targetOffset = 0;

    final maxScroll = _tabScrollController.position.maxScrollExtent;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    _tabScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  // 이미지 다이얼로그
  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상세 이미지가 없습니다.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/background.png', fit: BoxFit.fill),
                  Center(
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetailViewer(dynamic item) {
    if (item is EWeapon) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailViewerPage(weapon: item)),
      );
    }
  }

  // 🔹 현재 탭에 "기존 필터"(리스트 필터)가 있는지 여부
  bool _hasFilterForCurrentTab() {
    return _selectedIndex == 0 || // 무기
        _selectedIndex == 1 || // 방어구
        _selectedIndex == 2 || // 전투 기술(EAsh)
        _selectedIndex == 3 || // 주문(ESpell) spell/type 필터
        _selectedIndex == 6 || // 기타(EEtc) 타입 필터
        _selectedIndex == 8; // 지도 마커 필터
    // ⭐ 뼛가루(index 5), 제스처(index 7)는 "추가 필터"만 있음
  }

  // 🔹 현재 탭에서 "기존 필터"가 활성화 상태인지
  bool _isFilterActiveForCurrentTab() {
    switch (_selectedIndex) {
      case 0: // 무기: 상위/하위 둘 중 하나라도 전체가 아니면 활성화
        return _weaponMainFilter != '전체' || _weaponSubFilter != '전체';
      case 1:
        return _armorPartFilter != '전체';
      case 2:
        return _ashPropertyFilter != '전체';
      case 3:
        return _spellKindFilter != '전체' || _spellTypeFilter != '전체';
      case 6:
        return _etcTypeFilter != '전체';
      case 8:
        return _isMapDetailFilterActive();
      default:
        return false;
    }
  }

  // 🔥 무기 전용 추가 필터 활성 상태인지 (강화/DLC/전설/본편)
  bool _isWeaponExtraFilterActive() {
    return _weaponFilterNormalEnhance ||
        _weaponFilterSpecialEnhance ||
        _weaponFilterLegend ||
        _weaponFilterBase ||
        _weaponFilterDlc;
  }

  // 🔥 방어구 추가 필터 활성 상태인지 (본편/DLC)
  bool _isArmorExtraFilterActive() {
    return _armorFilterBase || _armorFilterDlc;
  }

  // 🔥 전투 기술 추가 필터 활성 상태인지 (본편/DLC)
  bool _isAshExtraFilterActive() {
    return _ashFilterBase || _ashFilterDlc;
  }

  // 🔥 주문(ESpell) 추가 필터 활성 상태인지 (본편/DLC + 전설)
  bool _isSpellExtraFilterActive() {
    return _spellFilterBase || _spellFilterDlc || _spellFilterLegend;
  }

  // 🔥 탈리스만(ETalisman) 추가 필터 활성 상태인지 (본편/DLC)
  bool _isTalismanExtraFilterActive() {
    return _talismanFilterBase || _talismanFilterDlc || _talismanFilterLegend;
  }

  // 🔥 뼛가루(EBone) 추가 필터 활성 상태인지
  bool _isBoneExtraFilterActive() {
    return _boneFilterNormalEnhance ||
        _boneFilterSpecialEnhance ||
        _boneFilterLegend ||
        _boneFilterBase ||
        _boneFilterDlc;
  }

  // 🔥 기타(EEtc) 추가 필터 활성 상태인지 (본편/DLC)
  bool _isEtcExtraFilterActive() {
    return _etcFilterBase || _etcFilterDlc;
  }

  // 🔥 제스처(EGesture) 추가 필터 활성 상태인지 (본편/DLC)
  bool _isGestureExtraFilterActive() {
    return _gestureFilterBase || _gestureFilterDlc;
  }

  bool _isMapDetailFilterActive() {
    return _enabledMapMarkerDetailKeys.length !=
        MapMarkerData.defaultDetailKeys.length;
  }

  bool _isMapRegionFilterActive() {
    return _selectedMapRegion != 'surface';
  }

  String _mapRegionLabel(String region) {
    switch (region) {
      case 'dlc':
        return 'DLC';
      case 'underground':
        return '지하';
      default:
        return '지상';
    }
  }

  String _extraFilterTooltip() {
    switch (_selectedIndex) {
      case 0:
        return '무기 강화/본편/DLC/전설 필터';
      case 1:
        return '방어구 본편/DLC 필터';
      case 2:
        return '전회 본편/DLC 필터';
      case 3:
        return '주문 전설/본편/DLC 필터';
      case 4:
        return '탈리스만 필터';
      case 5:
        return '뼛가루 필터';
      case 6:
        return '기타 아이템 본편/DLC 필터';
      case 7:
        return '제스처 필터';
      case 8:
        return '맵 선택: ${_mapRegionLabel(_selectedMapRegion)}';
      default:
        return '추가 필터 없음';
    }
  }

  VoidCallback? _extraFilterAction() {
    switch (_selectedIndex) {
      case 0:
        return _openWeaponExtraFilterSheet;
      case 1:
        return _openArmorExtraFilterSheet;
      case 2:
        return _openAshExtraFilterSheet;
      case 3:
        return _openSpellExtraFilterSheet;
      case 4:
        return _openTalismanExtraFilterSheet;
      case 5:
        return _openBoneExtraFilterSheet;
      case 6:
        return _openEtcExtraFilterSheet;
      case 7:
        return _openGestureExtraFilterSheet;
      case 8:
        return _openMapRegionSheet;
      default:
        return null;
    }
  }

  // 🔹 공용 필터 선택 바텀시트 열기 (기존: 무기/방어구/전투기술/기타 타입 필터)
  void _openFilterSheet() {
    if (_selectedIndex == 8) {
      _openMapDetailFilterSheet();
      return;
    }

    if (_selectedIndex == 0) {
      _openWeaponFilterSheet();
      return;
    }

    if (_selectedIndex == 3) {
      _openSpellFilterSheet();
      return;
    }

    if (!_hasFilterForCurrentTab()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이 카테고리는 아직 필터가 없습니다.')));
      return;
    }

    late List<String> options;
    late String currentValue;
    String title = '필터 선택';
    String? iconAsset;

    switch (_selectedIndex) {
      case 1:
        title = '방어구 필터';
        iconAsset = 'assets/images/armor_Icon.png';
        options = const ['전체', '투구', '갑옷', '장갑', '각반'];
        currentValue = _armorPartFilter;
        break;
      case 2:
        title = '전회 필터';
        iconAsset = 'assets/images/ash_Icon.png';
        options = const [
          '전체',
          '중후',
          '예리',
          '상질',
          '마력',
          '화염',
          '화염술',
          '벼락',
          '신성',
          '독',
          '피',
          '냉기',
          '신비',
          '전용 전투 기술',
          '없음',
        ];
        currentValue = _ashPropertyFilter;
        break;
      case 6:
        title = '기타 아이템 필터';
        iconAsset = 'assets/images/etc_Icon.png';
        options = const [
          '전체',
          '재사용 아이템',
          '소비',
          '투척 항아리',
          '조향병',
          '투척 아이템',
          '기름',
          '기타 아이템',
          '기타 사용 아이템',
          '퀘스트 관련 아이템',
          '룬',
          '추억',
          '협력 아이템',
          '제작 재료',
          '강화 재료',
          '거대한 룬',
          '영약 물방울',
          '그릇',
          '슬롯 증가 아이템',
          '수복 룬',
          '열쇠',
          'NPC 퀘스트 관련 아이템',
          '제작',
          '숫돌',
          '지도 조각',
          '스크롤',
          '기도서',
        ];
        currentValue = _etcTypeFilter;
        break;
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    if (iconAsset != null) ...[
                      Image.asset(
                        iconAsset!,
                        width: 22,
                        height: 22,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              color: Colors.white70,
                              size: 22,
                            ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          switch (_selectedIndex) {
                            case 1:
                              _armorPartFilter = '전체';
                              break;
                            case 2:
                              _ashPropertyFilter = '전체';
                              break;
                            case 6:
                              _etcTypeFilter = '전체';
                              break;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '초기화',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final bool isSelected = option == currentValue;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          switch (_selectedIndex) {
                            case 1:
                              _armorPartFilter = option;
                              break;
                            case 2:
                              _ashPropertyFilter = option;
                              break;
                            case 6:
                              _etcTypeFilter = option;
                              break;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.grey[800]
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Colors.amberAccent,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMapRegionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(33, 33, 33, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      '맵 선택',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              for (final region in const ['surface', 'underground', 'dlc'])
                RadioListTile<String>(
                  value: region,
                  groupValue: _selectedMapRegion,
                  activeColor: Colors.amberAccent,
                  title: Text(
                    _mapRegionLabel(region),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedMapRegion = value;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _openMapDetailFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(33, 33, 33, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        var tempEnabled = {..._enabledMapMarkerDetailKeys};
        final maxHeight = MediaQuery.of(context).size.height * 0.75;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '지도 필터',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempEnabled = {
                                  ...MapMarkerData.defaultDetailKeys,
                                };
                              });
                              setState(() {
                                _enabledMapMarkerDetailKeys = {
                                  ...MapMarkerData.defaultDetailKeys,
                                };
                              });
                            },
                            child: const Text(
                              '전체',
                              style: TextStyle(color: Colors.amberAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempEnabled = <String>{};
                              });
                              setState(() {
                                _enabledMapMarkerDetailKeys = <String>{};
                              });
                            },
                            child: const Text(
                              '끄기',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final group in MapMarkerData.detailGroups) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.title,
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        tempEnabled.addAll(group.keys);
                                      });
                                      setState(() {
                                        _enabledMapMarkerDetailKeys = {
                                          ...tempEnabled,
                                        };
                                      });
                                    },
                                    child: const Text(
                                      '전체',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        tempEnabled.removeAll(group.keys);
                                      });
                                      setState(() {
                                        _enabledMapMarkerDetailKeys = {
                                          ...tempEnabled,
                                        };
                                      });
                                    },
                                    child: const Text(
                                      '끄기',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final detailKey in group.keys)
                              CheckboxListTile(
                                value: tempEnabled.contains(detailKey),
                                onChanged: (v) {
                                  final checked = v ?? false;
                                  setModalState(() {
                                    if (checked) {
                                      tempEnabled.add(detailKey);
                                    } else {
                                      tempEnabled.remove(detailKey);
                                    }
                                  });
                                  setState(() {
                                    _enabledMapMarkerDetailKeys = {
                                      ...tempEnabled,
                                    };
                                  });
                                },
                                activeColor: Colors.amberAccent,
                                checkColor: Colors.black,
                                dense: true,
                                title: Text(
                                  MapMarkerData.detailDisplayLabel(detailKey),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
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

  Widget? _buildMapFilterIcon(String categoryKey) {
    final iconAsset = MapMarkerData.categoryIconAsset(categoryKey);
    if (iconAsset == null) return null;

    return Image.asset(iconAsset, width: 20, height: 20, fit: BoxFit.contain);
  }

  void _openSpellFilterSheet() {
    if (_selectedIndex != 3) return;

    const String magicKind = '마술';
    const String prayerKind = '기도';

    const Map<String, List<String>> spellTypeOptionsByKind = {
      magicKind: [
        '전체',
        '레아 루카리아 학원의 휘석',
        '카리아 왕가의 휘석',
        '밤',
        '용암',
        '얼음',
        '결정인',
        '중력',
        '손가락',
        '거품',
        '가시',
        '죽음',
      ],
      prayerKind: [
        '전체',
        '두 손가락',
        '황금 나무 신앙',
        '옛 황금 나무',
        '황금률 원리주의',
        '미켈라',
        '도읍 고룡신앙',
        '불',
        '메스메르의 불',
        '신 사냥',
        '짐승',
        '웅찬',
        '혈맹',
        '부패',
        '미친 불',
        '용찬',
        '나선',
        '수호령',
        '신조',
        '신수',
      ],
      '전체': [
        '전체',
        '두 손가락',
        '황금 나무 신앙',
        '옛 황금 나무',
        '황금률 원리주의',
        '미켈라',
        '도읍 고룡신앙',
        '불',
        '메스메르의 불',
        '신 사냥',
        '짐승',
        '웅찬',
        '혈맹',
        '부패',
        '미친 불',
        '용찬',
        '나선',
        '수호령',
        '신조',
        '신수',
        '레아 루카리아 학원의 휘석',
        '카리아 왕가의 휘석',
        '밤',
        '용암',
        '얼음',
        '결정인',
        '중력',
        '손가락',
        '거품',
        '가시',
        '죽음',
      ],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String tempKind = _spellKindFilter;
        String tempType = _spellTypeFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> currentTypeList =
                spellTypeOptionsByKind[tempKind] ??
                spellTypeOptionsByKind['전체']!;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/ESpell_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '주문 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempKind = '전체';
                              tempType = '전체';
                            });
                            setState(() {
                              _spellKindFilter = '전체';
                              _spellTypeFilter = '전체';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '종류 선택',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          value: tempKind == magicKind,
                          onChanged: (v) {
                            final bool checked = v ?? false;
                            setModalState(() {
                              if (checked) {
                                tempKind = magicKind;
                                tempType = '전체';
                              } else {
                                tempKind = '전체';
                                tempType = '전체';
                              }
                            });
                            setState(() {
                              if (checked) {
                                _spellKindFilter = magicKind;
                                _spellTypeFilter = '전체';
                              } else {
                                _spellKindFilter = '전체';
                                _spellTypeFilter = '전체';
                              }
                            });
                          },
                          title: const Text(
                            magicKind,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.amberAccent,
                        ),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          value: tempKind == prayerKind,
                          onChanged: (v) {
                            final bool checked = v ?? false;
                            setModalState(() {
                              if (checked) {
                                tempKind = prayerKind;
                                tempType = '전체';
                              } else {
                                tempKind = '전체';
                                tempType = '전체';
                              }
                            });
                            setState(() {
                              if (checked) {
                                _spellKindFilter = prayerKind;
                                _spellTypeFilter = '전체';
                              } else {
                                _spellKindFilter = '전체';
                                _spellTypeFilter = '전체';
                              }
                            });
                          },
                          title: const Text(
                            prayerKind,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.amberAccent,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: currentTypeList.length,
                      itemBuilder: (context, index) {
                        final option = currentTypeList[index];
                        final bool isSelected = (tempType == option);

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempType = option;
                            });
                            setState(() {
                              _spellTypeFilter = option;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: isSelected
                                ? Colors.grey[800]
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    color: Colors.amberAccent,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openWeaponFilterSheet() {
    const List<String> mainOptions = [
      '전체',
      '소형 무기',
      '대형 무기',
      '원거리 무기',
      '촉매',
      '방패',
    ];

    const Map<String, List<String>> subOptions = {
      '소형 무기': [
        '단검',
        '직검',
        '자검',
        '곡검',
        '역수검',
        '도',
        '쌍날검',
        '도끼',
        '망치',
        '철퇴',
        '창',
        '채찍',
        '주먹',
        '격투',
        '손톱',
        '짐승 발톱',
        '조향병',
      ],
      '대형 무기': [
        '대검',
        '특대검',
        '대자검',
        '대곡검',
        '대도',
        '대형 도끼',
        '대형 망치',
        '특대형 무기',
        '대형 창',
        '도끼창',
        '낫',
      ],
      '원거리 무기': ['소형 활', '활', '대궁', '석궁', '발리스타'],
      '촉매': ['지팡이', '성인', '횃불'],
      '방패': ['소형 방패', '중형 방패', '대형 방패', '관통 방패'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String tempMain = _weaponMainFilter;
        String tempSub = _weaponSubFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> currentSubList = [];
            if (tempMain != '전체') {
              currentSubList = ['전체', ...(subOptions[tempMain] ?? [])];
            }

            final double maxHeight = MediaQuery.of(context).size.height * 0.6;

            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/weapon_Icon.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '무기 필터',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempMain = '전체';
                                tempSub = '전체';
                              });
                              setState(() {
                                _weaponMainFilter = '전체';
                                _weaponSubFilter = '전체';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              '초기화',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    if (tempMain != '전체' && currentSubList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: tempSub,
                              isExpanded: true,
                              dropdownColor: Colors.grey[900],
                              iconEnabledColor: Colors.white70,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              items: currentSubList
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          option,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setModalState(() {
                                  tempSub = value;
                                });
                                setState(() {
                                  _weaponMainFilter = tempMain;
                                  _weaponSubFilter = tempSub;
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: mainOptions.length,
                        itemBuilder: (context, index) {
                          final option = mainOptions[index];
                          final bool isSelected = option == tempMain;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                tempMain = option;
                                tempSub = '전체';
                              });
                              setState(() {
                                _weaponMainFilter = tempMain;
                                _weaponSubFilter = tempSub;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: isSelected
                                  ? Colors.grey[800]
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[300],
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check,
                                      color: Colors.amberAccent,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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

  void _openWeaponExtraFilterSheet() {
    if (_selectedIndex != 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempNormal = _weaponFilterNormalEnhance;
        bool tempSpecial = _weaponFilterSpecialEnhance;
        bool tempLegend = _weaponFilterLegend;
        bool tempBase = _weaponFilterBase;
        bool tempDlc = _weaponFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/weapon_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '무기 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempNormal = false;
                              tempSpecial = false;
                              tempLegend = false;
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _weaponFilterNormalEnhance = false;
                              _weaponFilterSpecialEnhance = false;
                              _weaponFilterLegend = false;
                              _weaponFilterBase = false;
                              _weaponFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempNormal,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempNormal = newValue;
                        if (newValue) {
                          tempSpecial = false;
                          tempLegend = false;
                        }
                      });
                      setState(() {
                        _weaponFilterNormalEnhance = newValue;
                        if (newValue) {
                          _weaponFilterSpecialEnhance = false;
                          _weaponFilterLegend = false;
                        }
                      });
                    },
                    title: const Text(
                      '일반 강화',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempSpecial,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempSpecial = newValue;
                        if (newValue) {
                          tempNormal = false;
                          tempLegend = false;
                        }
                      });
                      setState(() {
                        _weaponFilterSpecialEnhance = newValue;
                        if (newValue) {
                          _weaponFilterNormalEnhance = false;
                          _weaponFilterLegend = false;
                        }
                      });
                    },
                    title: const Text(
                      '특수 강화',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempLegend,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempLegend = newValue;
                        if (newValue) {
                          tempNormal = false;
                          tempSpecial = false;
                        }
                      });
                      setState(() {
                        _weaponFilterLegend = newValue;
                        if (newValue) {
                          _weaponFilterNormalEnhance = false;
                          _weaponFilterSpecialEnhance = false;
                        }
                      });
                    },
                    title: const Text(
                      '전설 무기',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _weaponFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _weaponFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openArmorExtraFilterSheet() {
    if (_selectedIndex != 1) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _armorFilterBase;
        bool tempDlc = _armorFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/armor_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '방어구 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _armorFilterBase = false;
                              _armorFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _armorFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _armorFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAshExtraFilterSheet() {
    if (_selectedIndex != 2) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _ashFilterBase;
        bool tempDlc = _ashFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/ash_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '전회 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _ashFilterBase = false;
                              _ashFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _ashFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _ashFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSpellExtraFilterSheet() {
    if (_selectedIndex != 3) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _spellFilterBase;
        bool tempDlc = _spellFilterDlc;
        bool tempLegend = _spellFilterLegend;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/ESpell_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '주문 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                              tempLegend = false;
                            });
                            setState(() {
                              _spellFilterBase = false;
                              _spellFilterDlc = false;
                              _spellFilterLegend = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempLegend,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempLegend = newValue;
                      });
                      setState(() {
                        _spellFilterLegend = newValue;
                      });
                    },
                    title: const Text(
                      '전설 주문만 보기',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _spellFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _spellFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openTalismanExtraFilterSheet() {
    if (_selectedIndex != 4) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _talismanFilterBase;
        bool tempDlc = _talismanFilterDlc;
        bool tempLegend = _talismanFilterLegend;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/ETalisman_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '탈리스만 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                              tempLegend = false;
                            });
                            setState(() {
                              _talismanFilterBase = false;
                              _talismanFilterDlc = false;
                              _talismanFilterLegend = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempLegend,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempLegend = newValue;
                      });
                      setState(() {
                        _talismanFilterLegend = newValue;
                      });
                    },
                    title: const Text(
                      '전설',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _talismanFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _talismanFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBoneExtraFilterSheet() {
    if (_selectedIndex != 5) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempNormal = _boneFilterNormalEnhance;
        bool tempSpecial = _boneFilterSpecialEnhance;
        bool tempLegend = _boneFilterLegend;
        bool tempBase = _boneFilterBase;
        bool tempDlc = _boneFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/ai_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '뼛가루 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempNormal = false;
                              tempSpecial = false;
                              tempLegend = false;
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _boneFilterNormalEnhance = false;
                              _boneFilterSpecialEnhance = false;
                              _boneFilterLegend = false;
                              _boneFilterBase = false;
                              _boneFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempNormal,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempNormal = newValue;
                        if (newValue) {
                          tempSpecial = false;
                          tempLegend = false;
                        }
                      });
                      setState(() {
                        _boneFilterNormalEnhance = newValue;
                        if (newValue) {
                          _boneFilterSpecialEnhance = false;
                          _boneFilterLegend = false;
                        }
                      });
                    },
                    title: const Text(
                      '일반 강화 뼛가루',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempSpecial,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempSpecial = newValue;
                        if (newValue) {
                          tempNormal = false;
                          tempLegend = false;
                        }
                      });
                      setState(() {
                        _boneFilterSpecialEnhance = newValue;
                        if (newValue) {
                          _boneFilterNormalEnhance = false;
                          _boneFilterLegend = false;
                        }
                      });
                    },
                    title: const Text(
                      '특수 강화 뼛가루',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempLegend,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempLegend = newValue;
                        if (newValue) {
                          tempNormal = false;
                          tempSpecial = false;
                        }
                      });
                      setState(() {
                        _boneFilterLegend = newValue;
                        if (newValue) {
                          _boneFilterNormalEnhance = false;
                          _boneFilterSpecialEnhance = false;
                        }
                      });
                    },
                    title: const Text(
                      '전설 뼛가루',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _boneFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _boneFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEtcExtraFilterSheet() {
    if (_selectedIndex != 6) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _etcFilterBase;
        bool tempDlc = _etcFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/etc_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '기타 아이템 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _etcFilterBase = false;
                              _etcFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _etcFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _etcFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openGestureExtraFilterSheet() {
    if (_selectedIndex != 7) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempBase = _gestureFilterBase;
        bool tempDlc = _gestureFilterDlc;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/EGesture_Icon.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '제스처 필터',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempBase = false;
                              tempDlc = false;
                            });
                            setState(() {
                              _gestureFilterBase = false;
                              _gestureFilterDlc = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '초기화',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  CheckboxListTile(
                    value: tempBase,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempBase = newValue;
                      });
                      setState(() {
                        _gestureFilterBase = newValue;
                      });
                    },
                    title: const Text(
                      '본편',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  CheckboxListTile(
                    value: tempDlc,
                    onChanged: (v) {
                      final bool newValue = v ?? false;
                      setModalState(() {
                        tempDlc = newValue;
                      });
                      setState(() {
                        _gestureFilterDlc = newValue;
                      });
                    },
                    title: const Text(
                      'DLC (◇)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _hasFilterForCurrentTab();
    final bool filterActive = _isFilterActiveForCurrentTab();

    final bool weaponExtraActive = _isWeaponExtraFilterActive();
    final bool armorExtraActive = _isArmorExtraFilterActive();
    final bool ashExtraActive = _isAshExtraFilterActive();
    final bool spellExtraActive = _isSpellExtraFilterActive();
    final bool talismanExtraActive = _isTalismanExtraFilterActive();
    final bool boneExtraActive = _isBoneExtraFilterActive();
    final bool etcExtraActive = _isEtcExtraFilterActive();
    final bool gestureExtraActive = _isGestureExtraFilterActive();

    final Color filterIconColor = !hasFilter
        ? Colors.grey[600]!
        : (filterActive ? Colors.amberAccent : Colors.grey[400]!);

    final Color extraFilterIconColor = switch (_selectedIndex) {
      0 => weaponExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      1 => armorExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      2 => ashExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      3 => spellExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      4 => talismanExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      5 => boneExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      6 => etcExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      7 => gestureExtraActive ? Colors.cyanAccent : Colors.grey[400]!,
      8 => _isMapRegionFilterActive() ? Colors.cyanAccent : Colors.grey[400]!,
      _ => Colors.grey[700]!,
    };

    final List<Widget> _pages = [
      EWeaponListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        navigateToDetailViewer: _navigateToDetailViewer,
        genreFilter: _weaponMainFilter,
        subTypeFilter: _weaponSubFilter,
        filterNormalEnhance: _weaponFilterNormalEnhance,
        filterSpecialEnhance: _weaponFilterSpecialEnhance,
        filterLegend: _weaponFilterLegend,
        filterBase: _weaponFilterBase,
        filterDlc: _weaponFilterDlc,
      ),
      EArmorListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        partFilter: _armorPartFilter,
        filterBase: _armorFilterBase,
        filterDlc: _armorFilterDlc,
      ),
      EAshListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        propertyFilter: _ashPropertyFilter,
        filterBase: _ashFilterBase,
        filterDlc: _ashFilterDlc,
      ),
      ESpellListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        filterBase: _spellFilterBase,
        filterDlc: _spellFilterDlc,
        filterLegend: _spellFilterLegend,
        spellKindFilter: _spellKindFilter,
        spellTypeFilter: _spellTypeFilter,
      ),
      ETalismanListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        filterBase: _talismanFilterBase,
        filterDlc: _talismanFilterDlc,
        filterLegend: _talismanFilterLegend,
      ),
      EBoneListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        filterNormalEnhance: _boneFilterNormalEnhance,
        filterSpecialEnhance: _boneFilterSpecialEnhance,
        filterLegend: _boneFilterLegend,
        filterBase: _boneFilterBase,
        filterDlc: _boneFilterDlc,
      ),
      EEtcListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        typeFilter: _etcTypeFilter,
        filterBase: _etcFilterBase,
        filterDlc: _etcFilterDlc,
      ),
      EGestureListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        filterBase: _gestureFilterBase,
        filterDlc: _gestureFilterDlc,
      ),
      MapPage(
        searchQuery: _searchQuery,
        enabledCategories: _enabledMapMarkerCategories,
        enabledDetailKeys: _enabledMapMarkerDetailKeys,
        selectedRegion: _selectedMapRegion,
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Image.asset(
                'assets/images/grace_Icon2.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            // ✅ 업데이트 알림 박스 추가
            if (_showUpdateNotice && _versionInfo != null)
              _buildUpdateNoticeBox(),

            // 🔹 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '아이템 이름으로 검색...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          color: Colors.white70,
                          tooltip: '검색어 지우기',
                          onPressed: () => _searchController.clear(),
                        ),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_outlined),
                        color: extraFilterIconColor,
                        tooltip: _extraFilterTooltip(),
                        onPressed: _extraFilterAction(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        color: filterIconColor,
                        tooltip: hasFilter ? '필터' : '필터 없음',
                        onPressed: hasFilter ? _openFilterSheet : null,
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: const Color.fromRGBO(33, 33, 33, 1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(
                horizontal: 3.0,
                vertical: 0.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _buildCategoryButton(
                    iconPath: 'assets/images/map_assets/map_Icon.png',
                    label: '맵',
                    index: 8,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/weapon_Icon.png',
                    label: '무기',
                    index: 0,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/armor_Icon.png',
                    label: '방어구',
                    index: 1,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/ash_Icon.png',
                    label: '전회',
                    index: 2,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/ESpell_Icon.png',
                    label: '마술,기도',
                    index: 3,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/ETalisman_Icon.png',
                    label: '탈리스만',
                    index: 4,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/ai_Icon.png',
                    label: '뼛가루',
                    index: 5,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/etc_Icon.png',
                    label: '기타',
                    index: 6,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                  _buildCategoryButton(
                    iconPath: 'assets/images/EGesture_Icon.png',
                    label: '제스처',
                    index: 7,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _searchController.clear();
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      _scrollToCategory(index);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: _selectedIndex == 8
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _scrollToCategory(index);
                },
                children: _pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공용 카테고리 버튼
Widget _buildCategoryButton({
  required String iconPath,
  required String label,
  required int index,
  required int currentIndex,
  required Function(int) onTap,
}) {
  final bool isSelected = index == currentIndex;

  return GestureDetector(
    onTap: () => onTap(index),
    child: Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.grey[700]!.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              color: isSelected ? Colors.white : Colors.white70,
              size: 40,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
