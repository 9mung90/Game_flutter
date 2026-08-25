import 'package:flutter/material.dart';

import '../DTO/earmor.dart';
import '../DTO/eash.dart';
import '../DTO/ebone.dart';
import '../DTO/eetc.dart';
import '../DTO/egesture.dart';
import '../DTO/espell.dart';
import '../DTO/etalisman.dart';
import '../DTO/eweapon.dart';
import '../DTO/game.dart';
import '../local_data/local_data_loader.dart';

class IntegratedSearchPage extends StatefulWidget {
  final Game game;
  final String searchQuery;
  final List<Widget> resultPages;

  const IntegratedSearchPage({
    super.key,
    required this.game,
    required this.searchQuery,
    required this.resultPages,
  });

  @override
  State<IntegratedSearchPage> createState() => _IntegratedSearchPageState();
}

class _IntegratedSearchPageState extends State<IntegratedSearchPage> {
  late final Future<List<_SearchTarget>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<_SearchTarget>> _loadItems() async {
    final results = await Future.wait<Object>([
      LocalDataLoader.loadWeapons(),
      LocalDataLoader.loadArmors(),
      LocalDataLoader.loadAshes(),
      LocalDataLoader.loadSpells(),
      LocalDataLoader.loadTalismans(),
      LocalDataLoader.loadBones(),
      LocalDataLoader.loadEtcs(),
      LocalDataLoader.loadGestures(),
    ]);

    final weapons = results[0] as List<EWeapon>;
    final armors = results[1] as List<EArmor>;
    final ashes = results[2] as List<EAsh>;
    final spells = results[3] as List<ESpell>;
    final talismans = results[4] as List<ETalisman>;
    final bones = results[5] as List<EBone>;
    final etcs = results[6] as List<EEtc>;
    final gestures = results[7] as List<EGesture>;

    return [
      ...weapons.map((item) => _SearchTarget(item.game, item.title)),
      ...armors.map((item) => _SearchTarget(item.game, item.title)),
      ...ashes.map((item) => _SearchTarget(item.game, item.title)),
      ...spells.map((item) => _SearchTarget(item.game, item.title)),
      ...talismans.map((item) => _SearchTarget(item.game, item.title)),
      ...bones.map((item) => _SearchTarget(item.game, item.title)),
      ...etcs.map((item) => _SearchTarget(item.game, item.title)),
      ...gestures.map((item) => _SearchTarget(item.game, item.title)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      final isCompact = MediaQuery.sizeOf(context).width < 600;
      return _IntegratedMessage(
        text: isCompact
            ? '통합 검색 페이지입니다.\n상단 검색창을 이용하여 아이템을 검색해주세요'
            : '통합 검색 페이지입니다. 상단 검색창을 이용하여 아이템을 검색해주세요',
      );
    }

    return FutureBuilder<List<_SearchTarget>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '데이터를 불러오지 못했습니다: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        final hasResult = (snapshot.data ?? const <_SearchTarget>[]).any(
          (item) =>
              item.game == widget.game.title &&
              item.title.toLowerCase().contains(query),
        );

        if (!hasResult) {
          return const _IntegratedMessage(text: '존재하지 않는 아이템입니다.');
        }

        final bottomPadding = MediaQuery.paddingOf(context).bottom + 16;

        return ListView(
          primary: false,
          padding: EdgeInsets.only(bottom: bottomPadding),
          children: widget.resultPages,
        );
      },
    );
  }
}

class _IntegratedMessage extends StatelessWidget {
  final String text;

  const _IntegratedMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
    );
  }
}

class _SearchTarget {
  final String game;
  final String title;

  const _SearchTarget(this.game, this.title);
}
