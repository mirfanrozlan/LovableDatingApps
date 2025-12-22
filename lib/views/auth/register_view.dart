import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/text_input.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../models/auth/register_form_model.dart';
import '../../themes/theme.dart';
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
  final _ageText = TextEditingController();
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
  int _stepIndex = 0;
  String _gender = 'Male';
  String _attractedGender = 'Male';
  int _age = 18;
  int _minAge = 18;
  int _maxAge = 18;
  int _distance = 0;
  String _photoName = '';
  XFile? _photo;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: false,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_stepIndex + 1) / 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Basic Info'),
                      Text('Contact & Location'),
                      Text('Preferences'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_stepIndex == 0) ...[
                          TextInput(
                            controller: _username,
                            hint: 'Username *',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          TextInput(
                            controller: _password,
                            hint: 'Password *',
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
                          TextInput(
                            controller: _password2,
                            hint: 'Confirm Password *',
                            icon: Icons.lock,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v != _password.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text('What Gender Are You? *'),
                          Wrap(
                            spacing: 16,
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Male',
                                    groupValue: _gender,
                                    onChanged:
                                        (v) => setState(() => _gender = v!),
                                  ),
                                  const Text('Male'),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Female',
                                    groupValue: _gender,
                                    onChanged:
                                        (v) => setState(() => _gender = v!),
                                  ),
                                  const Text('Female'),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Non-Binary',
                                    groupValue: _gender,
                                    onChanged:
                                        (v) => setState(() => _gender = v!),
                                  ),
                                  const Text('Non-Binary'),
                                ],
                              ),
                            ],
                          ),
                          Slider(
                            value: _age.toDouble(),
                            min: 18,
                            max: 100,
                            divisions: 82,
                            label: 'Age : $_age',
                            onChanged: (v) => setState(() => _age = v.round()),
                          ),
                          const SizedBox(height: 8),
                          TextInput(
                            controller: _interests,
                            hint: 'Interests (comma separated)',
                          ),
                          const SizedBox(height: 12),
                          TextInput(
                            controller: _bio,
                            hint: 'Tell us about yourself',
                          ),
                          const SizedBox(height: 12),
                          TextInput(controller: _education, hint: 'Education'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Next',
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      setState(() => _stepIndex = 1);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              const Text('By signing up, you agree to our'),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Terms of Service'),
                              ),
                              const Text('and'),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Privacy Policy'),
                              ),
                            ],
                          ),
                        ],
                        if (_stepIndex == 1) ...[
                          TextInput(controller: _address, hint: 'Address'),
                          const SizedBox(height: 12),
                          TextInput(controller: _postcode, hint: 'Postcode'),
                          const SizedBox(height: 12),
                          TextInput(controller: _state, hint: 'State'),
                          const SizedBox(height: 12),
                          TextInput(controller: _city, hint: 'City'),
                          const SizedBox(height: 12),
                          TextInput(controller: _country, hint: 'Country'),
                          const SizedBox(height: 12),
                          TextInput(
                            controller: _email,
                            hint: 'Email *',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextInput(controller: _phone, hint: 'Phone *'),
                          const SizedBox(height: 12),
                          TextInput(controller: _otp, hint: 'OTP *'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => setState(() => _stepIndex = 0),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Next',
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      setState(() => _stepIndex = 2);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_stepIndex == 2) ...[
                          Slider(
                            value: _minAge.toDouble(),
                            min: 18,
                            max: 100,
                            divisions: 82,
                            label: 'Min Age : $_minAge',
                            onChanged:
                                (v) => setState(() => _minAge = v.round()),
                          ),
                          Slider(
                            value: _maxAge.toDouble(),
                            min: 18,
                            max: 100,
                            divisions: 82,
                            label: 'Max Age : $_maxAge',
                            onChanged:
                                (v) => setState(() => _maxAge = v.round()),
                          ),
                          Slider(
                            value: _distance.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: 'Location : $_distance km',
                            onChanged:
                                (v) => setState(() => _distance = v.round()),
                          ),
                          const SizedBox(height: 8),
                          const Text('What Gender Are You Attracted To?'),
                          Wrap(
                            spacing: 16,
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Male',
                                    groupValue: _attractedGender,
                                    onChanged:
                                        (v) => setState(
                                          () => _attractedGender = v!,
                                        ),
                                  ),
                                  const Text('Male'),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Female',
                                    groupValue: _attractedGender,
                                    onChanged:
                                        (v) => setState(
                                          () => _attractedGender = v!,
                                        ),
                                  ),
                                  const Text('Female'),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Non-Binary',
                                    groupValue: _attractedGender,
                                    onChanged:
                                        (v) => setState(
                                          () => _attractedGender = v!,
                                        ),
                                  ),
                                  const Text('Non-Binary'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_photo != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_photo!.path),
                                height: 140,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final source =
                                  await showModalBottomSheet<ImageSource>(
                                    context: context,
                                    builder:
                                        (_) => SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.photo_library,
                                                ),
                                                title: const Text(
                                                  'Pick from Gallery',
                                                ),
                                                onTap:
                                                    () => Navigator.pop(
                                                      context,
                                                      ImageSource.gallery,
                                                    ),
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.photo_camera,
                                                ),
                                                title: const Text('Take Photo'),
                                                onTap:
                                                    () => Navigator.pop(
                                                      context,
                                                      ImageSource.camera,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                              if (source == null) return;
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: source,
                                maxWidth: 1080,
                              );
                              if (picked != null) {
                                setState(() {
                                  _photo = picked;
                                  _photoName = picked.name;
                                });
                              }
                            },
                            child: Text(
                              _photoName.isEmpty ? 'Choose File' : _photoName,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => setState(() => _stepIndex = 1),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Submit',
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
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
                                      _controller.register(context, form);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
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
