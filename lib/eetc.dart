
class EEtc {
  /// DB에서 자동 증가되는 기본키
  final int id;

  /// 게임 종류
  final String game;

  /// 아이템 이름
  final String title;

  /// 아이템 타입/분류
  final String type;

  /// 상세 설명
  final String description;

  /// 능력/효과
  final String ability;

  /// 아이템 이미지 URL
  final String img;

  EEtc({
    required this.id,
    required this.game,
    required this.title,
    required this.type,
    required this.description,
    required this.ability,
    required this.img,
  });

  /// JSON → EEtc 객체 변환
  factory EEtc.fromJson(Map<String, dynamic> json) {
    return EEtc(
      id: json['id'] ?? 0,
      game: json['game'] ?? '',
      title: json['title'] ?? '제목 없음',
      type: json['type'] ?? '타입 정보 없음',
      description: json['description'] ?? '설명이 없습니다.',
      ability: json['ability'] ?? '능력 정보 없음',
      img: json['img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game,
      'title': title,
      'type': type,
      'description': description,
      'ability': ability,
      'img': img,
    };
  }
}
