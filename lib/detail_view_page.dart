// lib/pages/detail_viewer_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forspeech/api_config.dart';
import 'package:forspeech/eweapon.dart';
import 'user_session.dart';
import 'etc.dart';
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
  final TextEditingController _commentController = TextEditingController();
  final Dio _dio = Dio();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  Comment? _replyingToComment;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _loadInitialComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialComments() async {
    setState(() => _isLoadingComments = true);
    String url = '$apiBaseUrl/api/comments/${widget.weapon.id}';
    if (UserSession.nickname != null) {
      url += '?nickname=${UserSession.nickname}';
    }

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> body = response.data;
        setState(() {
          _comments = body.map((dynamic item) => Comment.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('댓글 로딩 중 에러 발생: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _fetchReplies(Comment parentComment) async {
    setState(() => parentComment.areRepliesLoading = true);
    String url = '$apiBaseUrl/api/comments/${parentComment.id}/replies';
    if (UserSession.nickname != null) {
      url += '?nickname=${UserSession.nickname}';
    }

    try {
      final response = await _dio.get(url);
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

  void _handleLikeDislike(int commentId, {required bool isLike}) {
    if (UserSession.nickname == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final originalState = _updateCommentVoteStatus(commentId, isLike);
    if (originalState == null) return;

    final String url = '$apiBaseUrl/api/comments/$commentId/like';
    final String likeType = isLike ? 'LIKE' : 'DISLIKE';
    _dio.post(url, data: {'nickname': UserSession.nickname, 'likeType': likeType})
        .catchError((error) {
      print('좋아요/싫어요 요청 실패: $error');
      _rollbackCommentVoteStatus(commentId, originalState);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요청 처리에 실패했습니다.')));
    });
  }

  Map<String, dynamic>? _updateCommentVoteStatus(int targetId, bool isLikePressed) {
    Map<String, dynamic>? originalState;

    bool findAndUpdate(List<Comment> comments) {
      for (var comment in comments) {
        if (comment.id == targetId) {
          originalState = {
            'likes': comment.likes,
            'dislike': comment.dislike,
            'myLike': comment.myLike,
            'myDislike': comment.myDislike,
          };

          if (isLikePressed) {
            comment.myLike = !comment.myLike;
            comment.likes += comment.myLike ? 1 : -1;
          } else {
            comment.myDislike = !comment.myDislike;
            comment.dislike += comment.myDislike ? 1 : -1;
          }
          return true;
        }
        if (comment.replies.isNotEmpty && findAndUpdate(comment.replies)) {
          return true;
        }
      }
      return false;
    }

    setState(() {
      findAndUpdate(_comments);
    });

    return originalState;
  }

  void _rollbackCommentVoteStatus(int targetId, Map<String, dynamic> originalState) {
    bool findAndRollback(List<Comment> comments) {
      for (var comment in comments) {
        if (comment.id == targetId) {
          comment.likes = originalState['likes'];
          comment.dislike = originalState['dislike'];
          comment.myLike = originalState['myLike'];
          comment.myDislike = originalState['myDislike'];
          return true;
        }
        if (comment.replies.isNotEmpty && findAndRollback(comment.replies)) {
          return true;
        }
      }
      return false;
    }

    setState(() {
      findAndRollback(_comments);
    });
  }

  void _toggleReplies(Comment parentComment) {
    setState(() {
      parentComment.areRepliesVisible = !parentComment.areRepliesVisible;
      if (parentComment.areRepliesVisible && parentComment.replies.isEmpty && parentComment.replyCount > 0) {
        _fetchReplies(parentComment);
      }
    });
  }

  void _setReplyMode(Comment parentComment, {String? usernameToReply}) {
    setState(() {
      _replyingToComment = parentComment;
      _replyingToUsername = usernameToReply ?? parentComment.username;
      if (usernameToReply != null) {
        _commentController.text = '@$usernameToReply ';
        _commentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _commentController.text.length),
        );
      } else {
        _commentController.clear();
      }
      _commentFocusNode.requestFocus();
    });
  }

  void _toggleRepliesAndSetReplyMode(Comment comment) {
    _toggleReplies(comment);
    _setReplyMode(comment);
  }

  void _cancelReplyMode() {
    setState(() {
      _replyingToComment = null;
      _replyingToUsername = null;
      _commentController.clear();
      _commentFocusNode.unfocus();
    });
  }

  void _addComment() async {
    final text = _commentController.text;
    final parentComment = _replyingToComment;

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

      if (parentComment == null) {
        _loadInitialComments();
      } else {
        setState(() {
          parentComment.replyCount++;
        });
        _fetchReplies(parentComment);
      }
      _cancelReplyMode();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: 1,
              child: Image.asset(
                'assets/images/detail_view_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea( // SafeArea 추가하여 시스템 UI(상태바 등)를 피하도록 설정
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // [수정] Row를 사용하여 뒤로가기 버튼과 제목을 함께 배치
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
                                    onPressed: () => Navigator.of(context).pop(),
                                    padding: const EdgeInsets.only(right: 8), // 오른쪽 패딩 추가
                                    constraints: const BoxConstraints(),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.weapon.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 24)
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isLoadingComments
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : _comments.isEmpty
                              ? const Center(child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.white70)))
                              : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments.reversed.toList()[index];
                              return _buildCommentThread(comment);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            children: [
                              if (_replyingToComment != null) _buildReplyIndicator(),
                              TextField(
                                focusNode: _commentFocusNode,
                                controller: _commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: UserSession.nickname != null ? '댓글을 입력하세요...' : '로그인이 필요합니다.',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[850],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                  suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.grey[400]), onPressed: UserSession.nickname != null ? _addComment : null),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReplyIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "'${_replyingToUsername ?? ''}'님에게 답글 남기는 중...",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _cancelReplyMode,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text('취소', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.close, size: 16, color: Colors.grey[400]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentThread(Comment comment) {
    return Padding( // 이 부분을 추가
      padding: const EdgeInsets.only(bottom: 12.0), // 예를 들어 하단에 12.0 픽셀 패딩
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentItem(comment),
          if (comment.areRepliesVisible)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: _buildRepliesSection(comment),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final likeIcon = comment.myLike ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined;
    final dislikeIcon = comment.myDislike ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined;
    final likeColor = comment.myLike ? Colors.white : Colors.grey[400];
    final dislikeColor = comment.myDislike ? Colors.white : Colors.grey[400];

    return Container(
      height: 150.0,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        image: const DecorationImage(
          image: AssetImage('assets/images/commentbackground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleRepliesAndSetReplyMode(comment),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/comment.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
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
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Row(
                  children: [
                    IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(likeIcon, color: likeColor), onPressed: () => _handleLikeDislike(comment.id, isLike: true)),
                    Text(comment.likes.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    const SizedBox(width: 16),
                    IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(dislikeIcon, color: dislikeColor), onPressed: () => _handleLikeDislike(comment.id, isLike: false)),
                    Text(comment.dislike.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 18,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[400]),
                      onPressed: () => _setReplyMode(comment),
                    ),
                    if (comment.replyCount > 0)
                      Text(
                        comment.replyCount.toString(),
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepliesSection(Comment parentComment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parentComment.areRepliesLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
        if (!parentComment.areRepliesLoading)
          ...parentComment.replies.map((reply) => _buildReplyItem(reply, parentComment)),
      ],
    );
  }

  Widget _buildReplyItem(Comment reply, Comment parentComment) {
    final likeIcon = reply.myLike ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined;
    final dislikeIcon = reply.myDislike ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined;
    final likeColor = reply.myLike ? Colors.white : Colors.grey[400];
    final dislikeColor = reply.myDislike ? Colors.white : Colors.grey[400];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        image: const DecorationImage(
          image: AssetImage('assets/images/commentbackground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _setReplyMode(parentComment, usernameToReply: reply.username),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/comment.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, bottom: 8),
            child: Row(
              children: [
                IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(likeIcon, color: likeColor), onPressed: () => _handleLikeDislike(reply.id, isLike: true)),
                Text(reply.likes.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(width: 16),
                IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: Icon(dislikeIcon, color: dislikeColor), onPressed: () => _handleLikeDislike(reply.id, isLike: false)),
                Text(reply.dislike.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}