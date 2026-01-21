import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../models/discover_profile_model.dart';

class DiscoverDetailView extends StatelessWidget {
  const DiscoverDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ModalRoute.of(context)?.settings.arguments as DiscoverProfileModel?;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      useGradient: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF0a0a0a),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFDCFCE7),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _Header(isDark: isDark),
                  const SizedBox(height: 16),
                  _ProfileCard(p: p, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back Button - Aligned Left
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        // Title - Centered
        Text(
          'Discover',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF064E3B),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final DiscoverProfileModel? p;
  final bool isDark;
  const _ProfileCard({required this.p, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Stack(
              children: [
                (p?.media.isNotEmpty ?? false)
                    ? Image.network(
                        p!.media,
                        height: 340,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            Container(color: Colors.grey.shade300, height: 340),
                      )
                    : Container(color: Colors.grey.shade300, height: 340),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p?.name ?? 'Profile'}, ${p?.age ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((p?.subscription ?? '') == 'premium' ||
                          (p?.subscription ?? '') == 'plus')
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                          ),
                          child: const Icon(Icons.verified, color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${p?.city ?? ''}, ${p?.country ?? ''}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF444444),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if ((p?.education ?? '').isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 18, color: isDark ? Colors.white70 : const Color(0xFF444444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p!.education,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF444444),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  'About',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  (p?.description ?? '').isNotEmpty ? p!.description : 'No description available.',
                  style: TextStyle(
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 16),
                if ((p?.interests ?? const []).isNotEmpty) ...[
                  const Text(
                    'Interests',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (p?.interests ?? const [])
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
