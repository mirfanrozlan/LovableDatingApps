import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../widgets/messages/message_bubble.dart';
import '../../controllers/messages/messages_controller.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final MessagesController _controller;
  final _input = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final chat =
        ModalRoute.of(context)?.settings.arguments as ChatSummaryModel?;
    final name = chat?.name ?? 'Chat';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Material(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              chat?.avatarUrl != null &&
                                      chat!.avatarUrl!.isNotEmpty
                                  ? NetworkImage(chat.avatarUrl!)
                                  : null,
                          child:
                              chat?.avatarUrl == null ||
                                      chat!.avatarUrl!.isEmpty
                                  ? Text(chat?.initials ?? '?')
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _controller.isTyping ? 'Typing…' : 'Available',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white60
                                          : Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _HeaderIcon(
                          icon: Icons.call,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.call,
                                arguments: chat,
                              ),
                        ),
                        const SizedBox(width: 6),
                        _HeaderIcon(
                          icon: Icons.videocam,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.videoCall,
                                arguments: chat,
                              ),
                        ),
                        const SizedBox(width: 6),
                        _HeaderIcon(icon: Icons.more_vert, onTap: () {}),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        });
                        _lastCount = msgs.length;
                      }
                      if (_controller.isTyping) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        });
                      }

                      if (msgs.isEmpty && !_controller.isTyping) {
                        return const Center(child: Text('No messages yet.'));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: msgs.length + (_controller.isTyping ? 1 : 0),
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
                const SizedBox(height: 8),
                Material(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          onChanged: (_) {
                            if (_chatId == null) return;
                            _controller.setTyping(_chatId!, true);
                            _typingTimer?.cancel();
                            _typingTimer = Timer(
                              const Duration(seconds: 2),
                              () {
                                if (_chatId != null) {
                                  _controller.setTyping(_chatId!, false);
                                }
                              },
                            );
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _HeaderIcon(icon: Icons.attach_file, onTap: () {}),
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(onPressed: onTap, icon: Icon(icon)),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          Alignment.centerLeft, // This keeps the container from stretching
      child: Container(
        margin: const EdgeInsets.only(right: 60, top: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(2),
          ),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6)],
        ),
        // REMOVE FittedBox if you just want it to wrap naturally
        child: const Text('Typing…', style: TextStyle(color: Colors.black54)),
      ),
    );
  }
}
