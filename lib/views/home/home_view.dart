import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: const Text('Welcome to LoveConnect'),
    );
  }
}