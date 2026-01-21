import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/discover_controller.dart';
import '../../models/discover_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/moments_service.dart';
import '../../routes.dart';
import '../../themes/theme.dart';

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
    if (mounted && _controller.profiles.isEmpty) {
      _controller.loadProfiles();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF064E3B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _PreferencesIconButton(onTap: _openPreferences),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Browse and chat instantly',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        _controller.loading && _controller.profiles.isEmpty
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF10B981),
                                ),
                              )
                            : _controller.profiles.isEmpty
                            ? Center(
                                child: Text(
                                  'No profiles found',
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.separated(
                              itemCount: _controller.profiles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _DiscoverListCard(p: _controller.profiles[i]),
                            ),
                  ),
                ],
              ),
            ),
          ),
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
    int minAge =
        (prefs?['pref_age_min'] ?? 18) is int
            ? (prefs?['pref_age_min'] ?? 18)
            : int.tryParse((prefs?['pref_age_min'] ?? '18').toString()) ?? 18;
    int maxAge =
        (prefs?['pref_age_max'] ?? 80) is int
            ? (prefs?['pref_age_max'] ?? 80)
            : int.tryParse((prefs?['pref_age_max'] ?? '80').toString()) ?? 80;
    int distance =
        (prefs?['pref_location'] ?? 25) is int
            ? (prefs?['pref_location'] ?? 25)
            : int.tryParse((prefs?['pref_location'] ?? '25').toString()) ?? 25;

    if (!mounted) return;
    final isDarkGlobal = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkGlobal ? const Color(0xFF121212) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final labelStyle = TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            );
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Color(0xFF10B981)),
                          const SizedBox(width: 12),
                          Text(
                            'Discovery Preferences',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF064E3B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(height: 8),
                      const SizedBox(height: 16),
                      Text('Attracted To', style: labelStyle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: ['Male', 'Female', 'Both'].map((g) {
                          final isSelected = gender == g;
                          return ChoiceChip(
                            label: Text(g),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => gender = g);
                            },
                            selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                            backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white12 : Colors.transparent),
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Age Range', style: labelStyle),
                          Text(
                            '$minAge - $maxAge',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF10B981),
                          inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          thumbColor: const Color(0xFF10B981),
                          overlayColor: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                        child: RangeSlider(
                          values: RangeValues(minAge.toDouble(), maxAge.toDouble()),
                          min: 18,
                          max: 100,
                          divisions: 82,
                          onChanged: (v) {
                            setModalState(() {
                              minAge = v.start.round();
                              maxAge = v.end.round();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Maximum Distance', style: labelStyle),
                          Text(
                            '$distance km',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF10B981),
                          inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          thumbColor: const Color(0xFF10B981),
                        ),
                        child: Slider(
                          value: distance.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          onChanged: (v) => setModalState(() => distance = v.round()),
                        ),
                      ),
                      const SizedBox(height: 40),
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
                              SnackBar(
                                content: Text(ok ? 'Preferences updated' : 'Update failed'),
                                backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
                              ),
                            );
                            if (ok) {
                              _controller.updateFilters(
                                gender: gender,
                                minAge: minAge,
                                maxAge: maxAge,
                                distance: distance,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DiscoverListCard extends StatelessWidget {
  final DiscoverProfileModel p;
  const _DiscoverListCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.discoverDetail,
            arguments: p,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: p.media.isNotEmpty
                      ? Image.network(
                          p.media,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${p.age}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                        if (p.subscription == 'premium') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.city.isNotEmpty ? '${p.city}, ${p.country}' : 'Nearby',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (p.interests.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: p.interests.take(2).map((i) => _buildMiniChip(i, isDark)).toList(),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
      child: Icon(Icons.person, color: isDark ? Colors.white10 : Colors.black12, size: 40),
    );
  }

  Widget _buildMiniChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFDCFCE7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF10B981),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
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
