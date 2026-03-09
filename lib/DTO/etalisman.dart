// lib/etalisman.dart

// API로부터 받은 탈리스만(ETalisman) 데이터를 담을 클래스입니다.
class ETalisman {
  final int id;
  final String game;
  final String title;
  final String description;
  final String ability;
  final String img; // 목록에 표시될 기본 이미지 URL

  ETalisman({
    required this.id,
    required this.game,
    required this.title,
    required this.description,
    required this.ability,
    required this.img,
  });

  // JSON 데이터를 ETalisman 객체로 변환해주는 팩토리 생성자입니다.
  // 이 부분이 있어야 서버에서 받은 데이터를 안전하게 객체로 만들 수 있습니다.
  factory ETalisman.fromJson(Map<String, dynamic> json) {
    return ETalisman(
      id: json['id'],
      game: json['game'] ?? '', // 데이터가 null일 경우 기본값
      title: json['title'] ?? '제목 없음',
      description: json['description'] ?? '설명이 없습니다.',
      ability: json['ability'] ?? '능력 정보가 없습니다.',
      img: json['img'] ?? '',
    );
  }
}
