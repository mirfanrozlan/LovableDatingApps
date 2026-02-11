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
import 'location_search_sheet.dart';

class DiscoverCardView extends StatefulWidget {
  const DiscoverCardView({super.key});

  @override
  State<DiscoverCardView> createState() => _DiscoverCardViewState();
}

class _DiscoverCardViewState extends State<DiscoverCardView> {
  final _controller = DiscoverController();
  final ScrollController _scrollController = ScrollController();
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    // Set up match callback to show match dialog
    _controller.onMatch = (profile) {
      if (mounted) {
        _showMatchDialog(profile);
      }
    };
    _scrollController.addListener(_onScroll);
    _initController();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_controller.loading &&
        _controller.hasMore) {
      _controller.loadProfiles();
    }
  }

  void _showMatchDialog(DiscoverProfileModel profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [const Color(0xFF1a1a1a), const Color(0xFF0a0a0a)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "It's a Match! 🎉",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF064E3B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You and ${profile.name} liked each other!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Keep Swiping',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to messages/chat with the matched user
                            Navigator.pushNamed(context, AppRoutes.messages);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Say Hello!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
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
        int? maxDistance = int.tryParse(
          prefs['pref_location']?.toString() ?? '',
        );
        if (maxDistance != null && maxDistance < 1) {
          maxDistance = 100;
        }

        _controller.updateFilters(
          gender: gender,
          minAge: minAge,
          maxAge: maxAge,
          maxDistance: maxDistance,
        );
        return;
      }
    }
    if (mounted) _controller.loadProfiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                            : _isListView
                                ? _buildListView(isDark)
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

  Widget _buildListView(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFF10B981).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _controller.profiles.length + (_controller.loading ? 1 : 0),
        separatorBuilder: (context, index) {
          return Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color:
                isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade100,
          );
        },
        itemBuilder: (context, index) {
          if (index == _controller.profiles.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            );
          }
          final p = _controller.profiles[index];
          return _ListCard(
            p: p,
            isDark: isDark,
            onRequestChat: () => _controller.like(p),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.discoverDetail,
              arguments: p,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Find Nearby Button (Top Left)
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LocationSearchSheet(),
              );
            },
            icon: Icon(
              Icons.location_on_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Find Nearby',
          ),
        ),
        // Title
        Text(
          'Discover',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        // View Toggle & Filter Button
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => setState(() => _isListView = !_isListView),
                icon: Icon(
                  _isListView ? Icons.style_rounded : Icons.grid_view_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                tooltip: _isListView ? 'Card View' : 'List View',
              ),
              IconButton(
                onPressed: _openPreferences,
                icon: Icon(
                  Icons.tune_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                tooltip: 'Filters',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openPreferences() async {
    final ms = MomentsService();
    final userId = await ms.getCurrentUserId();
    if (userId == null) return;

    // Local state for modal
    String gender = _controller.gender ?? 'male';
    int minAge = _controller.minAge ?? 18;
    int maxAge = _controller.maxAge ?? 80;
    int maxDistance = _controller.maxDistance;

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
                          const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Discovery Preferences',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF064E3B),
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
                        children:
                            ['Male', 'Female'].map((g) {
                              final isSelected = gender == g;
                              return ChoiceChip(
                                label: Text(g),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setModalState(() => gender = g);
                                },
                                selectedColor: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.15),
                                backgroundColor:
                                    isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? const Color(0xFF10B981)
                                            : (isDark
                                                ? Colors.white12
                                                : Colors.transparent),
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
                          inactiveTrackColor:
                              isDark ? Colors.white10 : Colors.grey.shade200,
                          thumbColor: const Color(0xFF10B981),
                          overlayColor: const Color(
                            0xFF10B981,
                          ).withOpacity(0.2),
                        ),
                        child: RangeSlider(
                          values: RangeValues(
                            minAge.toDouble(),
                            maxAge.toDouble(),
                          ),
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
                            prefLocation: maxDistance,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? 'Preferences updated' : 'Update failed',
                                ),
                                backgroundColor:
                                    ok ? const Color(0xFF10B981) : Colors.red,
                              ),
                            );
                            if (ok) {
                              _controller.updateFilters(
                                gender: gender,
                                minAge: minAge,
                                maxAge: maxAge,
                                maxDistance: maxDistance,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Finalize the theme state if we changed it in the modal but didn't save?
      // Actually setDiscoveryDarkMode(val) updates it immediately.
    });
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
                  if (p.city.isNotEmpty ||
                      p.country.isNotEmpty ||
                      p.distance > 0)
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
                            '${p.city}, ${p.country}${p.distance > 0 ? " • ${p.distance.toStringAsFixed(0)} km" : ""}',
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

class _ListCard extends StatelessWidget {
  final DiscoverProfileModel p;
  final bool isDark;
  final VoidCallback onRequestChat;
  final VoidCallback onTap;

  const _ListCard({
    required this.p,
    required this.isDark,
    required this.onRequestChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  backgroundImage:
                      p.media.isNotEmpty ? NetworkImage(p.media) : null,
                  child:
                      p.media.isEmpty
                          ? Icon(
                              Icons.person,
                              color: const Color(0xFF10B981),
                              size: 28,
                            )
                          : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.age > 0)
                          Text(
                            ', ${p.age}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.city}${p.country.isNotEmpty ? ", ${p.country}" : ""}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Request Chat Button
              ElevatedButton(
                onPressed: onRequestChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_add_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Friend',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
}

class _GridCard extends StatelessWidget {
  final DiscoverProfileModel p;
  final bool isDark;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const _GridCard({
    required this.p,
    required this.isDark,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: p.media.isNotEmpty
                    ? Image.network(
                        p.media,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${p.name}, ${p.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (p.city.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.city,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SmallActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onPressed: onDislike ?? () {},
                      ),
                      _SmallActionButton(
                        icon: Icons.info_outline,
                        color: Colors.white,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.discoverDetail,
                          arguments: p,
                        ),
                      ),
                      _SmallActionButton(
                        icon: Icons.favorite,
                        color: const Color(0xFF10B981),
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

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _SmallActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.7), width: 1),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
