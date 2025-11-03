// lib/eweapon.dart

// API로부터 받은 무기 데이터를 담을 클래스입니다.
class EArmor {
  final int id;
  final String game;
  final String title;
  final String part;
  final String aset;
  final String description;
  final String img;  // 목록에 표시될 기본 이미지

  EArmor({
    required this.id,
    required this.game,
    required this.title,
    required this.part,
    required this.aset,
    required this.description,
    required this.img,

  });

  // JSON 데이터를 EWeapon 객체로 변환해주는 팩토리 생성자입니다.
  // 이 부분이 있어야 서버에서 받은 데이터를 안전하게 객체로 만들 수 있습니다.
  factory EArmor.fromJson(Map<String, dynamic> json) {
    return EArmor(
      id: json['id'],
      game: json['game'] ?? '', // 데이터가 null일 경우를 대비해 기본값 설정
      title: json['title'] ?? '제목 없음',
      part: json['part'] ?? '부위 종류 없음',
      aset: json['aset'] ?? '세트 정보 없음',
      description: json['description'] ?? '설명이 없습니다.',
      img: json['img'] ?? '',

    );
  }
}