import 'package:flutter/material.dart';
import '../../models/auth/login_form_model.dart';
import '../../models/auth/register_form_model.dart';
import '../../models/auth/check_email_args.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';

class AuthController {
  final _service = AuthService();

  Future<void> login(BuildContext context, LoginFormModel form) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final status = await _service.login(form.email, form.password);
    if (status == LoginStatus.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Signed in')));
      navigator.pushNamedAndRemoveUntil(AppRoutes.discover, (route) => false);
    } else {
      String msg = 'Login failed';
      if (status == LoginStatus.invalid_credentials) {
        msg = 'Invalid username or password';
      } else if (status == LoginStatus.network_error) {
        msg = 'Network error. Check your connection';
      } else if (status == LoginStatus.server_error) {
        msg = 'Server error. Please try again later';
      } else {
        msg = 'Unexpected error. Please try again';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> sendReset(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await _service.sendReset(email);
    messenger.showSnackBar(const SnackBar(content: Text('Reset link sent')));
    navigator.pushNamed(
      AppRoutes.checkEmail,
      arguments: CheckEmailArgs(email: email, type: 'reset'),
    );
  }

  Future<void> register(BuildContext context, RegisterFormModel form) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await _service.register(form);
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Account created')));
      navigator.pushNamed(
        AppRoutes.checkEmail,
        arguments: CheckEmailArgs(email: form.email, type: 'verify'),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid registration data')),
      );
    }
  }
}
