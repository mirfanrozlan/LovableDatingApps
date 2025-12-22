import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../themes/theme.dart';
import '../../controllers/app/theme_controller.dart';
import '../../routes.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
          child: Column(
            children: [
              const CircleAvatar(radius: 30, child: Text('YU')),
              const SizedBox(height: 8),
              const Text(
                'Your Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Available',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.pushNamed(context, AppRoutes.editProfile),
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Account'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () =>
                                Navigator.pushNamed(context, AppRoutes.account),
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.notifications,
                            ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Privacy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () =>
                                Navigator.pushNamed(context, AppRoutes.privacy),
                      ),
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
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () => Navigator.pushNamed(context, AppRoutes.help),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed:
                              () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              ),
                          child: const Text('Log Out'),
                        ),
                      ),
                    ],
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
