import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../controllers/discover_controller.dart';

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  double _maxDistance = 25;
  RangeValues _ageRange = const RangeValues(22, 35);
  bool _onlyVerified = true;
  bool _profilesWithMoreLikes = false;
  bool _onlyActiveNow = false;
  final List<String> _tags = [
    'Photography',
    'Music',
    'Travel',
    'Books',
    'Coffee',
    'Yoga',
    'Hiking',
    'Films',
    'Cooking',
  ];
  final Set<String> _selected = {'Photography', 'Travel'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      useGradient: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Material(
          color: isDark ? const Color(0xFF181818) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          elevation: isDark ? 0 : 2,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Discovery Preferences',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionTitle('Location & Distance', isDark),
                    const SizedBox(height: 8),
                    _buildValueRow('Maximum distance', _maxDistance >= 500 ? '500km+' : '${_maxDistance.round()} km', isDark),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        thumbColor: const Color(0xFF10B981),
                      ),
                      child: Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 500,
                        divisions: 100,
                        onChanged: (v) => setState(() => _maxDistance = v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Age Range', isDark),
                    const SizedBox(height: 8),
                    _buildValueRow('Between', '${_ageRange.start.round()} - ${_ageRange.end.round()}', isDark),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        thumbColor: const Color(0xFF10B981),
                      ),
                      child: RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 100,
                        divisions: 82,
                        onChanged: (v) => setState(() => _ageRange = v),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Filters', isDark),
                    const SizedBox(height: 8),
                    _buildSwitchTile('Only show verified profiles', _onlyVerified, (v) => setState(() => _onlyVerified = v), isDark),
                    _buildSwitchTile('Profiles with more likes', _profilesWithMoreLikes, (v) => setState(() => _profilesWithMoreLikes = v), isDark),
                    _buildSwitchTile('Only active now', _onlyActiveNow, (v) => setState(() => _onlyActiveNow = v), isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Interests', isDark),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((t) => _buildInterestChip(t, isDark)).toList(),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Save Preferences',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF064E3B),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildValueRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF10B981),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInterestChip(String t, bool isDark) {
    final selected = _selected.contains(t);
    return FilterChip(
      label: Text(t),
      selected: selected,
      onSelected: (val) {
        setState(() {
          if (val) _selected.add(t);
          else _selected.remove(t);
        });
      },
      selectedColor: const Color(0xFF10B981),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade300),
        ),
      ),
    );
  }
}
