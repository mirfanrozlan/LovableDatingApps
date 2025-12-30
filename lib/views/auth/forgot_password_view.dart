import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../routes.dart';

enum ResetStep { email, otp, newPassword }

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _controller = AuthController();
  
  ResetStep _step = ResetStep.email;
  bool _isLoading = false;
  bool _obscurePasswords = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppScaffold(
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    ),
                    onPressed: () {
                      if (_step == ResetStep.email) {
                        Navigator.pop(context);
                      } else if (_step == ResetStep.otp) {
                        setState(() => _step = ResetStep.email);
                      } else {
                        setState(() => _step = ResetStep.otp);
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(isDark),
                          const SizedBox(height: 48),
                          _buildForgotPasswordCard(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    String title = 'Forgot Password?';
    String subtitle = 'ENTER YOUR EMAIL TO RESET PASSWORD';
    
    if (_step == ResetStep.otp) {
        title = 'Enter OTP';
        subtitle = 'ENTER THE OTP SENT TO YOUR EMAIL';
    } else if (_step == ResetStep.newPassword) {
        title = 'Reset Password';
        subtitle = 'ENTER YOUR NEW PASSWORD';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            _step == ResetStep.newPassword ? Icons.lock_open : Icons.lock_reset,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1a1a1a),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDark 
                ? Colors.white.withOpacity(0.6)
                : const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _step == ResetStep.email 
                    ? "No worries! We'll send you reset instructions."
                    : (_step == ResetStep.otp 
                        ? "Please enter the verification code sent to your email."
                        : "Create a new strong password for your account."),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark 
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF666666),
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (_step == ResetStep.email)
                  _buildTextField(
                    controller: _email,
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),

              if (_step == ResetStep.otp)
                  _buildTextField(
                    controller: _otp,
                    hint: 'Enter OTP',
                    icon: Icons.pin_invoke,
                    isDark: isDark,
                  ),

              if (_step == ResetStep.newPassword)
                  _buildTextField(
                    controller: _newPassword,
                    hint: 'New Password',
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    isPassword: true,
                    obscureOverride: _obscurePasswords,
                    label: 'New Password',
                    trailing: IconButton(
                      icon: Icon(
                        _obscurePasswords ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF999999),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscurePasswords = !_obscurePasswords);
                      },
                    ),
                  ),
              
              if (_step == ResetStep.newPassword)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildTextField(
                      controller: _confirmPassword,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      isPassword: true,
                      obscureOverride: _obscurePasswords,
                      label: 'Confirm Password',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        if (value != _newPassword.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
              
              const SizedBox(height: 32),
              
              _buildResetButton(isDark),
              
              const SizedBox(height: 32),
              
              if (_step == ResetStep.email)
                _buildBackToLoginLink(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool? obscureOverride,
    Widget? trailing,
    String? Function(String?)? validator,
    String? label,
  }) {
    final field = Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              icon,
              color: isDark 
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF999999),
              size: 22,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword ? (obscureOverride ?? true) : false,
              keyboardType: isPassword ? TextInputType.text : (hint.contains('OTP') ? TextInputType.number : TextInputType.emailAddress),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
              ),
              validator: validator ?? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark 
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: trailing,
            ),
        ],
      ),
    );
    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF333333),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          field,
        ],
      );
    }
    return field;
  }

  Widget _buildResetButton(bool isDark) {
    String label = 'Send Reset Link';
    if (_step == ResetStep.otp) label = 'Verify OTP';
    if (_step == ResetStep.newPassword) label = 'Reset Password';

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () async {
            if (_formKey.currentState?.validate() ?? false) {
              setState(() => _isLoading = true);
              bool success = false;
              
              if (_step == ResetStep.email) {
                  success = await _controller.sendOtp(context, _email.text);
                  if (success && mounted) {
                      setState(() => _step = ResetStep.otp);
                  }
              } else if (_step == ResetStep.otp) {
                  success = await _controller.verifyOtp(context, _email.text, _otp.text);
                  if (success && mounted) {
                      setState(() => _step = ResetStep.newPassword);
                  }
              } else if (_step == ResetStep.newPassword) {
                  success = await _controller.resetPassword(context, _email.text, _otp.text, _newPassword.text);
              }

              if (mounted) setState(() => _isLoading = false);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "REMEMBER PASSWORD?",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : const Color(0xFF999999),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context, 
            AppRoutes.login, 
            (route) => false,
          ),
          child: const Text(
            'SIGN IN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF10B981),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF10B981),
              decorationThickness: 2,
            ),
          ),
        ),
      ],
    );
  }
}
