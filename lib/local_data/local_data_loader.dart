// lib/local_data/local_data_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../eweapon.dart';
import '../earmor.dart';
import '../eash.dart';
import '../espell.dart';
import '../etalisman.dart'; // ⭐ 탈리스만 모델
import '../ebone.dart';     // ⭐ 뼈(EBone) 모델
import '../eetc.dart';      // ⭐ 기타(EEtc) 모델
import '../egesture.dart';  // ⭐ 제스처(EGesture) 모델 추가

/// 엘든 링 데이터들을 로컬 JSON(assets)에 담아두고
/// 앱에서 불러오는 유틸 클래스
class LocalDataLoader {
  // 🔥 무기 캐시: 한 번 읽으면 앱 살아있는 동안 재사용
  static List<EWeapon>? _weaponCache;

  // 🔥 방어구 캐시
  static List<EArmor>? _armorCache;

  // 🔥 재(전투 기술) 캐시
  static List<EAsh>? _ashCache;

  // 🔥 주문(Spell) 캐시
  static List<ESpell>? _spellCache;

  // 🔥 탈리스만 캐시
  static List<ETalisman>? _talismanCache;

  // 🔥 뼈(EBone) 캐시
  static List<EBone>? _boneCache;

  // 🔥 기타(EEtc) 캐시
  static List<EEtc>? _etcCache;

  // 🔥 제스처(EGesture) 캐시
  static List<EGesture>? _gestureCache;

  /// 무기 데이터 로드
  /// - 처음 한 번만 assets/data/EWeaponv1.json을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<EWeapon>> loadWeapons() async {
    // 이미 캐시에 있으면 그대로 반환
    if (_weaponCache != null) return _weaponCache!;

    // 1) assets 에서 JSON 문자열 읽어오기
    final jsonString =
    await rootBundle.loadString('assets/data/EWeaponv1.json');

    // 2) JSON 문자열을 List<dynamic> 으로 디코딩
    final List<dynamic> jsonList = json.decode(jsonString);

    // 3) 각 항목을 EWeapon.fromJson 으로 변환
    _weaponCache = jsonList
        .map((e) => EWeapon.fromJson(e as Map<String, dynamic>))
        .toList();

    return _weaponCache!;
  }

  /// 방어구 데이터 로드
  /// - 처음 한 번만 assets/data/EArmorv1.json을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<EArmor>> loadArmors() async {
    // 이미 캐시에 있으면 그대로 반환
    if (_armorCache != null) return _armorCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/EArmorv1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _armorCache = jsonList
        .map((e) => EArmor.fromJson(e as Map<String, dynamic>))
        .toList();

    return _armorCache!;
  }

  /// 재(전투 기술) 데이터 로드
  /// - assets/data/EAshv1.json 에서 로드
  static Future<List<EAsh>> loadAshes() async {
    if (_ashCache != null) return _ashCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/EAshv1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _ashCache = jsonList
        .map((e) => EAsh.fromJson(e as Map<String, dynamic>))
        .toList();

    return _ashCache!;
  }

  /// 주문(Spell) 데이터 로드
  /// - 처음 한 번만 assets/data/ESpellv1.json을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<ESpell>> loadSpells() async {
    if (_spellCache != null) return _spellCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/ESpellv1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _spellCache = jsonList
        .map((e) => ESpell.fromJson(e as Map<String, dynamic>))
        .toList();

    return _spellCache!;
  }

  /// 탈리스만 데이터 로드
  /// - 처음 한 번만 assets/data/ETalismanv1.json 을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<ETalisman>> loadTalismans() async {
    if (_talismanCache != null) return _talismanCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/ETalismanv1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _talismanCache = jsonList
        .map((e) => ETalisman.fromJson(e as Map<String, dynamic>))
        .toList();

    return _talismanCache!;
  }

  /// 뼈(EBone) 데이터 로드
  /// - 처음 한 번만 assets/data/EBonev1.json 을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<EBone>> loadBones() async {
    if (_boneCache != null) return _boneCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/EBonev1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _boneCache = jsonList
        .map((e) => EBone.fromJson(e as Map<String, dynamic>))
        .toList();

    return _boneCache!;
  }

  /// 기타(EEtc) 데이터 로드
  /// - 처음 한 번만 assets/data/EEtcv1.json 을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<EEtc>> loadEtcs() async {
    if (_etcCache != null) return _etcCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/EEtcv1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _etcCache = jsonList
        .map((e) => EEtc.fromJson(e as Map<String, dynamic>))
        .toList();

    return _etcCache!;
  }

  /// 제스처(EGesture) 데이터 로드
  /// - 처음 한 번만 assets/data/EGesturev1.json 을 읽고
  /// - 이후에는 메모리에 들고 있다가 그대로 반환
  static Future<List<EGesture>> loadGestures() async {
    if (_gestureCache != null) return _gestureCache!;

    final jsonString =
    await rootBundle.loadString('assets/data/EGesturev1.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    _gestureCache = jsonList
        .map((e) => EGesture.fromJson(e as Map<String, dynamic>))
        .toList();

    return _gestureCache!;
  }
}
