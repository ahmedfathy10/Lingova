import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/community_post.dart';
import '../../data/services/community_api_service.dart';

class AdminCommunityPage extends StatefulWidget {
  final String token;

  const AdminCommunityPage({super.key, required this.token});

  @override
  State<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends State<AdminCommunityPage> {
  final _service = CommunityApiService();
  late Future<List<CommunityPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _service.getAdminPosts(widget.token);
  }

  void _refresh() {
    setState(() => _postsFuture = _service.getAdminPosts(widget.token));
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await _confirm(
      title: 'حذف المنشور',
      message: 'هل تريد حذف هذا المنشور من المجتمع؟',
    );
    if (!confirmed) return;

    try {
      await _service.deletePost(token: widget.token, postId: post.id);
      _refresh();
      _showMessage('تم حذف المنشور.');
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _banUser(CommunityPost post) async {
    final confirmed = await _confirm(
      title: 'حظر المستخدم',
      message:
          'سيتم تعليق حساب ${post.authorName} ومنعه من تسجيل الدخول والنشر. هل أنت متأكد؟',
    );
    if (!confirmed) return;

    try {
      await _service.banUser(token: widget.token, studentId: post.studentId);
      _refresh();
      _showMessage('تم حظر المستخدم.');
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _deleteComment(
    CommunityPost post,
    CommunityComment comment,
  ) async {
    final confirmed = await _confirm(
      title: 'حذف التعليق',
      message: 'هل تريد حذف هذا التعليق؟',
    );
    if (!confirmed) return;

    try {
      await _service.deleteComment(
        token: widget.token,
        postId: post.id,
        commentId: comment.id,
      );
      _refresh();
      _showMessage('تم حذف التعليق.');
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title, textAlign: TextAlign.right),
            content: Text(message, textAlign: TextAlign.right),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: FutureBuilder<List<CommunityPost>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            final posts = snapshot.data ?? const <CommunityPost>[];
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'إدارة المجتمع',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'تابع المنشورات والتعليقات واحذف المحتوى غير المناسب أو احظر صاحبه.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  _AdminCommunityMessage(
                    message: 'تعذر تحميل منشورات المجتمع.',
                    onRetry: _refresh,
                  )
                else if (posts.isEmpty)
                  _AdminCommunityMessage(
                    message: 'لا توجد منشورات في المجتمع حالياً.',
                    onRetry: _refresh,
                  )
                else
                  ...posts.map(
                    (post) => _AdminCommunityPostCard(
                      post: post,
                      onDelete: () => _deletePost(post),
                      onBan: () => _banUser(post),
                      onDeleteComment: (comment) =>
                          _deleteComment(post, comment),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminCommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onDelete;
  final VoidCallback onBan;
  final ValueChanged<CommunityComment> onDeleteComment;

  const _AdminCommunityPostCard({
    required this.post,
    required this.onDelete,
    required this.onBan,
    required this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    final date = post.createdAt.isNotEmpty
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBan,
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('بان'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.message, textAlign: TextAlign.right),
          const SizedBox(height: 12),
          Text(
            '${post.likesCount} Like | ${post.dislikesCount} Dislike | ${post.commentsCount} Comments | ${post.sharesCount} Shares',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (post.comments.isNotEmpty) ...[
            const Divider(height: 22),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.authorName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف التعليق',
                          onPressed: () => onDeleteComment(comment),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.message, textAlign: TextAlign.right),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminCommunityMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminCommunityMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
