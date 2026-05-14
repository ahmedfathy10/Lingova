import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/community_post.dart';
import '../../data/models/auth_user.dart';
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
    return _communityService.getPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _loadPosts();
    });
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

    setState(() {
      _isPosting = true;
    });

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
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final createdAt = post.createdAt.isNotEmpty
        ? post.createdAt.split('T').first
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                post.authorName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                createdAt,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مجتمع Lingova'),
        ),
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
                            'لا توجد منشورات بعد. ابدأ بمشاركة تجربةً أو سؤالاً.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(22),
                      children: posts.map(_buildPostCard).toList(),
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
