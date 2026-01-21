import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../themes/theme.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../controllers/moments_controller.dart';

class PostMomentView extends StatefulWidget {
  const PostMomentView({super.key});

  @override
  State<PostMomentView> createState() => _PostMomentViewState();
}

class _PostMomentViewState extends State<PostMomentView> {
  final TextEditingController _textController = TextEditingController();
  final MomentsController _controller = MomentsController();
  File? _selectedImage;
  bool _isPosting = false;
  int _charCount = 0;
  final int _maxCharCount = 500;

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _postMoment() async {
    if (_textController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add text or an image'),
            ],
          ),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final success = await _controller.createPost(
        _textController.text,
        _selectedImage,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to post moment'),
                ],
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPost = _textController.text.isNotEmpty || _selectedImage != null;
    
    return AppScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F1512),
                    const Color(0xFF0A0F0D),
                  ]
                : [
                    const Color(0xFFF0FDF8),
                    const Color(0xFFECFDF5),
                  ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Create Moment',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: (_isPosting || !canPost) ? null : _postMoment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPost 
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                      disabledForegroundColor: isDark 
                          ? Colors.white38
                          : Colors.grey.shade400,
                      elevation: canPost ? 2 : 0,
                      shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Post',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main content card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Text input
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            minLines: 4,
                            maxLength: _maxCharCount,
                            onChanged: (v) => setState(() => _charCount = v.length),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: "What's on your mind? Share your moment...",
                              hintStyle: TextStyle(
                                color: isDark 
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                        
                        // Progress indicator for character count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _charCount / _maxCharCount,
                                    backgroundColor: isDark 
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      _charCount > _maxCharCount * 0.9
                                          ? Colors.orange.shade400
                                          : const Color(0xFF10B981),
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_charCount / $_maxCharCount',
                                style: TextStyle(
                                  color: _charCount > _maxCharCount * 0.9
                                      ? Colors.orange.shade400
                                      : (isDark ? Colors.white60 : Colors.grey.shade500),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Image section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _selectedImage == null
                              ? GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark 
                                            ? [
                                                Colors.white.withOpacity(0.03),
                                                Colors.white.withOpacity(0.06),
                                              ]
                                            : [
                                                const Color(0xFFF0FDF8),
                                                const Color(0xFFECFDF5),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.1)
                                            : const Color(0xFF10B981).withOpacity(0.2),
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF10B981).withOpacity(0.2),
                                                const Color(0xFF34D399).withOpacity(0.15),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 32,
                                            color: const Color(0xFF10B981).withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Add a photo',
                                          style: TextStyle(
                                            color: isDark 
                                                ? Colors.white60
                                                : const Color(0xFF10B981),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to select from gallery',
                                          style: TextStyle(
                                            color: isDark 
                                                ? Colors.white38
                                                : Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 280,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.swap_horiz_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Change',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick actions
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.image_rounded,
                        label: 'Gallery',
                        color: const Color(0xFF10B981),
                        onTap: _pickImage,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.emoji_emotions_rounded,
                        label: 'Mood',
                        color: Colors.orange,
                        onTap: () {
                          // Mood picker placeholder
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        color: Colors.blue,
                        onTap: () {
                          // Location picker placeholder
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
