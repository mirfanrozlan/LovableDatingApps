import 'package:flutter/material.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/messages/app_bottom_nav.dart';
import '../../themes/theme.dart';
import '../../services/moments_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  
  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  
  bool _loading = true;
  bool _saving = false;
  UserModel? _user;
  final _momentsService = MomentsService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await _momentsService.getCurrentUserId();
      if (userId != null) {
        final user = await _momentsService.getUserDetails(userId);
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _locationController.text = '${user.city}, ${user.country}';
          _occupationController.text = user.education;
          _bioController.text = user.description;
          _interestsController.text = user.interests;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    try {
      final userId = await _momentsService.getCurrentUserId();
      if (userId == null) return;

      final locationParts = _locationController.text.split(',');
      final city = locationParts[0].trim();
      final country = locationParts.length > 1 ? locationParts[1].trim() : '';

      final success = await _authService.updateProfile(
        userId: userId,
        username: _nameController.text,
        gender: _user?.gender ?? 'male',
        age: _user?.age ?? 0,
        bio: _bioController.text,
        education: _occupationController.text,
        city: city,
        country: country,
        interests: _interestsController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1512), const Color(0xFF0A0F0D)]
                : [const Color(0xFFF0FDF8), const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
            stops: isDark ? null : const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            _buildDecorativeCircle(top: -50, right: -50, color: const Color(0xFF10B981), opacity: isDark ? 0.15 : 0.2),
            _buildDecorativeCircle(top: 200, left: -80, color: const Color(0xFF34D399), opacity: isDark ? 0.08 : 0.12),

            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(isDark),

                    Expanded(
                      child: _loading 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: FadeTransition(
                              opacity: _animController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animController,
                                  curve: Curves.easeOut,
                                )),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Avatar Section
                                      _buildAvatarSection(isDark),
                                      const SizedBox(height: 24),

                                      // Form Fields container
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: isDark 
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.white.withOpacity(0.5),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDark 
                                                  ? Colors.black.withOpacity(0.2)
                                                  : const Color(0xFF10B981).withOpacity(0.05),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputField(
                                              controller: _nameController,
                                              label: 'Full Name',
                                              icon: Icons.person_outline_rounded,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInputField(
                                              controller: _locationController,
                                              label: 'Location (City, Country)',
                                              icon: Icons.location_on_outlined,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInputField(
                                              controller: _occupationController,
                                              label: 'Education',
                                              icon: Icons.school_outlined,
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInputField(
                                              controller: _bioController,
                                              label: 'Bio',
                                              minLines: 3,
                                              maxLines: null,
                                              keyboardType: TextInputType.multiline,
                                              isDark: isDark,
                                              required: false,
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInputField(
                                              controller: _interestsController,
                                              label: 'Interests (comma separated)',
                                              icon: Icons.interests_outlined,
                                              isDark: isDark,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      // Save Button
                                      _buildSaveButton(isDark),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF064E3B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                backgroundImage: _user?.media.isNotEmpty == true ? NetworkImage(_user!.media) : null,
                child: _user?.media.isEmpty == true 
                  ? Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ) 
                  : null,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: InkWell(
              onTap: () {
                // Future: implementation of image picking
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    required bool isDark,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF10B981), size: 20) : null,
            alignLabelWithHint: true,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF8).withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: required 
            ? (v) => v?.trim().isEmpty == true ? 'This field is required' : null
            : null,
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saving ? null : _saveProfile,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle({
    required double top,
    double? right,
    double? left,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
