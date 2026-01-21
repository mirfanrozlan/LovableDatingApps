import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/discover_controller.dart';
import '../../controllers/moments_controller.dart';
import '../../models/discover_profile_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';
import '../../widgets/moments/moment_list.dart';
import '../../services/auth_service.dart';
import '../../services/moments_service.dart';

class DiscoverCardView extends StatefulWidget {
  const DiscoverCardView({super.key});

  @override
  State<DiscoverCardView> createState() => _DiscoverCardViewState();
}

class _DiscoverCardViewState extends State<DiscoverCardView> {
  final _controller = DiscoverController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _initController();
  }

  Future<void> _initController() async {
    final ms = MomentsService();
    final userId = await ms.getCurrentUserId();
    if (userId != null) {
      final prefs = await AuthService().getPreferences(userId);
      if (mounted && prefs != null) {
        String? gender = prefs['pref_gender']?.toString();
        int? minAge = int.tryParse(prefs['pref_age_min']?.toString() ?? '');
        int? maxAge = int.tryParse(prefs['pref_age_max']?.toString() ?? '');
        int? distance = int.tryParse(prefs['pref_location']?.toString() ?? '');

        _controller.updateFilters(
          gender: gender,
          minAge: minAge,
          maxAge: maxAge,
          distance: distance,
        );
        return;
      }
    }
    if (mounted) _controller.loadProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  _buildHeader(isDark),
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
                            ? _buildEmptyState(isDark)
                            : _CardStack(
                              controller: _controller,
                              isDark: isDark,
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

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.explore, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Discover',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        _PreferencesIconButton(isDark: isDark, onTap: _openPreferences),
      ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          Text(
                            'Discovery Preferences',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Attracted To',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            ['Male', 'Female'].map((g) {
                              final selected = gender == g;
                              return ChoiceChip(
                                label: Text(g),
                                selected: selected,
                                selectedColor: const Color(0xFF10B981),
                                labelStyle: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                                onSelected: (_) => setState(() => gender = g),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Age Range',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      RangeSlider(
                        values: RangeValues(
                          minAge.toDouble(),
                          maxAge.toDouble(),
                        ),
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
                        children: [Text('Min: $minAge'), Text('Max: $maxAge')],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Distance (km)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: distance.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (v) => setState(() => distance = v.round()),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('$distance km'),
                      ),
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
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Preferences updated'
                                      : 'Failed to update preferences',
                                ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Preferences'),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.1),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No more profiles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesIconButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _PreferencesIconButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.tune, color: Color(0xFF10B981)),
        ),
      ),
    );
  }
}

class _CardStack extends StatefulWidget {
  final DiscoverController controller;
  final bool isDark;

  const _CardStack({required this.controller, required this.isDark});

  @override
  State<_CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<_CardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _angle = (_dragOffset.dx / 300) * 0.26;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx > threshold) {
      _animateOut(Offset(screenWidth * 1.5, _dragOffset.dy), true);
    } else if (_dragOffset.dx < -threshold) {
      _animateOut(Offset(-screenWidth * 1.5, _dragOffset.dy), false);
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    final startOffset = _dragOffset;
    final startAngle = _angle;

    Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.reset();
    _animationController.duration = const Duration(milliseconds: 300);

    void listener() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, Offset.zero, animation.value)!;
        _angle = lerpDouble(startAngle, 0, animation.value)!;
      });
    }

    animation.addListener(listener);
    _animationController.forward().then((_) {
      animation.removeListener(listener);
    });
  }

  void _animateOut(Offset target, bool isLike) {
    final startOffset = _dragOffset;

    Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.reset();
    _animationController.duration = const Duration(milliseconds: 200);

    void listener() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, target, animation.value)!;
      });
    }

    animation.addListener(listener);
    _animationController.forward().then((_) {
      animation.removeListener(listener);
      _dragOffset = Offset.zero;
      _angle = 0;
      if (isLike) {
        widget.controller.like(widget.controller.profiles.first);
      } else {
        widget.controller.dislike(widget.controller.profiles.first);
      }
    });
  }

  void _triggerLike() {
    final screenWidth = MediaQuery.of(context).size.width;
    _animateOut(Offset(screenWidth * 1.5, 0), true);
  }

  void _triggerDislike() {
    final screenWidth = MediaQuery.of(context).size.width;
    _animateOut(Offset(-screenWidth * 1.5, 0), false);
  }

  double get _nextCardScale {
    final distance = _dragOffset.distance;
    final maxDistance = 300.0;
    final progress = (distance / maxDistance).clamp(0.0, 1.0);
    return 0.9 + (0.1 * progress);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.profiles.isEmpty) return const SizedBox();

    final p = widget.controller.profiles.first;
    final nextP =
        widget.controller.profiles.length > 1
            ? widget.controller.profiles[1]
            : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Card (Next)
        if (nextP != null)
          Positioned.fill(
            child: Center(
              child: Transform.scale(
                scale: _nextCardScale,
                child: _SingleCard(
                  p: nextP,
                  isBackground: true,
                  isDark: widget.isDark,
                ),
              ),
            ),
          ),

        // Foreground Card (Current)
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _angle,
                child: _SingleCard(
                  p: p,
                  controller: widget.controller,
                  onLike: _triggerLike,
                  onDislike: _triggerDislike,
                  isDark: widget.isDark,
                ),
              ),
            ),
          ),
        ),

        // Overlay indicators (Like/Nope)
        if (_isDragging)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  if (_dragOffset.dx > 20)
                    Positioned(
                      top: 60,
                      left: 40,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'LIKE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_dragOffset.dx < -20)
                    Positioned(
                      top: 60,
                      right: 40,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'REJECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SingleCard extends StatelessWidget {
  final DiscoverProfileModel p;
  final bool isBackground;
  final bool isDark;
  final DiscoverController? controller;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const _SingleCard({
    required this.p,
    required this.isDark,
    this.isBackground = false,
    this.controller,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBackground ? 0.1 : 0.3),
            blurRadius: isBackground ? 20 : 40,
            offset: Offset(0, isBackground ? 10 : 20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child:
                    p.media.isNotEmpty
                        ? Image.network(
                          p.media,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (ctx, err, stack) => Container(
                                color:
                                    isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFE5E7EB),
                                child: Icon(
                                  Icons.person,
                                  size: 100,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                        )
                        : Container(
                          color:
                              isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE5E7EB),
                          child: Icon(
                            Icons.person,
                            size: 100,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.name}, ${p.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (p.subscription == 'premium' ||
                          p.subscription == 'plus')
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (p.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        p.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (p.city.isNotEmpty || p.country.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${p.city}, ${p.country}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (p.interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          p.interests.take(3).map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!isBackground && controller != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          icon: Icons.close,
                          color: Colors.red,
                          size: 22,
                          onPressed: onDislike ?? () {},
                        ),
                        const SizedBox(width: 16),
                        _ActionButton(
                          icon: Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                          onPressed:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.discoverDetail,
                                arguments: p,
                              ),
                        ),
                        const SizedBox(width: 16),
                        _ActionButton(
                          icon: Icons.favorite,
                          color: const Color(0xFF10B981),
                          size: 22,
                          onPressed: onLike ?? () {},
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}
