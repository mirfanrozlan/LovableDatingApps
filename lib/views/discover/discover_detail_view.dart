import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../models/discover_profile_model.dart';

class DiscoverDetailView extends StatelessWidget {
  const DiscoverDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ModalRoute.of(context)?.settings.arguments as DiscoverProfileModel?;
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      useGradient: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: const [
            Text('Discover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            Spacer(),
            Icon(Icons.close)
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (p?.media.isNotEmpty ?? false)
                ? Image.network(
                    p!.media,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        Container(color: Colors.grey.shade300, height: 300),
                  )
                : Container(color: Colors.grey.shade300, height: 300),
          ),
          const SizedBox(height: 12),
          Text(
            '${p?.name ?? 'Profile'}, ${p?.age ?? ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on, size: 18),
            const SizedBox(width: 6),
            Text('${p?.city ?? ''}, ${p?.country ?? ''}')
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.school_outlined, size: 18),
            const SizedBox(width: 6),
            Text(p?.education ?? '')
          ]),
          const SizedBox(height: 12),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(p?.description ?? ''),
          const SizedBox(height: 12),
          const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (p?.interests ?? const [])
                .map((t) => Chip(label: Text(t)))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(onPressed: () {}, child: const Text('Chat')),
            ),
          ]),
        ],
      ),
    );
  }
}
