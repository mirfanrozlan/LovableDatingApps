import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/privacy_controller.dart';

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
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.isLoading && _controller.privacy == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.error != null && _controller.privacy == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${_controller.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _controller.loadPrivacy,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final privacy = _controller.privacy;
              if (privacy == null) {
                return const Center(child: Text('No privacy settings found.'));
              }

              return ListView(
                children: [
                  const ListTile(
                    title: Text(
                      'Profile Visibility',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SwitchListTile(
                    value: privacy.showProfile,
                    onChanged: _controller.toggleShowProfile,
                    title: const Text('Show Profile'),
                    subtitle: const Text('Allow others to see your profile'),
                  ),
                  SwitchListTile(
                    value: privacy.showIncognito,
                    onChanged: _controller.toggleShowIncognito,
                    title: const Text('Incognito Mode'),
                    subtitle: const Text('Browse anonymously'),
                  ),
                  SwitchListTile(
                    value: privacy.showAge,
                    onChanged: _controller.toggleShowAge,
                    title: const Text('Show Age'),
                  ),
                  const Divider(),
                  const ListTile(
                    title: Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SwitchListTile(
                    value: privacy.showDistance,
                    onChanged: _controller.toggleShowDistance,
                    title: const Text('Show Distance'),
                  ),
                  SwitchListTile(
                    value: privacy.showPrecise,
                    onChanged: _controller.toggleShowPrecise,
                    title: const Text('Precise Location'),
                    subtitle: const Text('Share your exact location'),
                  ),
                  const Divider(),
                  const ListTile(
                    title: Text(
                      'Activity Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SwitchListTile(
                    value: privacy.showStatus,
                    onChanged: _controller.toggleShowStatus,
                    title: const Text('Show Online Status'),
                  ),
                  SwitchListTile(
                    value: privacy.showPrevious,
                    onChanged: _controller.toggleShowPrevious,
                    title: const Text('Show Last Seen'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
