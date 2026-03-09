/// 제스처 아이템 DTO
/// Spring JPA 엔티티 `EGestureAdd`와 1:1로 매핑되는 Flutter 모델입니다.
class EGesture {
  /// DB에서 자동 증가되는 기본키 (Java: Long id)
  final int id;

  /// 게임 종류 (예: 엘든링, 다크소울 등)
  final String game;

  /// 제스처 이름 (title 필드)
  final String title;

  /// 제스처 설명 (description 필드)
  final String description;

  /// 제스처 이미지 URL (img 필드)
  final String img;

  /// 생성자
  EGesture({
    required this.id,
    required this.game,
    required this.title,
    required this.description,
    required this.img,
  });

  /// JSON(Map<String, dynamic>) → EGesture 객체로 변환
  factory EGesture.fromJson(Map<String, dynamic> json) {
    return EGesture(
      id: json['id'] ?? 0,                          // null이면 0으로
      game: json['game'] ?? '',                     // 게임 이름 없으면 빈 문자열
      title: json['title'] ?? '제목 없음',           // 제목 기본값
      description: json['description'] ?? '설명이 없습니다.',
      img: json['img'] ?? '',                       // 이미지 없으면 빈 문자열
    );
  }

  /// EGesture 객체 → JSON(Map<String, dynamic>)으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game,
      'title': title,
      'description': description,
      'img': img,
    };
  }
}
