// lib/eweapon.dart

// API로부터 받은 무기 데이터를 담을 클래스입니다.
class EWeapon {
  final int id;
  final String game;
  final String title;
  final String type;
  final String img;  // 목록에 표시될 기본 이미지
  final String img2; // 확장 시 보일 상세 이미지
  final String description; // 확장 시 보일 설명

  EWeapon({
    required this.id,
    required this.game,
    required this.title,
    required this.type,
    required this.img,
    required this.img2,
    required this.description,
  });

  // JSON 데이터를 EWeapon 객체로 변환해주는 팩토리 생성자입니다.
  // 이 부분이 있어야 서버에서 받은 데이터를 안전하게 객체로 만들 수 있습니다.
  factory EWeapon.fromJson(Map<String, dynamic> json) {
    return EWeapon(
      id: json['id'],
      game: json['game'] ?? '', // 데이터가 null일 경우를 대비해 기본값 설정
      title: json['title'] ?? '제목 없음',
      type: json['type'] ?? '타입 정보 없음',
      img: json['img'] ?? '',
      img2: json['img2'] ?? '',
      description: json['description'] ?? '설명이 없습니다.',
    );
  }
}