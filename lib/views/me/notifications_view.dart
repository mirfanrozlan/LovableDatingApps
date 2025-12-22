import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListView(
            children: const [
              ListTile(title: Text('Messages')),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('New Messages'),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Message Sounds'),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Message Previews'),
              ),
              Divider(),
              ListTile(title: Text('Matches')),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('New Matches'),
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text('Super Likes'),
              ),
              Divider(),
              ListTile(title: Text('Activity')),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Show Activity'),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Notify Likes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
