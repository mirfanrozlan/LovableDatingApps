import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../services/messages_service.dart';
import '../../models/messages/chat_invite_model.dart';
import '../../models/messages/chat_summary_model.dart';
import '../../routes.dart';
import '../../models/user_model.dart';

class FriendsHomeView extends StatefulWidget {
  const FriendsHomeView({super.key});
  @override
  State<FriendsHomeView> createState() => _FriendsHomeViewState();
}

class _FriendsHomeViewState extends State<FriendsHomeView> {
  final _service = MessagesService();
  bool _loading = false;
  String? _error;
  List<ChatInviteModel> _invites = [];

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getInvites();
      setState(() {
        _invites = data.where((i) => i.friendStatus == 'accepted').toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openProfile(UserModel user) {
    Navigator.pushNamed(context, AppRoutes.userProfile, arguments: user.id);
  }

  void _startChat(UserModel user) {
    final chat = ChatSummaryModel(
      id: user.id.toString(),
      name: user.name,
      initials: user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
      avatarUrl: user.media,
      lastMessage: 'Say hi!',
      time: '',
      unread: 0,
    );
    Navigator.pushNamed(context, AppRoutes.chat, arguments: chat);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      useGradient: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Matches', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Container(
          color: Colors.transparent,
          child: RefreshIndicator(
            onRefresh: _loadInvites,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                if (_error != null) Center(child: Text('Error: $_error')),
                if (!_loading && _error == null && _invites.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No matches found'))),
                ..._invites.map((inv) => _MatchCard(
                      user: inv.user,
                      onViewProfile: () => _openProfile(inv.user),
                      onChat: () => _startChat(inv.user),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;
  const _MatchCard({required this.user, required this.onViewProfile, required this.onChat});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user.media.isNotEmpty ? NetworkImage(user.media) : null,
                    child: user.media.isEmpty ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?') : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          '${user.age}, ${user.gender} • ${user.city}, ${user.country}',
                          style: TextStyle(color: Colors.black.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (user.interests.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.interests,
                    style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: const Text('Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
