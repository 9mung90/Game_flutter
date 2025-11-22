// lib/pages/list_Top.dart (검색창 내부 필터 아이콘 + 바텀시트 + 필터 타이틀 앞 대표 이미지)

import 'package:flutter/material.dart';
import 'package:forspeech/eweapon_list_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:forspeech/api_config.dart';
import 'package:forspeech/eweapon.dart';
import 'package:forspeech/game.dart';
import 'package:forspeech/detail_view_page.dart';
import 'package:forspeech/detail_image_view_page.dart';

import 'package:forspeech/earmor.dart';
import 'package:forspeech/earmor_list_page.dart';

import 'package:forspeech/eash.dart';
import 'package:forspeech/eash_list_page.dart';

import 'package:forspeech/espell.dart';
import 'package:forspeech/espell_list_page.dart';

import 'ebone_list_page.dart';
import 'eetc_list_page.dart';
import 'etalisman_list_page.dart';

// ⭐ 제스처 리스트 페이지 import
import 'egesture_list_page.dart';

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

  // 🔹 무기 전용 2단계 필터
  String _weaponMainFilter = '전체'; // 소형 무기 / 대형 무기 / 원거리 무기 / 촉매 / 방패 ...
  String _weaponSubFilter = '전체';  // 단검 / 직검 / 대검 ... (상위 선택에 따라 달라짐)

  // 🔹 방어구 전용 부위 필터 (머리 / 몸통 / 손 / 다리 등)
  String _armorPartFilter = '전체';

  // 🔹 전투 기술(EAsh) 전용 속성 필터
  String _ashPropertyFilter = '전체';

  // 🔹 기타(EEtc) 전용 타입 필터
  String _etcTypeFilter = '전체';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    _searchFocusNode
        .dispose(); // 🔥 FocusNode도 잊지 말고 해제 (메모리 누수 방지)
    super.dispose();
  }

  // ✅ 선택된 카테고리가 항상 화면 안에 들어오도록 스크롤
  void _scrollToCategory(int index) {
    if (!_tabScrollController.hasClients) return;

    const double itemWidth = 58.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    double targetOffset = itemWidth * index - (screenWidth - itemWidth) / 2;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 이미지가 없습니다.')),
      );
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
                  Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.fill,
                  ),
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
        MaterialPageRoute(
          builder: (context) => DetailViewerPage(
            weapon: item,
          ),
        ),
      );
    }
  }

  // 🔹 현재 탭에 필터가 있는지 여부
  bool _hasFilterForCurrentTab() {
    return _selectedIndex == 0 || // 무기
        _selectedIndex == 1 || // 방어구
        _selectedIndex == 2 || // 전투 기술(EAsh)
        _selectedIndex == 6; // 기타(EEtc)
    // ⭐ 제스처(index 7)는 필터 없음 → 여기 안 넣음
  }

  // 🔹 현재 탭에서 필터가 "전체"가 아닌지 → 아이콘 하이라이트용
  bool _isFilterActiveForCurrentTab() {
    switch (_selectedIndex) {
      case 0:
      // 무기: 상위/하위 둘 중 하나라도 전체가 아니면 활성화
        return _weaponMainFilter != '전체' || _weaponSubFilter != '전체';
      case 1:
        return _armorPartFilter != '전체';
      case 2:
        return _ashPropertyFilter != '전체';
      case 6:
        return _etcTypeFilter != '전체';
      default:
        return false;
    }
  }

  // 🔹 공용 필터 선택 바텀시트 열기
  void _openFilterSheet() {
    // 무기 탭이라면 2단계 필터 시트로 분기
    if (_selectedIndex == 0) {
      _openWeaponFilterSheet();
      return;
    }

    if (!_hasFilterForCurrentTab()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 카테고리는 아직 필터가 없습니다.')),
      );
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
        options = const [
          '전체',
          '투구',
          '갑옷',
          '장갑',
          '각반',
        ];
        currentValue = _armorPartFilter;
        break;
      case 2:
        title = '전투 기술 필터';
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
              // 제목 + 대표 아이콘
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
                        const Icon(Icons.broken_image,
                            color: Colors.white70, size: 22),
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

  // 🔥 무기 전용: 상위 / 하위 2단계 필터 시트
  void _openWeaponFilterSheet() {
    // 상위 분류(genre)
    const List<String> mainOptions = [
      '전체',
      '소형 무기',
      '대형 무기',
      '원거리 무기',
      '촉매',
      '방패',
    ];

    // 🔥 상위 분류별 하위 타입(type) 목록
    const Map<String, List<String>> subOptions = {
      '소형 무기': [
        '단검',
        '직검',
        '곡검',
        '채찍',
      ],
      '대형 무기': [
        '대검',
        '대형 곡검',
        '도끼',
        '도끼창',
        '망치',
      ],
      '원거리 무기': [
        '활',
        '대형 활',
        '석궁',
      ],
      '촉매': [
        '지팡이',
        '도장',
      ],
      '방패': [
        '소형 방패',
        '중형 방패',
        '대형 방패',
      ],
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
            // 현재 상위 선택에 따라 하위 리스트 구성
            List<String> currentSubList = [];
            if (tempMain != '전체') {
              currentSubList = [
                '전체',
                ...(subOptions[tempMain] ?? []),
              ];
            }

            final double maxHeight = MediaQuery.of(context).size.height * 0.6;

            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // 상단 타이틀 + 초기화
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/weapon_Icon.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                color: Colors.white70, size: 22),
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
                              // 상/하위 모두 초기화 + 부모 상태도 초기화
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

                    // 🔹 상단 바로 아래: 가로 꽉 차는, 세로 얇은 드롭다운
                    if (tempMain != '전체' && currentSubList.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Container(
                          height: 34, // 👈 세로 얇게
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1,
                            ),
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
                                        horizontal: 8.0),
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

                    // 🔹 상위 분류 리스트 (render overflow 방지를 위해 Expanded 사용)
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

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _hasFilterForCurrentTab();
    final bool filterActive = _isFilterActiveForCurrentTab();

    final Color filterIconColor = !hasFilter
        ? Colors.grey[600]!
        : (filterActive ? Colors.amberAccent : Colors.grey[400]!);

    // 각 카테고리별 콘텐츠 위젯 리스트
    final List<Widget> _pages = [
      EWeaponListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        navigateToDetailViewer: _navigateToDetailViewer,
        genreFilter: _weaponMainFilter,   // 상위 분류
        subTypeFilter: _weaponSubFilter,  // 하위 분류
      ),
      EArmorListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        partFilter: _armorPartFilter,
      ),
      EAshListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        propertyFilter: _ashPropertyFilter,
      ),
      ESpellListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
      ETalismanListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
      EBoneListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
      EEtcListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        typeFilter: _etcTypeFilter,
      ),
      // ⭐ 제스처 탭 페이지 (필터 없음)
      EGestureListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
    ];

    return WillPopScope(
      // 🔥 안드로이드 뒤로가기 버튼 눌렀을 때 처리
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          // 검색창에 포커스가 있으면 → 포커스만 해제하고, 페이지 뒤로가기는 막기
          _searchFocusNode.unfocus();
          return false; // pop 하지 않음
        }
        // 포커스 없으면 → 원래대로 뒤로가기 허용
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
            // 🔹 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode, // 🔥 여기 연결
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
                        icon: const Icon(Icons.filter_list),
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

            // 카테고리 버튼 줄
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                children: <Widget>[
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
                    label: '전투 기술',
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
                    label: '마술/기도',
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
                  // ⭐ 제스처 카테고리 버튼
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
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color:
        isSelected ? Colors.grey[700]!.withOpacity(0.5) : Colors.transparent,
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
