import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/support_message.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_storage_service.dart';
import '../../data/services/support_api_service.dart';

class LiveSupportPage extends StatefulWidget {
  const LiveSupportPage({super.key});

  @override
  State<LiveSupportPage> createState() => _LiveSupportPageState();
}

class _LiveSupportPageState extends State<LiveSupportPage> {
  final _supportService = SupportApiService();
  final _messageController = TextEditingController();
  late Future<List<SupportMessage>> _messagesFuture;
  bool _isSending = false;
  AuthUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<SupportMessage>> _loadMessages() async {
    final user = await AuthStorageService.loadUser();
    if (user == null) {
      throw Exception('لم يتم تسجيل الدخول.');
    }
    _currentUser = user;
    return _supportService.getMessages(studentId: user.id);
  }

  void _refreshMessages() {
    setState(() {
      _messagesFuture = _loadMessages();
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = _currentUser ?? await AuthStorageService.loadUser();
      if (currentUser == null) {
        _showMessage('لم يتم تسجيل الدخول.');
        return;
      }

      await _supportService.createMessage(
        studentId: currentUser.id,
        message: message,
      );
      _messageController.clear();
      _refreshMessages();
      _showMessage('تم إرسال الرسالة. سيقوم الدعم بالرد قريباً.');
    } on Exception catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
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

  Widget _buildMessageCard(SupportMessage message) {
    final createdAt = message.createdAt.isNotEmpty
        ? message.createdAt.split('T').first
        : '';

    final isAdminMessage = message.message.trim().isEmpty && message.answer.trim().isNotEmpty;

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
          Text(
            isAdminMessage ? 'رسالة من الإدارة' : 'سؤالك',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isAdminMessage ? message.answer : message.message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdminMessage ? 'رسالة واردة من الإدارة' : message.isAnswered ? 'تم الرد' : 'قيد الانتظار',
                style: TextStyle(
                  color: isAdminMessage
                      ? Colors.green
                      : message.isAnswered
                          ? Colors.green
                          : AppColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                createdAt,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          if (!isAdminMessage && message.isAnswered) ...[
            const Divider(height: 30),
            Text(
              'الرد:',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message.answer,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15),
            ),
          ],
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
          title: const Text('الشات المباشر'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<SupportMessage>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'تعذر تحميل المحادثة. حاول مرة أخرى.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'لا توجد رسائل دعم بعد. أرسل أول رسالة الآن.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(22),
                      children: messages.map(_buildMessageCard).toList(),
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
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك للأدارة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إرسال'),
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
