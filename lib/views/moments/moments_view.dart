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
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
        useGradient: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TabBar(
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).primaryColor,
                            tabs: const [
                              Tab(text: 'All'),
                              Tab(text: 'Friends'),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
