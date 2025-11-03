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


// 웨폰 리스트 페이지 위의 이름/검색창/필터?


class GameItemMasterPage extends StatefulWidget {
  final Game game;
  const GameItemMasterPage({super.key, required this.game});

  @override
  State<GameItemMasterPage> createState() => _GameItemMasterPageState();
}

class _GameItemMasterPageState extends State<GameItemMasterPage> {
  final TextEditingController _searchController = TextEditingController();
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
                            Icons.image_not_supported, color: Colors.white38, size: 48),
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

  // EWeapon 객체를 받도록 되어있으므로, 다른 타입의 아이템도 처리하려면 제네릭하게 수정하거나 오버로드해야 할 수 있습니다.
  void _navigateToDetailViewer(dynamic item) {
    // 여기서는 EWeapon만 처리하는 예시를 보여줍니다.
    // 만약 Armor 등 다른 타입도 DetailViewerPage에 넘겨야 한다면,
    // DetailViewerPage가 dynamic을 받거나, 각 타입별로 따로 처리해야 합니다.
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
    // EWeaponListPage에 필요한 파라미터들을 전달합니다.
    final List<Widget> _pages = [
      Center(child: Text('AI 질문(AI로 질문을 받을 수 있게 추후 만들 예정)', style: const TextStyle(color: Colors.white, fontSize: 20))),
      EWeaponListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
        navigateToDetailViewer: _navigateToDetailViewer,
      ),
      // 여기에 추후 만들 ArmorListPage, AshListPage, EtcListPage 등을 추가합니다.
      // 현재는 임시로 텍스트 위젯을 사용합니다.
      EArmorListPage(
        game: widget.game,
        searchQuery: _searchQuery,
        showImageDialog: _showImageDialog,
      ),

      Center(child: Text('전투 기술 목록 (게임: ${widget.game.title}, 검색: $_searchQuery)', style: const TextStyle(color: Colors.white, fontSize: 20))),
      Center(child: Text('소비템 목록 (게임: ${widget.game.title}, 검색: $_searchQuery)', style: const TextStyle(color: Colors.white, fontSize: 20))),
      Center(child: Text('기타 목록 (게임: ${widget.game.title}, 검색: $_searchQuery)', style: const TextStyle(color: Colors.white, fontSize: 20))),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: Text(widget.game.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  iconPath: 'assets/images/ai_Icon.png',
                  label: 'AI 질문',
                  index: 0,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchController.clear();
                    });
                  },
                ),

                _buildCategoryButton(
                  iconPath: 'assets/images/weapon_Icon.png',
                  label: '무기',
                  index: 1,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchController.clear(); // 카테고리 변경 시 검색창 초기화
                    });
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/armor_Icon.png',
                  label: '방어구',
                  index: 2,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchController.clear();
                    });
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/ash_Icon.png',
                  label: '전투 기술',
                  index: 3,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchController.clear();
                    });
                  },
                ),
                _buildCategoryButton(
                  iconPath: 'assets/images/use_Icon.png',
                  label: '소비',
                  index: 4,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchController.clear();
                    });
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
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

// _buildCategoryButton 위젯도 GameItemMasterPage의 State 클래스 외부로 옮기거나,
// 이 위젯 내부에 넣고 필요하면 _GameItemMasterPageState에서 접근하도록 합니다.
// 여기서는 위젯 외부로 빼서 재활용 가능하게 했습니다.
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
            //color: isSelected ? Colors.white : Colors.white70,
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