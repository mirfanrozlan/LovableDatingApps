import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  // Mock states for interactive switches
  bool _newMessages = true;
  bool _messageSounds = true;
  bool _messagePreviews = true;
  bool _newMatches = true;
  bool _superLikes = false;
  bool _showActivity = true;
  bool _notifyLikes = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      child: Container(
        decoration: isDark ? AppTheme.pageDecorationDark : AppTheme.pageDecoration,
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeCircle(top: -50, right: -50, color: const Color(0xFF10B981), opacity: isDark ? 0.15 : 0.2),
            _buildDecorativeCircle(top: 200, left: -80, color: const Color(0xFF34D399), opacity: isDark ? 0.08 : 0.12),

            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(isDark),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          children: [
                            _buildSection(
                              title: 'Messages',
                              icon: Icons.chat_bubble_outline_rounded,
                              isDark: isDark,
                              children: [
                                _buildSwitchTile(
                                  title: 'New Messages',
                                  subtitle: 'Receive notifications when you get a message',
                                  value: _newMessages,
                                  onChanged: (v) => setState(() => _newMessages = v),
                                  isDark: isDark,
                                ),
                                _buildSwitchTile(
                                  title: 'Message Sounds',
                                  subtitle: 'Play a sound for incoming messages',
                                  value: _messageSounds,
                                  onChanged: (v) => setState(() => _messageSounds = v),
                                  isDark: isDark,
                                ),
                                _buildSwitchTile(
                                  title: 'Message Previews',
                                  subtitle: 'Show message text in notifications',
                                  value: _messagePreviews,
                                  onChanged: (v) => setState(() => _messagePreviews = v),
                                  isDark: isDark,
                                  isLast: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              title: 'Matches',
                              icon: Icons.favorite_border_rounded,
                              isDark: isDark,
                              children: [
                                _buildSwitchTile(
                                  title: 'New Matches',
                                  subtitle: 'When you get a new match',
                                  value: _newMatches,
                                  onChanged: (v) => setState(() => _newMatches = v),
                                  isDark: isDark,
                                ),
                                _buildSwitchTile(
                                  title: 'Super Likes',
                                  subtitle: 'When someone super likes you',
                                  value: _superLikes,
                                  onChanged: (v) => setState(() => _superLikes = v),
                                  isDark: isDark,
                                  isLast: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              title: 'Activity',
                              icon: Icons.notifications_none_rounded,
                              isDark: isDark,
                              children: [
                                _buildSwitchTile(
                                  title: 'Show Activity',
                                  subtitle: 'Notifications about your account activity',
                                  value: _showActivity,
                                  onChanged: (v) => setState(() => _showActivity = v),
                                  isDark: isDark,
                                ),
                                _buildSwitchTile(
                                  title: 'Notify Likes',
                                  subtitle: 'When someone likes your moments',
                                  value: _notifyLikes,
                                  onChanged: (v) => setState(() => _notifyLikes = v),
                                  isDark: isDark,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF064E3B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF064E3B),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
      ],
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
