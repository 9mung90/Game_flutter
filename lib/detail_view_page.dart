// lib/pages/detail_viewer_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forspeech/api_config.dart';
import 'package:forspeech/eweapon.dart';
import 'user_session.dart';
import 'etc.dart';
import 'photo_fullscreen_viewer.dart';
import 'comment.dart';

class DetailViewerPage extends StatefulWidget {
  final EWeapon weapon;

  const DetailViewerPage({
    super.key,
    required this.weapon,
  });

  @override
  State<DetailViewerPage> createState() => _DetailViewerPageState();
}

class _DetailViewerPageState extends State<DetailViewerPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  final TextEditingController _commentController = TextEditingController();
  // ▼▼▼ [수정] 답글 컨트롤러는 여전히 필요합니다. 페이지 레벨에서 하나만 관리합니다.
  final TextEditingController _replyController = TextEditingController();
  final Dio _dio = Dio();

  late Future<List<Comment>> _commentsFuture;
  // ▼▼▼ [추가] 현재 답글을 달고 있는 부모 댓글을 추적하기 위한 상태 변수
  Comment? _replyingToComment;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() => _currentPage = _pageController.page!.round());
      }
    });
    _commentsFuture = _fetchComments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _replyController.dispose(); // [수정] 답글 컨트롤러도 dispose
    super.dispose();
  }

  /// 서버에서 '최상위 댓글' 목록을 가져오는 로직 (원본과 동일)
  Future<List<Comment>> _fetchComments() async {
    try {
      final response = await _dio.get('$apiBaseUrl/api/comments/${widget.weapon.id}');
      if (response.statusCode == 200) {
        final List<dynamic> body = response.data;
        return body.map((dynamic item) => Comment.fromJson(item)).toList();
      }
    } catch (e) {
      print('댓글 로딩 중 에러 발생: $e');
    }
    return [];
  }

  /// 특정 댓글의 '답글' 목록을 서버에서 가져오는 로직
  Future<void> _fetchReplies(Comment parentComment) async {
    setState(() => parentComment.areRepliesLoading = true);
    try {
      final response = await _dio.get('$apiBaseUrl/api/comments/${parentComment.id}/replies');
      if (response.statusCode == 200) {
        final List<dynamic> body = response.data;
        setState(() {
          parentComment.replies = body.map((dynamic item) => Comment.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('답글 로딩 중 에러: $e');
    } finally {
      setState(() => parentComment.areRepliesLoading = false);
    }
  }

  /// 답글 UI를 토글하는 함수
  void _toggleReplies(Comment parentComment) {
    setState(() {
      // 답글 창을 열 때, 이 댓글이 답글 대상임을 기억
      if (!parentComment.areRepliesVisible) {
        _replyingToComment = parentComment;
      }
      parentComment.areRepliesVisible = !parentComment.areRepliesVisible;
      if (parentComment.areRepliesVisible && parentComment.replies.isEmpty && parentComment.replyCount > 0) {
        _fetchReplies(parentComment);
      }
    });
  }

  /// [추가] 답글 달 대상을 지정하고 입력창에 @닉네임을 설정하는 함수
  void _prepareToReply(Comment parentComment, String usernameToReply) {
    setState(() {
      _replyingToComment = parentComment; // 답글 달 부모 댓글을 기억
      // 페이지에 하나뿐인 _replyController의 텍스트를 설정
      _replyController.text = '@$usernameToReply ';
      _replyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _replyController.text.length),
      );
    });
    // 키보드 포커스는 TextField 위젯 자체에서 관리하도록 유도하는 것이 더 안정적
  }

  /// [유지] 원본 좋아요/싫어요 로직
  void _handleLikeDislike(int commentId, {required bool isLike}) async {
    if (UserSession.nickname == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    final String url = '$apiBaseUrl/api/comments/$commentId/like';
    final String likeType = isLike ? 'LIKE' : 'DISLIKE';
    try {
      await _dio.post(
        url,
        data: {'nickname': UserSession.nickname, 'likeType': likeType},
      );
      setState(() {
        _commentsFuture = _fetchComments();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요청 처리에 실패했습니다.')));
    }
  }

  /// [수정] 원본 _addComment를 기반으로 답글 기능 추가
  void _addComment({Comment? parentComment}) async {
    final controller = parentComment == null ? _commentController : _replyController;
    final text = controller.text;

    if (text.trim().isEmpty) return;
    if (UserSession.nickname == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    try {
      final Map<String, dynamic> commentData = {
        'itemId': widget.weapon.id,
        'nickname': UserSession.nickname,
        'text': text,
        'parentId': parentComment?.id,
      };
      commentData.removeWhere((key, value) => value == null);

      await _dio.post('$apiBaseUrl/api/comments', data: commentData);

      setState(() {
        if (parentComment == null) {
          _commentsFuture = _fetchComments();
        } else {
          _fetchReplies(parentComment);
          parentComment.replyCount++;
        }
        controller.clear();
        FocusScope.of(context).unfocus();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 원본과 동일
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TopAppBar(title: widget.weapon.title),
      body: Column(
        children: [
          Expanded(child: PageView(controller: _pageController, children: [_buildImageViewer(widget.weapon.img2), _buildCommentsView()])),
          _buildPageIndicator(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    // 원본과 동일
    return GestureDetector(onTap: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (_, __, ___) => PhotoFullscreenViewer(imageUrl: imageUrl), transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child))), child: Card(color: Colors.grey[900], clipBehavior: Clip.antiAlias, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: InteractiveViewer(panEnabled: false, child: Center(child: Image.network(imageUrl, fit: BoxFit.contain)))));
  }
  Widget _buildPageIndicator() {
    // 원본과 동일
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(2, (index) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4)))));
  }

  Widget _buildCommentsView() {
    // 원본과 거의 동일
    return Card(
      color: Colors.grey[900],
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Comments', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Divider(color: Colors.white24, height: 24)])),
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.white70)));
                final comments = snapshot.data!.reversed.toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => _buildCommentThread(comments[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: UserSession.nickname != null ? '댓글을 입력하세요...' : '로그인이 필요합니다.',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.grey[400]), onPressed: UserSession.nickname != null ? () => _addComment() : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [수정] 댓글 + 답글 UI 구조
  Widget _buildCommentThread(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentItem(comment), // 원본 댓글 UI
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.replyCount > 0 || UserSession.nickname != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                    onPressed: () => _toggleReplies(comment),
                    child: Text(
                      comment.areRepliesVisible ? '답글 숨기기' : (comment.replyCount > 0 ? '${comment.replyCount}개의 답글 보기' : '답글 달기'),
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                if (comment.areRepliesVisible) _buildRepliesSection(comment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [유지] 원본 댓글 아이템 UI
  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: Colors.blueGrey[700], child: Text(comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(comment.comment, style: TextStyle(color: Colors.grey[300], height: 1.4, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Row(
            children: [
              IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.grey[400]), onPressed: () => _handleLikeDislike(comment.id, isLike: true)),
              Text(comment.likes.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(width: 16),
              IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(Icons.thumb_down_alt_outlined, color: Colors.grey[400]), onPressed: () => _handleLikeDislike(comment.id, isLike: false)),
              Text(comment.dislike.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  /// [수정] 답글 목록과 입력창 섹션 (이제 페이지의 _replyController를 사용)
  Widget _buildRepliesSection(Comment parentComment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parentComment.areRepliesLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
        if (!parentComment.areRepliesLoading)
          ...parentComment.replies.map((reply) => Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildReplyItem(reply, parentComment),
          )),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '답글 추가...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Colors.grey[400], size: 20),
                onPressed: () => _addComment(parentComment: _replyingToComment ?? parentComment),
              )
            ],
          ),
        )
      ],
    );
  }

  /// [추가] 답글 하나하나를 위한 UI 위젯
  Widget _buildReplyItem(Comment reply, Comment parentComment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: Colors.blueGrey[700], child: Text(reply.username.isNotEmpty ? reply.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reply.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(reply.comment, style: TextStyle(color: Colors.grey[300], height: 1.4, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Row(
            children: [
              IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.grey[400]), onPressed: () => _handleLikeDislike(reply.id, isLike: true)),
              Text(reply.likes.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(width: 16),
              IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(Icons.thumb_down_alt_outlined, color: Colors.grey[400]), onPressed: () => _handleLikeDislike(reply.id, isLike: false)),
              Text(reply.dislike.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _prepareToReply(parentComment, reply.username),
                child: Text('답글', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}