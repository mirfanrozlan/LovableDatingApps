import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/discover_controller.dart';
import '../../models/discover_profile_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/moments_service.dart';

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
            Row(children: [
              const Text('Discover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const Spacer(),
              _PreferencesIconButton(onTap: _openPreferences),
              const SizedBox(width: 8),
              const Icon(Icons.view_agenda_outlined),
              const SizedBox(width: 12),
              const Icon(Icons.grid_view),
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

  Future<void> _openPreferences() async {
    final ms = MomentsService();
    final userId = await ms.getCurrentUserId();
    if (userId == null) return;
    final prefs = await AuthService().getPreferences(userId);
    String gender = (prefs?['pref_gender'] ?? 'Male').toString();
    int minAge = (prefs?['pref_age_min'] ?? 18) is int
        ? (prefs?['pref_age_min'] ?? 18)
        : int.tryParse((prefs?['pref_age_min'] ?? '18').toString()) ?? 18;
    int maxAge = (prefs?['pref_age_max'] ?? 80) is int
        ? (prefs?['pref_age_max'] ?? 80)
        : int.tryParse((prefs?['pref_age_max'] ?? '80').toString()) ?? 80;
    int distance = (prefs?['pref_location'] ?? 25) is int
        ? (prefs?['pref_location'] ?? 25)
        : int.tryParse((prefs?['pref_location'] ?? '25').toString()) ?? 25;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Discovery Preferences', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Attracted To', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Male', 'Female', 'Non-Binary'].map((g) {
                        final selected = gender == g;
                        return ChoiceChip(
                          label: Text(g),
                          selected: selected,
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                          onSelected: (_) => setState(() => gender = g),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Age Range', style: TextStyle(fontWeight: FontWeight.w600)),
                    RangeSlider(
                      values: RangeValues(minAge.toDouble(), maxAge.toDouble()),
                      min: 18,
                      max: 100,
                      divisions: 82,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) {
                        setState(() {
                          minAge = v.start.round();
                          maxAge = v.end.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: $minAge'),
                        Text('Max: $maxAge'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Distance (km)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: distance.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => distance = v.round()),
                    ),
                    Align(alignment: Alignment.centerRight, child: Text('$distance km')),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await AuthService().updateProfile(
                          userId: userId,
                          username: '',
                          gender: '',
                          age: 0,
                          bio: '',
                          education: '',
                          address: '',
                          postcode: '',
                          state: '',
                          city: '',
                          country: '',
                          interests: '',
                          email: '',
                          phone: '',
                          prefGender: gender,
                          prefAgeMin: minAge,
                          prefAgeMax: maxAge,
                          prefLocation: distance,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Preferences updated' : 'Failed to update preferences')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Preferences'),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
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

class _PreferencesIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PreferencesIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.tune, color: Color(0xFF10B981)),
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
