import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../widgets/messages/message_bubble.dart';
import '../../controllers/messages/messages_controller.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';
import '../../services/signaling.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final MessagesController _controller;
  final _input = TextEditingController();
  final _signaling = Signaling();
  final _scrollController = ScrollController();
  String? _chatId;
  Timer? _typingTimer;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = MessagesController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chat =
        ModalRoute.of(context)?.settings.arguments as ChatSummaryModel?;
    if (chat != null && _chatId == null) {
      _chatId = chat.id;
      _controller.connectToChat(_chatId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _input.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _input.text.trim();
    if (text.isEmpty || _chatId == null) return;

    _controller.sendMessage(_chatId!, text);
    _input.clear();
    _typingTimer?.cancel();
    _controller.setTyping(_chatId!, false);
  }

  Future<void> initCall(ChatSummaryModel? chat, int vidType) async {
    if (chat == null) return;
    final ctrl = _controller;
    final calleeId = int.tryParse(chat.id ?? '');
    final meId = await FlutterSecureStorage()
        .read(key: 'user_id')
        .then((v) => int.tryParse(v ?? ''));

    if (calleeId == null) return;
    if (meId == null) return;

    final a = meId <= calleeId ? meId : calleeId;
    final b = meId <= calleeId ? calleeId : meId;
    final roomId = 'vc_${a}_${b}_${DateTime.now().millisecondsSinceEpoch}';

    // _signaling.createRoom(roomId) is moved to VideoCallView to ensure same instance usage

    if (mounted) {
      if (vidType == 1) {
        Navigator.pushNamed(
          context,
          AppRoutes.videoCall,
          arguments: {
            'roomId': roomId,
            'isCaller': true,
            'chat': chat,
            'type': vidType,
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.call,
          arguments: {
            'roomId': roomId,
            'isCaller': true,
            'chat': chat,
            'type': vidType,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat =
        ModalRoute.of(context)?.settings.arguments as ChatSummaryModel?;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF0F1512), const Color(0xFF0A0F0D)]
                    : [
                      const Color(0xFFF0FDF8),
                      const Color(0xFFECFDF5),
                      const Color(0xFFD1FAE5),
                    ],
          ),
        ),
        child: Stack(
          children: [
            _buildDecorativeCircle(
              top: -50,
              right: -50,
              color: const Color(0xFF10B981),
              opacity: isDark ? 0.15 : 0.2,
            ),
            _buildDecorativeCircle(
              top: 200,
              left: -80,
              color: const Color(0xFF34D399),
              opacity: isDark ? 0.08 : 0.12,
            ),

            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(chat, isDark),

                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final msgs =
                              _chatId != null
                                  ? _controller.getConversation(_chatId!)
                                  : [];
                          if (msgs.length != _lastCount) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                            _lastCount = msgs.length;
                          }

                          if (msgs.isEmpty && !_controller.isTyping) {
                            return Center(
                              child: Text(
                                'No messages yet.',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount:
                                msgs.length + (_controller.isTyping ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (_controller.isTyping && i == msgs.length) {
                                return const _TypingBubble();
                              }
                              final m = msgs[i];
                              return MessageBubble(
                                text: m.text,
                                isMe: m.isMe,
                                timestamp: m.timestamp,
                                largeEmoji: m.largeEmoji,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    _buildMessageInput(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatSummaryModel? chat, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.2)
                      : const Color(0xFF10B981).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    isDark ? const Color(0xFF1A1A1A) : Colors.white,
                backgroundImage:
                    chat?.avatarUrl != null && chat!.avatarUrl!.isNotEmpty
                        ? NetworkImage(chat.avatarUrl!)
                        : null,
                child:
                    chat?.avatarUrl == null || chat!.avatarUrl!.isEmpty
                        ? Text(
                          chat?.initials ?? '?',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat?.name ?? 'Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                    ),
                  ),
                  Text(
                    _controller.isTyping ? 'typing...' : 'online',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _controller.isTyping
                              ? const Color(0xFF10B981)
                              : (isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            _HeaderIcon(
              icon: Icons.call_rounded,
              onTap: () => initCall(chat, 0),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.videocam_rounded,
              onTap: () => initCall(chat, 1),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.2)
                      : const Color(0xFF10B981).withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: const Color(0xFF10B981),
                size: 26,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _input,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) {
                  if (_chatId == null) return;
                  _controller.setTyping(_chatId!, true);
                  _typingTimer?.cancel();
                  _typingTimer = Timer(const Duration(seconds: 2), () {
                    if (_chatId != null) _controller.setTyping(_chatId!, false);
                  });
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle({
    required double top,
    double? right,
    double? left,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF10B981), size: 20),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border:
              isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '...',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
