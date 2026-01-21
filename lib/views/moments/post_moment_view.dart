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
                        
                        // Image section - redesigned
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _selectedImage == null
                              ? _buildAddPhotoCard(isDark)
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
                                        onTap: () => _showImagePickerOptions(context, isDark),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard(bool isDark) {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(context, isDark),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.03)
              : const Color(0xFFF8FFFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF10B981).withOpacity(0.25),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Dashed border effect overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: isDark 
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFF10B981).withOpacity(0.3),
                  strokeWidth: 2,
                  dashWidth: 8,
                  dashSpace: 6,
                  radius: 24,
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container with gradient
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.15),
                          const Color(0xFF34D399).withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      size: 32,
                      color: const Color(0xFF10B981).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    'Add a Photo',
                    style: TextStyle(
                      color: isDark 
                          ? Colors.white
                          : const Color(0xFF047857),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Subtitle
                  Text(
                    'Take a photo or choose from gallery',
                    style: TextStyle(
                      color: isDark 
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.shade500,
                      fontSize: 13,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.camera);
                    },
                    isDark: isDark,
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.gallery);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFF10B981).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
}

// Custom painter for dashed border effect
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Draw dashed path
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();
    
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

