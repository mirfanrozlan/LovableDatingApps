import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/privacy_controller.dart';
import '../../themes/theme.dart';

class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});

  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  late final PrivacyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrivacyController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1512), const Color(0xFF0A0F0D)]
                : [const Color(0xFFF0FDF8), const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
            stops: isDark ? null : const [0.0, 0.5, 1.0],
          ),
        ),
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
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          if (_controller.isLoading && _controller.privacy == null) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                          }

                          if (_controller.error != null && _controller.privacy == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Error: ${_controller.error}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    onPressed: _controller.loadPrivacy,
                                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }

                          final privacy = _controller.privacy;
                          if (privacy == null) {
                            return Center(child: Text('No privacy settings found.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)));
                          }

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Column(
                              children: [
                                _buildSection(
                                  title: 'Visibility',
                                  icon: Icons.visibility_outlined,
                                  isDark: isDark,
                                  children: [
                                    _buildSwitchTile(
                                      title: 'Show Profile',
                                      subtitle: 'Allow others to see your profile',
                                      value: privacy.showProfile,
                                      onChanged: _controller.toggleShowProfile,
                                      isDark: isDark,
                                    ),
                                    _buildSwitchTile(
                                      title: 'Incognito Mode',
                                      subtitle: 'Browse anonymously',
                                      value: privacy.showIncognito,
                                      onChanged: _controller.toggleShowIncognito,
                                      isDark: isDark,
                                    ),
                                    _buildSwitchTile(
                                      title: 'Show Age',
                                      subtitle: 'Display your age on your profile',
                                      value: privacy.showAge,
                                      onChanged: _controller.toggleShowAge,
                                      isDark: isDark,
                                      isLast: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildSection(
                                  title: 'Location',
                                  icon: Icons.location_on_outlined,
                                  isDark: isDark,
                                  children: [
                                    _buildSwitchTile(
                                      title: 'Show Distance',
                                      subtitle: 'Show how far you are from matches',
                                      value: privacy.showDistance,
                                      onChanged: _controller.toggleShowDistance,
                                      isDark: isDark,
                                    ),
                                    _buildSwitchTile(
                                      title: 'Precise Location',
                                      subtitle: 'Share your exact coordinates',
                                      value: privacy.showPrecise,
                                      onChanged: _controller.toggleShowPrecise,
                                      isDark: isDark,
                                      isLast: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildSection(
                                  title: 'Activity',
                                  icon: Icons.bolt_rounded,
                                  isDark: isDark,
                                  children: [
                                    _buildSwitchTile(
                                      title: 'Show Online Status',
                                      subtitle: 'Let others see when you are active',
                                      value: privacy.showStatus,
                                      onChanged: _controller.toggleShowStatus,
                                      isDark: isDark,
                                    ),
                                    _buildSwitchTile(
                                      title: 'Show Last Seen',
                                      subtitle: 'Display when you were last online',
                                      value: privacy.showPrevious,
                                      onChanged: _controller.toggleShowPrevious,
                                      isDark: isDark,
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
            'Privacy',
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
