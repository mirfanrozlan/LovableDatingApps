import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Location & Distance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_maxDistance.round()} km',
                onChanged: (v) => setState(() => _maxDistance = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Age Range',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 100,
                divisions: 82,
                labels: RangeLabels(
                  '${_ageRange.start.round()}',
                  '${_ageRange.end.round()}',
                ),
                onChanged: (v) => setState(() => _ageRange = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SwitchListTile(
                value: _onlyVerified,
                onChanged: (v) => setState(() => _onlyVerified = v),
                title: const Text('Only show verified profiles'),
              ),
              SwitchListTile(
                value: _profilesWithMoreLikes,
                onChanged: (v) => setState(() => _profilesWithMoreLikes = v),
                title: const Text('Profiles with more likes/matches'),
              ),
              SwitchListTile(
                value: _onlyActiveNow,
                onChanged: (v) => setState(() => _onlyActiveNow = v),
                title: const Text('Only active now'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Interests',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _tags
                        .map(
                          (t) => FilterChip(
                            label: Text(t),
                            selected: _selected.contains(t),
                            onSelected:
                                (sel) => setState(() {
                                  if (sel)
                                    _selected.add(t);
                                  else
                                    _selected.remove(t);
                                }),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
