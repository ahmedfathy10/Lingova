import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/community_post.dart';
import '../../data/services/auth_storage_service.dart';
import '../../data/services/community_api_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _communityService = CommunityApiService();
  final _postController = TextEditingController();
  late Future<List<CommunityPost>> _postsFuture;
  bool _isPosting = false;
  AuthUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<List<CommunityPost>> _loadPosts() async {
    _currentUser = await AuthStorageService.loadUser();
    return _communityService.getPosts(studentId: _currentUser?.id);
  }

  void _refreshPosts() {
    setState(() => _postsFuture = _loadPosts());
  }

  Future<void> _sendPost() async {
    final message = _postController.text.trim();
    if (message.isEmpty || _isPosting) {
      return;
    }

    final currentUser = _currentUser ?? await AuthStorageService.loadUser();
    if (currentUser == null) {
      _showMessage('لم يتم تسجيل الدخول.');
      return;
    }

    setState(() => _isPosting = true);
    try {
      await _communityService.createPost(
        studentId: currentUser.id,
        authorName: currentUser.fullName,
        message: message,
      );
      _postController.clear();
      _refreshPosts();
      _showMessage('تم نشر المنشور في المجتمع.');
    } on Exception catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _react(CommunityPost post, String reaction) async {
    final user = _currentUser ?? await AuthStorageService.loadUser();
    if (user == null) {
      _showMessage('لم يتم تسجيل الدخول.');
      return;
    }
    try {
      await _communityService.react(
        postId: post.id,
        studentId: user.id,
        reaction: reaction,
      );
      _refreshPosts();
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _comment(CommunityPost post, String message) async {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }
    final user = _currentUser ?? await AuthStorageService.loadUser();
    if (user == null) {
      _showMessage('لم يتم تسجيل الدخول.');
      return;
    }
    try {
      await _communityService.comment(
        postId: post.id,
        studentId: user.id,
        authorName: user.fullName,
        message: text,
      );
      _refreshPosts();
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _share(CommunityPost post) async {
    final user = _currentUser ?? await AuthStorageService.loadUser();
    if (user == null) {
      _showMessage('لم يتم تسجيل الدخول.');
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: '${post.authorName}\n${post.message}'),
    );
    try {
      await _communityService.share(postId: post.id, studentId: user.id);
      _refreshPosts();
    } catch (_) {}
    _showMessage('تم نسخ المنشور للمشاركة.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return _CommunityPostCard(
      post: post,
      onLike: () => _react(post, 'like'),
      onDislike: () => _react(post, 'dislike'),
      onComment: (message) => _comment(post, message),
      onShare: () => _share(post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مجتمع Lingova')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<CommunityPost>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'تعذر تحميل منشورات المجتمع الآن.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'لا توجد منشورات بعد. ابدأ بمشاركة تجربة أو سؤال.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _refreshPosts(),
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: posts.map(_buildPostCard).toList(),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        minLines: 1,
                        maxLines: 4,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: 'اكتب منشوراً للمجتمع',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isPosting ? null : _sendPost,
                      child: _isPosting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('نشر'),
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
}

class _CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final ValueChanged<String> onComment;
  final VoidCallback onShare;

  const _CommunityPostCard({
    required this.post,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  final _commentController = TextEditingController();
  bool _showComments = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final createdAt = post.createdAt.isNotEmpty
        ? post.createdAt.split('T').first
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.orangeSoft,
                child: Text(
                  post.authorName.isEmpty
                      ? 'L'
                      : post.authorName.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            '${post.likesCount} إعجاب  |  ${post.dislikesCount} عدم إعجاب  |  ${post.commentsCount} تعليق  |  ${post.sharesCount} مشاركة',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Divider(height: 22),
          Row(
            children: [
              _ActionButton(
                icon: Icons.thumb_up_alt_rounded,
                label: 'Like',
                active: post.userReaction == 'like',
                onTap: widget.onLike,
              ),
              _ActionButton(
                icon: Icons.thumb_down_alt_rounded,
                label: 'Dislike',
                active: post.userReaction == 'dislike',
                onTap: widget.onDislike,
              ),
              _ActionButton(
                icon: Icons.mode_comment_rounded,
                label: 'Comment',
                onTap: () => setState(() => _showComments = !_showComments),
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: widget.onShare,
              ),
            ],
          ),
          if (_showComments) ...[
            const SizedBox(height: 12),
            ...post.comments.map(
              (comment) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      comment.authorName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(comment.message, textAlign: TextAlign.right),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'اكتب تعليقاً',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final text = _commentController.text;
                    _commentController.clear();
                    widget.onComment(text);
                  },
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : AppColors.textMuted;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
    );
  }
}
