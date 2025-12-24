import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../themes/theme.dart';
import '../../controllers/app/theme_controller.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';
import '../../services/moments_service.dart';
import '../../models/user_model.dart';

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
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.brandGradient,
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (_user?.media.isNotEmpty ?? false) ? NetworkImage(_user!.media) : null,
                      child: (_user?.media.isEmpty ?? true)
                          ? Text(
                              (_user?.name.isNotEmpty ?? false) ? _user!.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.name ?? 'Your Name',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user != null ? '${_user!.age}, ${_user!.gender} • ${_user!.city}, ${_user!.country}' : 'Available',
                            style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: const Text('Account'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.account),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Privacy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                    ),
                    const Divider(height: 1),
                    AnimatedBuilder(
                      animation: ThemeController.instance,
                      builder: (context, _) {
                        final ctrl = ThemeController.instance;
                        return SwitchListTile(
                          value: ctrl.isDark,
                          onChanged: ctrl.toggle,
                          secondary: const Icon(Icons.dark_mode),
                          title: const Text('Dark Mode'),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                      }
                    },
                    child: const Text('Log Out'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
