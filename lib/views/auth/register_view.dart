import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/text_input.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../models/auth/register_form_model.dart';
import '../../themes/theme.dart';
import '../../routes.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _interests = TextEditingController();
  final _bio = TextEditingController();
  final _education = TextEditingController();
  final _address = TextEditingController();
  final _postcode = TextEditingController();
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _controller = AuthController();
  bool _showPassword = false;
  bool _isLoading = false;
  int _stepIndex = 0;
  String _gender = 'Male';
  String _attractedGender = 'Male';
  int _age = 18;
  int _minAge = 18;
  int _maxAge = 50;
  int _distance = 10;
  String _photoName = '';
  XFile? _photo;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    _interests.dispose();
    _bio.dispose();
    _education.dispose();
    _address.dispose();
    _postcode.dispose();
    _state.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    _otp.dispose();
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
                    onPressed: () => Navigator.pop(context),
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
                          _buildRegisterCard(isDark),
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
          child: const Icon(
            Icons.favorite,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1a1a1a),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'STEP ${_stepIndex + 1} OF 3',
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

  Widget _buildRegisterCard(bool isDark) {
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
              _buildProgressIndicator(isDark),
              const SizedBox(height: 32),
              if (_stepIndex == 0) _buildStep1(isDark),
              if (_stepIndex == 1) _buildStep2(isDark),
              if (_stepIndex == 2) _buildStep3(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Column(
      children: [
        Row(
          children: List.generate(3, (index) {
            final isActive = index <= _stepIndex;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isActive
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Basic',
              style: TextStyle(
                fontSize: 11,
                fontWeight: _stepIndex == 0 ? FontWeight.bold : FontWeight.w500,
                color: _stepIndex >= 0
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white38 : const Color(0xFF999999)),
              ),
            ),
            Text(
              'Contact',
              style: TextStyle(
                fontSize: 11,
                fontWeight: _stepIndex == 1 ? FontWeight.bold : FontWeight.w500,
                color: _stepIndex >= 1
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white38 : const Color(0xFF999999)),
              ),
            ),
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 11,
                fontWeight: _stepIndex == 2 ? FontWeight.bold : FontWeight.w500,
                color: _stepIndex >= 2
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white38 : const Color(0xFF999999)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _username,
          hint: 'Username',
          icon: Icons.person_outline,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _password,
          hint: 'Password',
          icon: Icons.lock_outline,
          isDark: isDark,
          obscure: !_showPassword,
          suffix: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF999999),
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _password2,
          hint: 'Confirm Password',
          icon: Icons.lock_outline,
          isDark: isDark,
          obscure: true,
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('Gender', isDark),
        const SizedBox(height: 12),
        _buildGenderSelector(isDark, _gender, (v) => setState(() => _gender = v)),
        const SizedBox(height: 24),
        _buildSectionLabel('Age: $_age', isDark),
        _buildSlider(_age.toDouble(), 18, 100, (v) => setState(() => _age = v.round()), isDark),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _interests,
          hint: 'Interests (comma separated)',
          icon: Icons.favorite_border,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bio,
          hint: 'Tell us about yourself',
          icon: Icons.description_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _education,
          hint: 'Education',
          icon: Icons.school_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 32),
        _buildStepButtons(isDark, null, () {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _stepIndex = 1);
          }
        }),
        const SizedBox(height: 24),
        _buildTermsText(isDark),
      ],
    );
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _address,
          hint: 'Address',
          icon: Icons.home_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _postcode,
                hint: 'Postcode',
                icon: Icons.location_on_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _city,
                hint: 'City',
                icon: Icons.location_city_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _state,
                hint: 'State',
                icon: Icons.map_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _country,
                hint: 'Country',
                icon: Icons.public,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _email,
          hint: 'Email',
          icon: Icons.email_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phone,
          hint: 'Phone Number',
          icon: Icons.phone_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _otp,
          hint: 'OTP',
          icon: Icons.security,
          isDark: isDark,
        ),
        const SizedBox(height: 32),
        _buildStepButtons(isDark, () => setState(() => _stepIndex = 0), () {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _stepIndex = 2);
          }
        }),
      ],
    );
  }

  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Age Range: $_minAge - $_maxAge', isDark),
        _buildSlider(_minAge.toDouble(), 18, 100, (v) => setState(() => _minAge = v.round()), isDark),
        _buildSlider(_maxAge.toDouble(), 18, 100, (v) => setState(() => _maxAge = v.round()), isDark),
        const SizedBox(height: 16),
        _buildSectionLabel('Distance: $_distance km', isDark),
        _buildSlider(_distance.toDouble(), 0, 100, (v) => setState(() => _distance = v.round()), isDark),
        const SizedBox(height: 24),
        _buildSectionLabel('Attracted To', isDark),
        const SizedBox(height: 12),
        _buildGenderSelector(isDark, _attractedGender, (v) => setState(() => _attractedGender = v)),
        const SizedBox(height: 24),
        _buildPhotoUpload(isDark),
        const SizedBox(height: 32),
        _buildStepButtons(isDark, () => setState(() => _stepIndex = 1), _submitForm),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              icon,
              color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF999999),
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) suffix,
          if (suffix != null) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF1a1a1a),
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark, String value, Function(String) onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Male', 'Female', 'Non-Binary'].map((gender) {
        final isSelected = value == gender;
        return GestureDetector(
          onTap: () => onChanged(gender),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE)),
                width: 1,
              ),
            ),
            child: Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF666666)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlider(double value, double min, double max, Function(double) onChanged, bool isDark) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: const Color(0xFF10B981),
        inactiveTrackColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
        thumbColor: const Color(0xFF10B981),
        overlayColor: const Color(0xFF10B981).withOpacity(0.2),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).round(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPhotoUpload(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Profile Photo', isDark),
        const SizedBox(height: 12),
        if (_photo != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_photo!.path),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                            title: Text(
                              'Pick from Gallery',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                              ),
                            ),
                            onTap: () => Navigator.pop(context, ImageSource.gallery),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_camera, color: Color(0xFF10B981)),
                            title: Text(
                              'Take Photo',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                              ),
                            ),
                            onTap: () => Navigator.pop(context, ImageSource.camera),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (source == null) return;
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: source, maxWidth: 1080);
                if (picked != null) {
                  setState(() {
                    _photo = picked;
                    _photoName = picked.name;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF999999),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _photoName.isEmpty ? 'Choose Photo' : _photoName,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepButtons(bool isDark, VoidCallback? onBack, VoidCallback onNext) {
    return Row(
      children: [
        if (onBack != null) ...[
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                onTap: _isLoading ? null : onNext,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading && _stepIndex == 2
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _stepIndex == 2 ? 'Create Account' : 'Next',
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
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'By signing up, you agree to our ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF999999),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Terms',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' and ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF999999),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final form = RegisterFormModel(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        age: _age,
        gender: _gender,
        interests: _interests.text,
        bio: _bio.text,
        education: _education.text,
        address: _address.text,
        postcode: _postcode.text,
        state: _state.text,
        city: _city.text,
        country: _country.text,
        phone: _phone.text,
        otp: _otp.text,
        minAge: _minAge,
        maxAge: _maxAge,
        distanceKm: _distance,
        attractedGender: _attractedGender,
        photoName: _photoName,
        photoPath: _photo?.path ?? '',
      );
      await _controller.register(context, form);
      if (mounted) setState(() => _isLoading = false);
    }
  }
}