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

// 웨폰 리스트 페이지 위의 이름/검색창/필터?

class GameItemMasterPage extends StatefulWidget {
  final Game game;
  const GameItemMasterPage({super.key, required this.game});

  @override
  State<GameItemMasterPage> createState() => _GameItemMasterPageState();
}

class _GameItemMasterPageState extends State<GameItemMasterPage> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0); // ⭐ 추가

  String _searchQuery = '';
  int _selectedIndex = 0; // 0: 무기, 1: 방어구, 2: 전투 기술, 3: 기타

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
    _pageController.dispose(); // ⭐ 추가
    super.dispose();
  }

  // EWeaponListPage에서 가져왔던 공통 함수들을 여기에 정의합니다.
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

  @override
  Widget build(BuildContext context) {
    // 각 카테고리별 콘텐츠 위젯 리스트
    final List<Widget> _pages = [
      EWeaponListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        navigateToDetailViewer: _navigateToDetailViewer,
      ),
      EArmorListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
      EAshListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),
      ESpellListPage(
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
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.game.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '아이템 이름으로 검색...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
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
            margin: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 0.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView(
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
                      _searchController.clear(); // 카테고리 변경 시 검색창 초기화
                    });
                    _pageController.animateToPage( // ⭐ 스와이프 연동
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
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
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/use_Icon.png',
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
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/ai_Icon.png',
                  label: '뼛가루',
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
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/etc_Icon.png',
                  label: '기타',
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
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            // 🔁 기존 IndexedStack → PageView로 교체
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  // 스와이프로 바꿀 때 검색어 유지하고 싶으면 그대로 두고,
                  // 같이 지우고 싶으면 아래 주석 해제:
                  // _searchController.clear();
                });
              },
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

// _buildCategoryButton 위젯
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
        color: isSelected ? Colors.grey[700]!.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image, color: isSelected ? Colors.white : Colors.white70, size: 40),
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
