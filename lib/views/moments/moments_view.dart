import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../controllers/moments_controller.dart';
import '../../widgets/moments/moment_card.dart';
import '../../widgets/moments/moment_list.dart';
import 'post_moment_view.dart';

class MomentsView extends StatefulWidget {
  const MomentsView({super.key});

  @override
  State<MomentsView> createState() => _MomentsViewState();
}

class _MomentsViewState extends State<MomentsView> {
  final _allMomentsController = MomentsController(type: MomentsType.all);
  final _friendMomentsController = MomentsController(type: MomentsType.friends);

  @override
  void initState() {
    super.initState();
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
    _allMomentsController.dispose();
    _friendMomentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TabBar(
                            isScrollable: false,
                            labelPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                              insets: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: const Color(0xFF10B981),
                            unselectedLabelColor: isDark ? Colors.white70 : const Color(0xFF6B7280),
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            tabs: const [
                              Tab(text: 'All'),
                              Tab(text: 'Friends'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        MomentList(controller: _allMomentsController),
                        MomentList(controller: _friendMomentsController),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () async {
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
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
