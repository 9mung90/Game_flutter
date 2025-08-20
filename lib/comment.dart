// lib/comment.dart

class Comment {
  // --- 서버 데이터 (사용자님 원본 기준) ---
  final int id;
  final String username;
  final String comment;
  int likes;
  int dislike; // 사용자님 원본 필드 이름 dislike 유지

  bool myLike;      // 내가 '좋아요'를 눌렀는지 여부
  bool myDislike;   // 내가 '싫어요'를 눌렀는지 여부

  // --- 답글 기능을 위한 추가 데이터 ---
  int replyCount; // 답글 추가 시 UI 즉시 반영을 위해 final 제거

  // --- UI 상태 관리를 위한 변수 ---
  List<Comment> replies;
  bool areRepliesVisible;
  bool areRepliesLoading;

  Comment({
    required this.id,
    required this.username,
    required this.comment,
    required this.likes,
    required this.dislike,
    required this.replyCount,
    this.replies = const [],
    this.areRepliesVisible = false,
    this.areRepliesLoading = false,
    this.myLike = false,
    this.myDislike = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      username: json['nickname'] ?? json['username'] ?? '',
      comment: json['text'] ?? json['comment'] ?? '',
      likes: json['likes'] ?? 0,
      dislike: json['dislike'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      myLike: json['myLike'] ?? false,
      myDislike: json['myDislike'] ?? false,
    );
  }
}