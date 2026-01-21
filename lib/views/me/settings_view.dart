import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../themes/theme.dart';
import '../../controllers/app/theme_controller.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';
import '../../services/moments_service.dart';
import '../../models/user_model.dart';
import '../../widgets/messages/app_bottom_nav.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _service = MomentsService();
  UserModel? _user;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await _service.getCurrentUserId();
      if (id != null) {
        final u = await _service.getUserDetails(id);
        setState(() {
          _user = u;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          children: [
                            // Profile Card (Glassmorphism)
                            _buildProfileCard(isDark),
                            
                            const SizedBox(height: 24),
                            
                            // Settings Group
                            _buildSettingsGroup(
                              isDark: isDark,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Notifications',
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                                  isDark: isDark,
                                ),
                                _buildSettingsTile(
                                  icon: Icons.lock_outline_rounded,
                                  title: 'Privacy',
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                                  isDark: isDark,
                                ),
                                _buildThemeToggle(isDark),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Logout Button
                            _buildLogoutButton(isDark),
                            
                            const SizedBox(height: 32),
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
            'Settings',
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

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              backgroundImage: (_user?.media.isNotEmpty ?? false) ? NetworkImage(_user!.media) : null,
              child: (_user?.media.isEmpty ?? true)
                  ? Text(
                      (_user?.name.isNotEmpty ?? false) ? _user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user != null 
                    ? '${_user!.age}, ${_user!.gender} • ${_user!.city}' 
                    : 'Fetching profile data',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF10B981), size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 20,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
      ],
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final ctrl = ThemeController.instance;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Switch.adaptive(
                value: ctrl.isDark,
                onChanged: ctrl.toggle,
                activeColor: const Color(0xFF10B981),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await AuthService().logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
