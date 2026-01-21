import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/moments/moment_list.dart';
import 'post_moment_view.dart';

class MomentsView extends StatefulWidget {
  const MomentsView({super.key});

  @override
  State<MomentsView> createState() => _MomentsViewState();
}

class _MomentsViewState extends State<MomentsView> with SingleTickerProviderStateMixin {
  final _allMomentsController = MomentsController(type: MomentsType.all);
  final _friendMomentsController = MomentsController(type: MomentsType.friends);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allMomentsController.addListener(() {
      if (mounted) setState(() {});
    });
    _friendMomentsController.addListener(() {
      if (mounted) setState(() {});
    });
    _allMomentsController.loadMoments();
    _friendMomentsController.loadMoments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allMomentsController.dispose();
    _friendMomentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F1512),
                    const Color(0xFF0A0F0D),
                  ]
                : [
                    const Color(0xFFF0FDF8),
                    const Color(0xFFECFDF5),
                    const Color(0xFFD1FAE5),
                  ],
            stops: isDark ? null : const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(isDark ? 0.1 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(isDark ? 0.05 : 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        // Logo/Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title
                        Text(
                          'Moments',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF064E3B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Notification icon
                        Container(
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Tab Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Discover'),
                        Tab(text: 'Friends'),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      MomentList(controller: _allMomentsController),
                      MomentList(controller: _friendMomentsController),
                    ],
                  ),
                ),
              ],
            ),
            
            // FAB
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PostMomentView(),
                        ),
                      );
                      if (result == true) {
                        _allMomentsController.refresh();
                        _friendMomentsController.refresh();
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
