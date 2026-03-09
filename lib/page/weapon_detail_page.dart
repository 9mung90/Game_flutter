import 'package:flutter/material.dart';

import '../DTO/weapon_detail.dart';
import '../local_data/local_data_loader.dart';

class WeaponDetailPage extends StatefulWidget {
  final String weaponTitle;
  final String weaponImage;

  const WeaponDetailPage({
    super.key,
    required this.weaponTitle,
    required this.weaponImage,
  });

  @override
  State<WeaponDetailPage> createState() => _WeaponDetailPageState();
}

class _WeaponDetailPageState extends State<WeaponDetailPage> {
  late Future<List<weapondetail>> _futureFilteredDetails;
  String? _expandedName;

  @override
  void initState() {
    super.initState();
    _futureFilteredDetails = fetchFilteredWeaponDetails();
  }

  String normalizeWeaponTitle(String title) {
    return title
        .replaceAll(RegExp(r'[○☆◇]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String getAffinityIconPath(String weaponName) {
    final String name = normalizeWeaponTitle(weaponName);

    if (name.startsWith('중후한')) {
      return 'assets/images/attribute/physical.png';
    }
    if (name.startsWith('예리한')) {
      return 'assets/images/attribute/sharp.png';
    }
    if (name.startsWith('상질')) {
      return 'assets/images/attribute/sangjil.png';
    }
    if (name.startsWith('마력')) {
      return 'assets/images/attribute/magic.png';
    }
    if (name.startsWith('화염')) {
      return 'assets/images/attribute/fire.png';
    }
    if (name.startsWith('화염술')) {
      return 'assets/images/attribute/fire.png';
    }
    if (name.startsWith('벼락')) {
      return 'assets/images/attribute/lightning.png';
    }
    if (name.startsWith('신성')) {
      return 'assets/images/attribute/holy.png';
    }
    if (name.startsWith('독')) {
      return 'assets/images/attribute/poison.png';
    }
    if (name.startsWith('피')) {
      return 'assets/images/attribute/blood.png';
    }
    if (name.startsWith('차가운')) {
      return 'assets/images/attribute/frost.png';
    }
    if (name.startsWith('신비')) {
      return 'assets/images/attribute/sinbi.png';
    }

    return 'assets/images/attribute/original.png';
  }



  Future<List<weapondetail>> fetchFilteredWeaponDetails() async {
    final List<weapondetail> allDetails =
    await LocalDataLoader.loadWeaponDetails();

    final String keyword =
    normalizeWeaponTitle(widget.weaponTitle).toLowerCase();

    // 검색어별 제외할 이름들
    final Map<String, List<String>> excludedNames = {
      '대거': [
        '패링 대거',
      ],
      '대도': [
        '흉조의 아이 대도',
        '용 사냥꾼의 대도',
        '나찰의 대도',
      ],
      '긴 이빨': [
        '사냥개의 긴 이빨',
      ],
      '그레이트 소드': [
        '왕가의 그레이트 소드',
      ],
      '라단의 대검(빛)': [
        '라단의 대검(왕)',
      ],
      '라단의 대검(왕)': [
        '라단의 대검(빛)',
      ],
    };

    final List<String> excluded =
    (excludedNames[keyword] ?? []).map((e) => e.toLowerCase()).toList();

    final List<weapondetail> filtered = allDetails.where((item) {
      final String name = normalizeWeaponTitle(item.name).toLowerCase();

      // 먼저 검색어 포함 여부 확인
      if (!name.contains(keyword)) {
        return false;
      }

      // 제외 키워드가 하나라도 포함되면 제외
      for (final exclude in excluded) {
        if (name.contains(exclude)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      BuildContext context,
      weapondetail item,
      double screenWidth,
      double screenHeight,
      ) {
    final bool isExpanded = _expandedName == item.name;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: const DecorationImage(
          image: AssetImage('assets/images/background_column.png'),
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedName = isExpanded ? null : item.name;
          });
        },
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: screenWidth * 0.25,
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      widget.weaponImage,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white24,
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
                          Row(
                            children: [
                              Image.asset(
                                getAffinityIconPath(item.name),
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(width: 18, height: 18);
                                },
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '무게 ${item.weight}  |  희귀도 ${item.rarity}',
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

                    if (item.description.trim().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          item.description.trim(),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '기본 정보',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('ID', item.id),
                          _buildInfoRow('정렬 ID', item.sortId),
                          _buildInfoRow('그룹 ID', item.sortGroupId),
                          _buildInfoRow('무게', item.weight),
                          _buildInfoRow('희귀도', item.rarity),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '능력 보정',
                            style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('근력', item.correctStr),
                          _buildInfoRow('기량', item.correctDex),
                          _buildInfoRow('지력', item.correctInt),
                          _buildInfoRow('신앙', item.correctFaith),
                          _buildInfoRow('행운', item.correctLuck),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '기본 공격력',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('물리', item.attackBasePhysics),
                          _buildInfoRow('마력', item.attackBaseMagic),
                          _buildInfoRow('화염', item.attackBaseFire),
                          _buildInfoRow('벼락', item.attackBaseThunder),
                          _buildInfoRow('어둠', item.attackBaseDark),
                          _buildInfoRow('치명', item.attackBaseStamina),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '가드 감소율',
                            style: TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('물리', item.physGuardCutRate),
                          _buildInfoRow('마력', item.magGuardCutRate),
                          _buildInfoRow('화염', item.fireGuardCutRate),
                          _buildInfoRow('벼락', item.thunGuardCutRate),
                          _buildInfoRow('어둠', item.darkGuardCutRate),
                          _buildInfoRow('가드 강도', item.staminaGuardDef),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '상태 이상 저항',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('독', item.poisonGuardResist),
                          _buildInfoRow('맹독', item.diseaseGuardResist),
                          _buildInfoRow('출혈', item.bloodGuardResist),
                          _buildInfoRow('수면', item.sleepGuardResist),
                          _buildInfoRow('광기', item.madnessGuardResist),
                          _buildInfoRow('동상', item.freezeGuardResist),
                          _buildInfoRow('저주', item.curseGuardResist),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '기타 정보',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('약공격 배율 A', item.weakA_DamageRate),
                          _buildInfoRow('약공격 배율 B', item.weakB_DamageRate),
                          _buildInfoRow('약공격 배율 C', item.weakC_DamageRate),
                          _buildInfoRow('약공격 배율 D', item.weakD_DamageRate),
                          _buildInfoRow('강인도 공격력', item.saWeaponDamage),
                          _buildInfoRow('전투 기술 ID', item.swordArtsParamId),
                          _buildInfoRow('스태미나 소모율', item.staminaConsumptionRate),
                          _buildInfoRow('HP 회복량', item.wepRegainHp),
                          _buildInfoRow('일반 공격 타입', item.isNormalAttackType),
                          _buildInfoRow('타격 공격 타입', item.isBlowAttackType),
                          _buildInfoRow('참격 공격 타입', item.isSlashAttackType),
                          _buildInfoRow('관통 공격 타입', item.isThrustAttackType),
                          _buildInfoRow('강화 가능', item.isEnhance),
                          _buildInfoRow('쌍수 무기', item.isDualBlade),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(normalizeWeaponTitle(widget.weaponTitle)),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<weapondetail>>(
        future: _futureFilteredDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '에러 발생: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                '"${widget.weaponTitle}" 이(가) 포함된 상세 데이터가 없습니다.',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, bottomPadding),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildDetailCard(
                context,
                item,
                screenWidth,
                screenHeight,
              );
            },
          );
        },
      ),
    );
  }
}