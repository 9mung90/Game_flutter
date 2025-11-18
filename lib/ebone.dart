class EBone {
  /// DB에서 자동 증가되는 기본키
  final int id;

  /// 게임 종류 (예: 엘든링, 다크소울 등)
  final String game;

  /// 아이템 이름
  final String title;

  /// 용도 / 쓰임새 (buse 필드)
  final String buse;

  /// 획득 방법 (bget 필드)
  final String bget;

  /// 상세 설명
  final String description;

  /// 아이템 이미지 URL
  final String img;

  /// 생성자
  EBone({
    required this.id,
    required this.game,
    required this.title,
    required this.buse,
    required this.bget,
    required this.description,
    required this.img,
  });

  /// JSON 데이터를 EBone 객체로 변환해주는 팩토리 생성자입니다.
  /// 서버에서 받은 Map<String, dynamic> 형태의 JSON을 안전하게 파싱합니다.
  factory EBone.fromJson(Map<String, dynamic> json) {
    return EBone(
      id: json['id'] ?? 0,
      game: json['game'] ?? '',                 // null이면 빈 문자열
      title: json['title'] ?? '제목 없음',        // 제목 기본값
      buse: json['buse'] ?? '용도 정보 없음',     // buse 기본값
      bget: json['bget'] ?? '획득 정보 없음',     // bget 기본값
      description: json['description'] ?? '설명이 없습니다.',
      img: json['img'] ?? '',                   // 이미지가 없으면 빈 문자열
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game,
      'title': title,
      'buse': buse,
      'bget': bget,
      'description': description,
      'img': img,
    };
  }
}
