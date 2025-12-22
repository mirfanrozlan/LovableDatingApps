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
    _controller.loadProfiles();
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
            const Center(
              child: Text(
                'Discover',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _controller.loading && _controller.profiles.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _controller.profiles.isEmpty
                      ? const Center(child: Text('No more profiles to show'))
                      : _CardStack(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStack extends StatefulWidget {
  final DiscoverController controller;
  const _CardStack({required this.controller});

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
      // Calculate rotation angle based on x position
      // Max rotation is 15 degrees (approx 0.26 rad) at 300px drag
      _angle = (_dragOffset.dx / 300) * 0.26;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Swipe Threshold: The distance a card must be dragged to trigger an action
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx > threshold) {
      // Swipe Right -> Like / Accept
      _animateOut(Offset(screenWidth * 1.5, _dragOffset.dy), true);
    } else if (_dragOffset.dx < -threshold) {
      // Swipe Left -> Reject / Dismiss
      _animateOut(Offset(-screenWidth * 1.5, _dragOffset.dy), false);
    } else {
      // Snap back if threshold not met
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
      // Reset state for next card
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
    // Scale from 0.9 to 1.0 based on drag distance
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
                child: _SingleCard(p: nextP, isBackground: true),
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
                ),
              ),
            ),
          ),
        ),

        // Overlay indicators (Like/Nope)
        if (_isDragging)
          Positioned.fill(
            child: IgnorePointer(
              child: FractionallySizedBox(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Stack(
                  children: [
                    if (_dragOffset.dx > 20)
                      Positioned(
                        top: 40,
                        left: 40,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIKE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_dragOffset.dx < -20)
                      Positioned(
                        top: 40,
                        right: 40,
                        child: Transform.rotate(
                          angle: 0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOPE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 32,
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
          ),
      ],
    );
  }
}

class _SingleCard extends StatelessWidget {
  final DiscoverProfileModel p;
  final bool isBackground;
  final DiscoverController? controller;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const _SingleCard({
    required this.p,
    this.isBackground = false,
    this.controller,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(24),
      elevation: isBackground ? 0 : 8,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child:
                  p.media.isNotEmpty
                      ? Image.network(
                        p.media,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (ctx, err, stack) =>
                                Container(color: Colors.grey.shade800),
                      )
                      : Container(color: Colors.grey.shade800),
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
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p.name} ( ${p.age} yrs )',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.description.isNotEmpty
                      ? p.description
                      : 'No description available.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (p.city.isNotEmpty || p.country.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.city}, ${p.country}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (!isBackground && controller != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        size: 32,
                        onPressed: onDislike ?? () {},
                      ),
                      const SizedBox(width: 24),
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
                      const SizedBox(width: 24),
                      _ActionButton(
                        icon: Icons.favorite,
                        color: const Color(0xFF4CD964), // Tinder-like green
                        size: 32,
                        onPressed: onLike ?? () {},
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
            color: Colors.black.withValues(
              alpha: 0.3,
            ), // Semi-transparent background
          ),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}
