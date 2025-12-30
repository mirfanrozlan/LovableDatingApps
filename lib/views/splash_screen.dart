import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a moment for better UX (optional)
    await Future.delayed(const Duration(seconds: 1));

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    if (!mounted) return;

    if (token != null) {
      // Token exists, navigate to discover by default
      Navigator.pushReplacementNamed(context, AppRoutes.discover);
    } else {
      // No token, navigate to login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
