import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/support_message.dart';
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
  final _scrollController = ScrollController();

  List<SupportMessage> _messages = [];
  AuthUser? _currentUser;

  bool _isLoading = true;
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final user = _currentUser ?? await AuthStorageService.loadUser();

      if (user == null) {
        throw Exception('لم يتم تسجيل الدخول.');
      }

      _currentUser = user;

      final messages = await _supportService.getMessages(studentId: user.id);

      if (!mounted) return;

      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!silent) {
        _showMessage('تعذر تحميل المحادثة.');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final user = _currentUser ?? await AuthStorageService.loadUser();

      if (user == null) {
        _showMessage('لم يتم تسجيل الدخول.');
        return;
      }

      await _supportService.createMessage(studentId: user.id, message: text);

      _messageController.clear();

      await _loadMessages(silent: true);
    } catch (_) {
      _showMessage('تعذر إرسال الرسالة.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(String value) {
    if (value.isEmpty) return '';

    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Widget _buildBubble(SupportMessage message) {
    final isMe = !message.isFromAdmin;

    final bubbleColor = isMe ? const Color(0xFFD9FDD3) : Colors.white;

    final textColor = isMe ? Colors.black87 : AppColors.textPrimary;

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    message.readByAdmin ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.readByAdmin ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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
      child: Scaffold(
        backgroundColor: const Color(0xFFECE5DD),
        appBar: AppBar(
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleSpacing: 0,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE8E8E8),
                child: Icon(Icons.support_agent, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الدعم المباشر',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'متصل الآن',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _loadMessages(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'ابدأ محادثتك مع الدعم الآن.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildBubble(_messages[index]);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: const Color(0xFF075E54),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: Color(0xFF075E54),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF075E54),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
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
