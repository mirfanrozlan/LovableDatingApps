import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../widgets/common/text_input.dart';
import '../../services/moments_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../routes.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _education = TextEditingController();
  final _interests = TextEditingController();
  final _address = TextEditingController();
  final _postcode = TextEditingController();
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  int? _userId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final ms = MomentsService();
      final id = await ms.getCurrentUserId();
      if (id == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final user = await ms.getUserDetails(id);
      _applyUser(user);
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyUser(UserModel user) {
    _userId = user.id;
    _name.text = user.name;
    _bio.text = user.description;
    _education.text = user.education;
    _interests.text = user.interests;
    _address.text = user.address;
    _postcode.text = user.postcode;
    _state.text = user.state;
    _city.text = user.city;
    _country.text = user.country;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_userId == null) return;
    setState(() {
      _saving = true;
    });
    final svc = AuthService();
    final ok = await svc.updateProfile(
      userId: _userId!,
      username: _name.text.trim(),
      gender: '',
      age: 0,
      bio: _bio.text.trim(),
      education: _education.text.trim(),
      address: _address.text.trim(),
      postcode: _postcode.text.trim(),
      state: _state.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
      interests: _interests.text.trim(),
    );
    setState(() {
      _saving = false;
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.me,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                          children: [
                            TextInput(controller: _name, hint: 'Enter your name', label: 'Name'),
                            const SizedBox(height: 12),
                            
                            TextInput(controller: _bio, hint: 'Tell us about yourself', label: 'Bio', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _education, hint: 'Your education', label: 'Education', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _interests, hint: 'Your interests', label: 'Interests', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _address, hint: 'Your address', label: 'Address', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _postcode, hint: 'Your postcode', label: 'Postcode', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _state, hint: 'Your state', label: 'State', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _city, hint: 'Your city', label: 'City', validator: (_) => null),
                            const SizedBox(height: 12),
                            TextInput(controller: _country, hint: 'Your country', label: 'Country', validator: (_) => null),
                            const SizedBox(height: 12),
                            
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: Text(_saving ? 'Saving...' : 'Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        title: const Text('Membership'),
                        subtitle: const Text(
                          'Upgrade to Premium to unlock exclusive features and benefits',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Upgrade'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    )));
  }
}
