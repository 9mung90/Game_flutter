// lib/eweapon.dart

// API로부터 받은 무기 데이터를 담을 클래스입니다.
class ESpell {
  final int id;
  final String game;
  final String title;
  final String type;
  final String slot;
  final String need;
  final String description;
  final String img;  // 목록에 표시될 기본 이미지

  ESpell({
    required this.id,
    required this.game,
    required this.title,
    required this.type,
    required this.slot,
    required this.need,
    required this.description,
    required this.img,

  });

  // JSON 데이터를 EWeapon 객체로 변환해주는 팩토리 생성자입니다.
  // 이 부분이 있어야 서버에서 받은 데이터를 안전하게 객체로 만들 수 있습니다.
  factory ESpell.fromJson(Map<String, dynamic> json) {
    return ESpell(
      id: json['id'],
      game: json['game'] ?? '', // 데이터가 null일 경우를 대비해 기본값 설정
      title: json['title'] ?? '제목 없음',
      type: json['type'] ?? '주문 타입 없음',
      slot: json['slot'] ?? '요구 슬롯 없음',
      need: json['need'] ?? '요구 스탯 없음',
      description: json['description'] ?? '설명이 없습니다.',
      img: json['img'] ?? '',

    );
  }
}