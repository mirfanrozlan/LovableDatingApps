import 'package:flutter/material.dart';
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
  String? _chatId;

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
    super.dispose();
  }

  void _sendMessage() {
    final text = _input.text.trim();
    if (text.isEmpty || _chatId == null) return;

    _controller.sendMessage(_chatId!, text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat =
        ModalRoute.of(context)?.settings.arguments as ChatSummaryModel?;
    final name = chat?.name ?? 'Chat';

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          chat?.avatarUrl != null && chat!.avatarUrl!.isNotEmpty
                              ? NetworkImage(chat.avatarUrl!)
                              : null,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Fallback to initials if image fails
                      },
                      child:
                          chat?.avatarUrl == null || chat!.avatarUrl!.isEmpty
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Text(
                            'Available',
                          ), // Could fetch real status via getUser
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.call,
                            arguments: chat,
                          ),
                      icon: const Icon(Icons.call),
                    ),
                    IconButton(
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.videoCall,
                            arguments: chat,
                          ),
                      icon: const Icon(Icons.videocam),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                    ),
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
                  // Sort by timestamp descending usually for chat, but ListView.builder builds top down.
                  // Usually chat is reversed.
                  // For now, let's keep it simple.

                  if (msgs.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  return ListView.builder(
                    itemCount: msgs.length,
                    itemBuilder:
                        (context, i) => MessageBubble(
                          text: msgs[i].text,
                          isMe: msgs[i].isMe,
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
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
    );
  }
}
