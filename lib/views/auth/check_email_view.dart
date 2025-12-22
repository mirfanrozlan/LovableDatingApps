import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../models/auth/check_email_args.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class CheckEmailView extends StatelessWidget {
  const CheckEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as CheckEmailArgs?;
    final email = args?.email ?? '';
    final type = args?.type ?? 'reset';
    final msg = type == 'verify'
        ? "We\'ve sent verification instructions to"
        : "We\'ve sent password reset instructions to";
    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Check Your Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('$msg', textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  Text(email, style: const TextStyle(color: AppTheme.primaryDark)),
                  const SizedBox(height: 12),
                  Text('If you don\'t see the email, check your spam folder.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Back to Login',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false),
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