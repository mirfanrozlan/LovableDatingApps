import 'package:flutter/material.dart';
import 'package:mobile/services/auth_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_logo.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/text_input.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../models/auth/login_form_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controller = AuthController();
  bool _remember = false;
  bool _showPassword = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextInput(
                          controller: _email,
                          hint: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: _password,
                          hint: 'Password',
                          icon: Icons.lock,
                          obscure: !_showPassword,
                          suffix: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged:
                                      (v) => setState(
                                        () => _remember = v ?? false,
                                      ),
                                ),
                                const Text('Remember me'),
                              ],
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgot,
                                  ),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Sign In',
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final form = LoginFormModel(
                                email: _email.text,
                                password: _password.text,
                                rememberMe: _remember,
                              );
                              _controller.login(context, form);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 0,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
