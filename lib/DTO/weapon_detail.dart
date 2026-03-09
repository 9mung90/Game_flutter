class weapondetail {
  final String id;
  final String name;
  final String description;
  final String sortId;
  final String sortGroupId;
  final String weight;

  final String correctStr;
  final String correctDex;
  final String correctInt;
  final String correctFaith;
  final String correctLuck;

  final String physGuardCutRate;
  final String magGuardCutRate;
  final String fireGuardCutRate;
  final String thunGuardCutRate;
  final String darkGuardCutRate;

  final String poisonGuardResist;
  final String diseaseGuardResist;
  final String bloodGuardResist;
  final String sleepGuardResist;
  final String madnessGuardResist;
  final String freezeGuardResist;
  final String curseGuardResist;

  final String staminaGuardDef;

  final String weakA_DamageRate;
  final String weakB_DamageRate;
  final String weakC_DamageRate;
  final String weakD_DamageRate;

  final String saWeaponDamage;

  final String attackBasePhysics;
  final String attackBaseMagic;
  final String attackBaseFire;
  final String attackBaseThunder;
  final String attackBaseDark;
  final String attackBaseStamina;

  final String trophySGradeId;
  final String bowDistRate;
  final String guardCutCancelRate;

  final String isNormalAttackType;
  final String isBlowAttackType;
  final String isSlashAttackType;
  final String isThrustAttackType;
  final String isEnhance;
  final String isDualBlade;

  final String swordArtsParamId;
  final String staminaConsumptionRate;
  final String rarity;
  final String wepRegainHp;

  final String spEffectMsgId0;
  final String spEffectMsgId1;
  final String spEffectMsgId2;

  weapondetail({
    required this.id,
    required this.name,
    required this.description,
    required this.sortId,
    required this.sortGroupId,
    required this.weight,
    required this.correctStr,
    required this.correctDex,
    required this.correctInt,
    required this.correctFaith,
    required this.correctLuck,
    required this.physGuardCutRate,
    required this.magGuardCutRate,
    required this.fireGuardCutRate,
    required this.thunGuardCutRate,
    required this.darkGuardCutRate,
    required this.poisonGuardResist,
    required this.diseaseGuardResist,
    required this.bloodGuardResist,
    required this.sleepGuardResist,
    required this.madnessGuardResist,
    required this.freezeGuardResist,
    required this.curseGuardResist,
    required this.staminaGuardDef,
    required this.weakA_DamageRate,
    required this.weakB_DamageRate,
    required this.weakC_DamageRate,
    required this.weakD_DamageRate,
    required this.saWeaponDamage,
    required this.attackBasePhysics,
    required this.attackBaseMagic,
    required this.attackBaseFire,
    required this.attackBaseThunder,
    required this.attackBaseDark,
    required this.attackBaseStamina,
    required this.trophySGradeId,
    required this.bowDistRate,
    required this.guardCutCancelRate,
    required this.isNormalAttackType,
    required this.isBlowAttackType,
    required this.isSlashAttackType,
    required this.isThrustAttackType,
    required this.isEnhance,
    required this.isDualBlade,
    required this.swordArtsParamId,
    required this.staminaConsumptionRate,
    required this.rarity,
    required this.wepRegainHp,
    required this.spEffectMsgId0,
    required this.spEffectMsgId1,
    required this.spEffectMsgId2,
  });

  factory weapondetail.fromJson(Map<String, dynamic> json) {
    return weapondetail(
      id: json['ID']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      description: json['Description']?.toString() ?? '',
      sortId: json['sortId']?.toString() ?? '',
      sortGroupId: json['sortGroupId']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      correctStr: json['correctStr']?.toString() ?? '',
      correctDex: json['correctDex']?.toString() ?? '',
      correctInt: json['correctInt']?.toString() ?? '',
      correctFaith: json['correctFaith']?.toString() ?? '',
      correctLuck: json['correctLuck']?.toString() ?? '',
      physGuardCutRate: json['physGuardCutRate']?.toString() ?? '',
      magGuardCutRate: json['magGuardCutRate']?.toString() ?? '',
      fireGuardCutRate: json['fireGuardCutRate']?.toString() ?? '',
      thunGuardCutRate: json['thunGuardCutRate']?.toString() ?? '',
      darkGuardCutRate: json['darkGuardCutRate']?.toString() ?? '',
      poisonGuardResist: json['poisonGuardResist']?.toString() ?? '',
      diseaseGuardResist: json['diseaseGuardResist']?.toString() ?? '',
      bloodGuardResist: json['bloodGuardResist']?.toString() ?? '',
      sleepGuardResist: json['sleepGuardResist']?.toString() ?? '',
      madnessGuardResist: json['madnessGuardResist']?.toString() ?? '',
      freezeGuardResist: json['freezeGuardResist']?.toString() ?? '',
      curseGuardResist: json['curseGuardResist']?.toString() ?? '',
      staminaGuardDef: json['staminaGuardDef']?.toString() ?? '',
      weakA_DamageRate: json['weakA_DamageRate']?.toString() ?? '',
      weakB_DamageRate: json['weakB_DamageRate']?.toString() ?? '',
      weakC_DamageRate: json['weakC_DamageRate']?.toString() ?? '',
      weakD_DamageRate: json['weakD_DamageRate']?.toString() ?? '',
      saWeaponDamage: json['saWeaponDamage']?.toString() ?? '',
      attackBasePhysics: json['attackBasePhysics']?.toString() ?? '',
      attackBaseMagic: json['attackBaseMagic']?.toString() ?? '',
      attackBaseFire: json['attackBaseFire']?.toString() ?? '',
      attackBaseThunder: json['attackBaseThunder']?.toString() ?? '',
      attackBaseDark: json['attackBaseDark']?.toString() ?? '',
      attackBaseStamina: json['attackBaseStamina']?.toString() ?? '',
      trophySGradeId: json['trophySGradeId']?.toString() ?? '',
      bowDistRate: json['bowDistRate']?.toString() ?? '',
      guardCutCancelRate: json['guardCutCancelRate']?.toString() ?? '',
      isNormalAttackType: json['isNormalAttackType']?.toString() ?? '',
      isBlowAttackType: json['isBlowAttackType']?.toString() ?? '',
      isSlashAttackType: json['isSlashAttackType']?.toString() ?? '',
      isThrustAttackType: json['isThrustAttackType']?.toString() ?? '',
      isEnhance: json['isEnhance']?.toString() ?? '',
      isDualBlade: json['isDualBlade']?.toString() ?? '',
      swordArtsParamId: json['swordArtsParamId']?.toString() ?? '',
      staminaConsumptionRate: json['staminaConsumptionRate']?.toString() ?? '',
      rarity: json['rarity']?.toString() ?? '',
      wepRegainHp: json['wepRegainHp']?.toString() ?? '',
      spEffectMsgId0: json['spEffectMsgId0']?.toString() ?? '',
      spEffectMsgId1: json['spEffectMsgId1']?.toString() ?? '',
      spEffectMsgId2: json['spEffectMsgId2']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Description': description,
      'sortId': sortId,
      'sortGroupId': sortGroupId,
      'weight': weight,
      'correctStr': correctStr,
      'correctDex': correctDex,
      'correctInt': correctInt,
      'correctFaith': correctFaith,
      'correctLuck': correctLuck,
      'physGuardCutRate': physGuardCutRate,
      'magGuardCutRate': magGuardCutRate,
      'fireGuardCutRate': fireGuardCutRate,
      'thunGuardCutRate': thunGuardCutRate,
      'darkGuardCutRate': darkGuardCutRate,
      'poisonGuardResist': poisonGuardResist,
      'diseaseGuardResist': diseaseGuardResist,
      'bloodGuardResist': bloodGuardResist,
      'sleepGuardResist': sleepGuardResist,
      'madnessGuardResist': madnessGuardResist,
      'freezeGuardResist': freezeGuardResist,
      'curseGuardResist': curseGuardResist,
      'staminaGuardDef': staminaGuardDef,
      'weakA_DamageRate': weakA_DamageRate,
      'weakB_DamageRate': weakB_DamageRate,
      'weakC_DamageRate': weakC_DamageRate,
      'weakD_DamageRate': weakD_DamageRate,
      'saWeaponDamage': saWeaponDamage,
      'attackBasePhysics': attackBasePhysics,
      'attackBaseMagic': attackBaseMagic,
      'attackBaseFire': attackBaseFire,
      'attackBaseThunder': attackBaseThunder,
      'attackBaseDark': attackBaseDark,
      'attackBaseStamina': attackBaseStamina,
      'trophySGradeId': trophySGradeId,
      'bowDistRate': bowDistRate,
      'guardCutCancelRate': guardCutCancelRate,
      'isNormalAttackType': isNormalAttackType,
      'isBlowAttackType': isBlowAttackType,
      'isSlashAttackType': isSlashAttackType,
      'isThrustAttackType': isThrustAttackType,
      'isEnhance': isEnhance,
      'isDualBlade': isDualBlade,
      'swordArtsParamId': swordArtsParamId,
      'staminaConsumptionRate': staminaConsumptionRate,
      'rarity': rarity,
      'wepRegainHp': wepRegainHp,
      'spEffectMsgId0': spEffectMsgId0,
      'spEffectMsgId1': spEffectMsgId1,
      'spEffectMsgId2': spEffectMsgId2,
    };
  }
}