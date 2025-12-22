import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/discover_controller.dart';
import '../../models/discover_profile_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class DiscoverListView extends StatefulWidget {
  const DiscoverListView({super.key});

  @override
  State<DiscoverListView> createState() => _DiscoverListViewState();
}

class _DiscoverListViewState extends State<DiscoverListView> {
  final _controller = DiscoverController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    if (_controller.profiles.isEmpty) {
      _controller.loadProfiles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: const [
              Text('Discover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              Spacer(),
              Icon(Icons.view_agenda_outlined),
              SizedBox(width: 12),
              Icon(Icons.grid_view),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Browse and chat instantly',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _controller.loading && _controller.profiles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.profiles.isEmpty
                      ? const Center(child: Text('No profiles found'))
                      : ListView.separated(
                          itemCount: _controller.profiles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _DiscoverListCard(p: _controller.profiles[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverListCard extends StatelessWidget {
  final DiscoverProfileModel p;
  const _DiscoverListCard({required this.p});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.media.isNotEmpty
                  ? Image.network(
                      p.media,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          Container(color: Colors.grey.shade300, width: 64, height: 64),
                    )
                  : Container(color: Colors.grey.shade300, width: 64, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${p.name}, ${p.age}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  if (p.subscription == 'premium' || p.subscription == 'plus')
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                ]),
                Text('${p.city}, ${p.country}'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: p.interests.take(4).map((t) => _Chip(t)).toList(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.discoverDetail, arguments: p),
                    child: const Text('View Profile'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Chat'),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String t;
  const _Chip(this.t);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(t),
    );
  }
}
