import 'dart:convert';
import 'dart:io';

const _mapNameCorrections = <String, String>{
  '손가락 끊기 칼': '손가락 끊기',
  '손가락 자국 포도': '손가락 자국의 포도',
  '휘석 숫돌 칼날': '휘석의 숫돌 칼날',
  '금 바늘': '황금 재봉 바늘',
  '황금 재봉 도구': '황금의 재봉도구',
  '철 숫돌 칼날': '철의 숫돌 칼날',
  '말하는 머리 "시작하자"': '말하는 머리 "시작할까?"',
  '말하는 머리 "도와줘"': '말하는 머리 "도와줘…"',
  '말하는 머리 "대단해"': '말하는 머리 "대단해!"',
  '배율자의 손가락': '배율의 손가락',
  '붉은 숫돌 칼날': '불탄 숫돌 칼날',
  '신성 숫돌 칼날': '성스러운 숫돌 칼날',
  '승리의 환희': '양손으로 환희',
  '내면의 율': '내재하는 규율',
  '도가니의 모습/목': '도가니의 모습/후대',
  '황금의 마력방호': '황금의 마력 방호',
  '영원한 어둠': '영원한 암흑',
  '불이여 힘을!': '불이여, 힘을!',
  '냉기 무기': '빙결의 무기',
  '정신 맑음': '냉정',
  '독 무기': '독 칼날',
  '용암 작렬': '솟구치는 용암',
  '그림자의 유인': '그림자 보내기',
  '불이여, 회오리쳐라!': '불이여 회오리쳐라',
  '빙뢰창': '얼음 뇌창',
  '전회: 환영의 창': '전회: 환영창',
  '넘치는 붉은 결정 물방울': '넘친 붉은 결정 물방울',
  '기량 혹 결정 물방울': '기량의 혹 결정 물방울',
  '신앙 혹 결정 물방울': '신앙의 혹 결정 물방울',
  '화염 두른 깨진 물방울': '불꽃 두른 깨진 물방울',
  '넘치는 초록 결정 물방울': '넘친 초록 결정 물방울',
  '지력 혹 결정 물방울': '지력의 혹 결정 물방울',
  '돌가시 깨진 물방울': '바위 가시 깨진 물방울',
  '근력 혹 결정 물방울': '근력의 혹 결정 물방울',
  '나뭇가지 깨진 물방울': '가는 가지 깨진 물방울',
  '클렙스의 작은 병': '크레푸스의 작은 병',
  '사악한 왕자의 업창': '죽음의 왕자의 업창',
  '성수의 비부절(좌)': '성수의 비부절 (좌)',
  '성수의 비부절(우)': '성수의 비부절 (우)',
  '지도 조각: 거인들의 산령 동부': '지도 조각: 거인 산령 동부',
  '지도 조각: 거인들의 산령 서부': '지도 조각: 거인 산령 서부',
  '지도 조각: 시오프라 강': '지도 조각: 시프라 강',
  '연성 석궁': '연노',
  '하이마의 포탄': '하이마의 포탑',
  '말하는 머리 "내 사랑"': '말하는 머리 "사랑해"',
  '덱타스의 부절(좌)': '덱타스의 부절 (좌)',
  '덱타스의 부절(우)': '덱타스의 부절 (우)',
};

const _mapImageOverrides = <String, String>{
  '무구한 금의 침':
      'https://coddingswitch.s3.ap-northeast-2.amazonaws.com/test/SB_Icon_02__MENU_ItemIcon_03231.png',
  '작은 라니':
      'https://coddingswitch.s3.ap-northeast-2.amazonaws.com/test/SB_Icon_02__MENU_ItemIcon_03074.png',
};

const _eTitleCorrections = <String, Map<String, String>>{
  'assets/data/EEtcv1.json': {
    '부적주머니': '부적 주머니',
    '영웅의 룬[1]': '영웅의 룬 [1]',
  },
  'assets/data/EAshv1.json': {
    '독나방은 두번 춤춘다': '독나방은 두 번 춤춘다',
    '에로우 레인': '애로우 레인',
  },
  'assets/data/EWeaponv1.json': {
    '헬펜의 청탑 ○': '헬펜의 첨탑 ○',
    '실루리아의 나무 창 ○': '실루리아의 나무창 ○',
  },
  'assets/data/EBonev1.json': {
    '헤메는 귀인의 뽛가루': '헤매는 귀인의 뽛가루',
    '밤 무녀와 검의 꼭두각시': '밤 무녀와 검사 꼭두각시',
  },
};

void main() {
  _updateMapItems();
  _updateETitles();
}

void _updateMapItems() {
  final file = File('assets/data/map_data/items.json');
  final items = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  var renamed = 0;
  var recategorized = 0;
  var imageOverrides = 0;

  for (final item in items) {
    final oldName = item['kor_name'] as String?;
    final newName = oldName == null ? null : _mapNameCorrections[oldName];
    if (newName != null) {
      item['kor_name'] = newName;
      renamed++;
    }

    final name = item['kor_name'] as String?;
    final newCategory = switch (name) {
      '어머니여' ||
      '두 손가락' ||
      '양손으로 환희' ||
      '내재하는 규율' ||
      '겨루기 소망' =>
        'gesture',
      '상실의 전회' || '색 잃은 단석 [5]' => 'upgrade_material',
      '듀얼링 실드' => 'weapon',
      _ => null,
    };

    if (newCategory != null && item['category'] != newCategory) {
      item['category'] = newCategory;
      recategorized++;
    }

    final imageUrl = name == null ? null : _mapImageOverrides[name];
    if (imageUrl != null && item['image_url'] != imageUrl) {
      item['image_url'] = imageUrl;
      imageOverrides++;
    }
  }

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(items)}\n');
  stdout.writeln(
    'items.json: renamed=$renamed recategorized=$recategorized '
    'imageOverrides=$imageOverrides',
  );
}

void _updateETitles() {
  for (final entry in _eTitleCorrections.entries) {
    final file = File(entry.key);
    final items = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    var renamed = 0;

    for (final item in items) {
      final oldTitle = item['title'] as String?;
      final newTitle = oldTitle == null ? null : entry.value[oldTitle];
      if (newTitle != null) {
        item['title'] = newTitle;
        renamed++;
      }
    }

    file.writeAsStringSync(jsonEncode(items));
    stdout.writeln('${entry.key}: renamed=$renamed');
  }
}
