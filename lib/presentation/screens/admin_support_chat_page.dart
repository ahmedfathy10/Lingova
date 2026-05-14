import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/support_message.dart';
import '../../data/services/support_api_service.dart';

class AdminSupportChatPage extends StatefulWidget {
  final String token;

  const AdminSupportChatPage({
    super.key,
    required this.token,
  });

  @override
  State<AdminSupportChatPage> createState() => _AdminSupportChatPageState();
}

class _AdminSupportChatPageState extends State<AdminSupportChatPage> {
  final _service = SupportApiService();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  static const Color primary = Color(0xFF0F6D5B);
  static const Color accent = Color(0xFF0F9D58);
  static const Color pageBg = Color(0xFFF7F5F1);
  static const Color chatBg = Color(0xFFF0F7F4);
  static const Color selectedChatBg = Color(0xFFE4F4EF);
  static const Color adminBubble = Color(0xFFD7F5E9);
  static const Color studentBubble = Colors.white;
  static const Color textMain = Color(0xFF202124);
  static const Color textMuted = Color(0xFF6B7280);

  List<SupportMessage> _messages = [];
  String? _selectedStudentId;

  bool _loading = true;
  bool _sending = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final messages = await _service.getAdminMessages(widget.token);

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _loading = false;

        if (_selectedStudentId == null && _conversations.isNotEmpty) {
          _selectedStudentId = _conversations.first.studentId;
        }
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);

      if (!silent) {
        _showMessage('تعذر تحميل الرسائل');
      }
    }
  }

  List<SupportMessage> get _conversations {
    final map = <String, SupportMessage>{};

    for (final message in _messages) {
      final current = map[message.studentId];

      if (current == null) {
        map[message.studentId] = message;
        continue;
      }

      final currentDate = DateTime.tryParse(current.createdAt);
      final nextDate = DateTime.tryParse(message.createdAt);

      if (currentDate == null || nextDate == null) {
        map[message.studentId] = message;
      } else if (nextDate.isAfter(currentDate)) {
        map[message.studentId] = message;
      }
    }

    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<SupportMessage> get _selectedMessages {
    final studentId = _selectedStudentId;
    if (studentId == null) return const [];

    final list = _messages
        .where((message) => message.studentId == studentId)
        .toList();

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  SupportMessage? get _selectedConversation {
    final studentId = _selectedStudentId;
    if (studentId == null) return null;

    for (final conversation in _conversations) {
      if (conversation.studentId == studentId) {
        return conversation;
      }
    }

    return null;
  }

  Future<void> _selectConversation(SupportMessage conversation) async {
    setState(() {
      _selectedStudentId = conversation.studentId;
    });

    try {
      await _service.markAdminMessagesRead(
        token: widget.token,
        studentId: conversation.studentId,
      );

      await _load(silent: true);
    } catch (_) {
      await _load(silent: true);
    }

    _scrollToBottom();
  }

  Future<void> _sendReply() async {
    final conversation = _selectedConversation;
    final text = _replyController.text.trim();

    if (conversation == null || text.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);

    try {
      await _service.sendAdminMessage(
        token: widget.token,
        studentId: conversation.studentId,
        message: text,
      );

      _replyController.clear();
      await _load(silent: true);
    } catch (_) {
      _showMessage('تعذر إرسال الرسالة');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  int _unreadCount(String studentId) {
    return _messages
        .where(
          (message) =>
              message.studentId == studentId &&
              message.sender == 'student' &&
              !message.readByAdmin,
        )
        .length;
  }

  String _formatTime(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '';

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _safeFirstLetter(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'م';
    return text.characters.first;
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerRight,
            color: primary,
            child: const Text(
              'رسائل الدعم',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد محادثات',
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final isSelected =
                          conversation.studentId == _selectedStudentId;
                      final unread = _unreadCount(conversation.studentId);

                      return Material(
                        color: isSelected ? selectedChatBg : Colors.white,
                        child: InkWell(
                          onTap: () => _selectConversation(conversation),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primary,
                                  child: Text(
                                    _safeFirstLetter(
                                      conversation.studentName,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        conversation.studentName.isEmpty
                                            ? conversation.studentPhone
                                            : conversation.studentName,
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: textMain,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        conversation.message,
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              unread > 0 ? textMain : textMuted,
                                          fontWeight: unread > 0
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text(
                                      _formatTime(conversation.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            unread > 0 ? accent : textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    if (unread > 0)
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: accent,
                                        child: Text(
                                          unread.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final isAdmin = message.sender == 'admin';

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
        decoration: BoxDecoration(
          color: isAdmin ? adminBubble : studentBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAdmin ? 18 : 4),
            bottomRight: Radius.circular(isAdmin ? 4 : 18),
          ),
          border: Border.all(
            color: isAdmin ? const Color(0xFFC6ECDD) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.045),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 5),
                  Icon(
                    message.readByStudent ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.readByStudent
                        ? Colors.blue
                        : Colors.grey.shade500,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final conversation = _selectedConversation;

    if (conversation == null) {
      return const Expanded(
        child: Center(
          child: Text(
            'اختر محادثة من القائمة',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final messages = _selectedMessages;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: primary,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white24,
                  child: Text(
                    _safeFirstLetter(conversation.studentName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        conversation.studentName.isEmpty
                            ? conversation.studentPhone
                            : conversation.studentName,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conversation.studentPhone,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: chatBg,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 15),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(messages[index]);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 5,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: textMain,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: primary,
                    decoration: InputDecoration(
                      hintText: 'اكتب ردك...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFA),
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
                          color: primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: primary,
                  child: IconButton(
                    onPressed: _sending ? null : _sendReply,
                    icon: _sending
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
    );
  }

  Widget _buildMobileLayout() {
    final conversation = _selectedConversation;

    if (conversation == null) {
      return _buildConversationsList();
    }

    return Column(
      children: [
        Container(
          height: 56,
          color: primary,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedStudentId = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  conversation.studentName.isEmpty
                      ? conversation.studentPhone
                      : conversation.studentName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        _buildChatArea(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: pageBg,
        child: isNarrow
            ? _buildMobileLayout()
            : Row(
                children: [
                  _buildConversationsList(),
                  _buildChatArea(),
                ],
              ),
      ),
    );
  }
}