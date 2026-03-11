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




  String buildAttackTypeText(weapondetail item) {
    final List<String> attackTypes = [];

    if (item.isNormalAttackType.trim() == '1') {
      attackTypes.add('일반');
    }
    if (item.isBlowAttackType.trim() == '1') {
      attackTypes.add('타격');
    }
    if (item.isSlashAttackType.trim() == '1') {
      attackTypes.add('참격');
    }
    if (item.isThrustAttackType.trim() == '1') {
      attackTypes.add('관통');
    }


    if (attackTypes.isEmpty) {
      return '-';
    }

    return attackTypes.join('/');
  }


  // 숫자 보정치를 E~S 등급으로 변환하는 함수
  String convertScalingToGrade(String value) {
    final int? numValue = int.tryParse(value.trim());

    if (numValue == null) {
      return '-';
    }

    if (numValue >= 175) {
      return 'S';
    } else if (numValue >= 140) {
      return 'A';
    } else if (numValue >= 90) {
      return 'B';
    } else if (numValue >= 60) {
      return 'C';
    } else if (numValue >= 25) {
      return 'D';
    } else if (numValue >= 1) {
      return 'E';
    } else {
      return '-';
    }
  }

  String convertRarity(String value) {
    final int? rarityValue = int.tryParse(value.trim());

    if (rarityValue == null) {
      return '-';
    }

    switch (rarityValue) {
      case 1:
        return '일반';
      case 2:
        return '희귀';
      case 3:
        return '전설';
      default:
        return value;
    }
  }


  String? _extractEffectKeyword(String? raw) {
    if (raw == null) return null;

    final text = raw.trim();
    if (text.isEmpty || text == '-1') return null;

    final List<String> parts = text.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;

    final keyword = parts.first.trim();
    if (keyword.isEmpty || keyword == '-1') return null;

    return keyword;
  }

  String? extractEffectKeyword(String? raw) {
    if (raw == null) return null;

    final text = raw.trim();
    if (text.isEmpty || text == '-1') return null;

    final int idx = text.indexOf('상태');

    String keyword;
    if (idx != -1) {
      keyword = text.substring(0, idx).trim();
    } else {
      keyword = text.trim();
    }
    if (keyword.isEmpty || keyword == '-1') return null;

    return keyword;
  }

  String buildSpEffectText(dynamic item) {
    final effects = [
      extractEffectKeyword(item.spEffectMsgId0),
      extractEffectKeyword(item.spEffectMsgId1),
      extractEffectKeyword(item.spEffectMsgId2),
    ].whereType<String>().toList();

    // 중복 제거
    final uniqueEffects = effects.toSet().toList();

    if (uniqueEffects.isEmpty) {
      return '';
    }

    return uniqueEffects.join('/');
  }



  String convertEnhance(String value) {
    return value.trim() == '1' ? '가능' : '불가능';
  }

  String convertDualBlade(String value) {
    return value.trim() == '1' ? '쌍수' : '한손/양손';
  }


  Widget _buildConditionalInfoRow(String label, String value) {
    final String trimmed = value.trim();

    if (trimmed == '1.0' || trimmed == '1' || trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildInfoRow(label, 'x$value');
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
            width: 210,
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
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
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

                    /*
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
                     */

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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          /*
                          _buildInfoRow('ID', item.id),
                          _buildInfoRow('정렬 ID', item.sortId),
                          _buildInfoRow('그룹 ID', item.sortGroupId),
                           */
                          if (buildSpEffectText(item).isNotEmpty)
                            _buildInfoRow('상태 이상', buildSpEffectText(item)),
                          _buildInfoRow('무게', item.weight),
                          _buildInfoRow('희귀도', convertRarity(item.rarity)),
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
                            '능력 보정치 (강화 없는 상태)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('근력', convertScalingToGrade(item.correctStr)),
                          _buildInfoRow('기량', convertScalingToGrade(item.correctDex)),
                          _buildInfoRow('지력', convertScalingToGrade(item.correctInt)),
                          _buildInfoRow('신앙', convertScalingToGrade(item.correctFaith)),
                          _buildInfoRow('신비', convertScalingToGrade(item.correctLuck)),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('물리', item.attackBasePhysics),
                          _buildInfoRow('마력', item.attackBaseMagic),
                          _buildInfoRow('화염', item.attackBaseFire),
                          _buildInfoRow('벼락', item.attackBaseThunder),
                          _buildInfoRow('신성', item.attackBaseDark),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('물리', item.physGuardCutRate),
                          _buildInfoRow('마력', item.magGuardCutRate),
                          _buildInfoRow('화염', item.fireGuardCutRate),
                          _buildInfoRow('벼락', item.thunGuardCutRate),
                          _buildInfoRow('신성', item.darkGuardCutRate),
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
                            '가드 시 상태 이상 내성',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('독', item.poisonGuardResist),
                          _buildInfoRow('부패', item.diseaseGuardResist),
                          _buildInfoRow('출혈', item.bloodGuardResist),
                          _buildInfoRow('수면', item.sleepGuardResist),
                          _buildInfoRow('발광', item.madnessGuardResist),
                          _buildInfoRow('동상', item.freezeGuardResist),
                          _buildInfoRow('죽음', item.curseGuardResist),
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
                          _buildConditionalInfoRow('별에서 온 자에 가하는 피해량 증가', item.weakA_DamageRate),
                          _buildConditionalInfoRow('언데드에 가하는 피해량 증가', item.weakB_DamageRate),
                          _buildConditionalInfoRow('고룡에 가하는 피해량 증가', item.weakC_DamageRate),
                          _buildConditionalInfoRow('비룡에 가하는 피해량 증가', item.weakD_DamageRate),
                          _buildInfoRow('무기의 기본 강인도 감쇄력', item.saWeaponDamage),
                          //_buildInfoRow('전투 기술 ID', item.swordArtsParamId),
                          _buildInfoRow('스태미나 소모량', item.staminaConsumptionRate),
                          _buildInfoRow('리게인 (HP 회복량)', item.wepRegainHp),
                          _buildInfoRow('공격 타입', buildAttackTypeText(item)),
                          _buildInfoRow('인첸트(무기에 일시적 속성 부여)', convertEnhance(item.isEnhance)),
                          _buildInfoRow('무기 운용 방식', convertDualBlade(item.isDualBlade)),
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
        iconTheme: const IconThemeData(
        color: Colors.white,
        ),
        title: Row(
          children: [
            const SizedBox(width: 6),
            Expanded(
              child: Transform.translate(
                offset: const Offset(-14, 0),
                child: Text(
                  normalizeWeaponTitle(widget.weaponTitle),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(5, 0),
              child: Image.asset(
                'assets/images/smithy.png',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(width: 28, height: 28);
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
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