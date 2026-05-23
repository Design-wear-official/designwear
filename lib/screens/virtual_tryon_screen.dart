import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/safe_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../services/virtual_tryon_service.dart';
import '../presentation/styles/app_colors.dart';
import '../presentation/utils/responsive_utils.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final Product product;

  const VirtualTryOnScreen({super.key, required this.product});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen>
    with SingleTickerProviderStateMixin {
  final VirtualTryOnService _tryOnService = VirtualTryOnService();
  final ImagePicker _imagePicker = ImagePicker();

  // Store image as bytes for cross-platform compatibility (web + mobile)
  Uint8List? _userPhotoBytes;
  Uint8List? _generatedImage;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Read bytes - works on all platforms including web
        final bytes = await image.readAsBytes();
        setState(() {
          _userPhotoBytes = bytes;
          _generatedImage = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Photo Source',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Camera option - hide on web since it may not work well
                if (!kIsWeb)
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: AppColors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                if (!kIsWeb) const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateTryOn() async {
    if (_userPhotoBytes == null) {
      setState(() {
        _errorMessage = 'Please upload your photo first';
      });
      return;
    }

    if (!_tryOnService.isConfigured) {
      setState(() {
        _errorMessage =
            'Gemini API key not configured.\nPlease add GEMINI_API_KEY to your .env file.\nGet your key from: aistudio.google.com/apikey';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get clothing image bytes from URL
      Uint8List clothingBytes;
      if (widget.product.imageUrl != null) {
        final response = await http.get(Uri.parse(widget.product.imageUrl!));
        if (response.statusCode == 200) {
          clothingBytes = response.bodyBytes;
        } else {
          throw Exception('Failed to fetch product image');
        }
      } else {
        throw Exception('Product image not available');
      }

      // Generate try-on
      final result = await _tryOnService.generateTryOn(
        personImageBytes: _userPhotoBytes!,
        clothingImageBytes: clothingBytes,
      );

      setState(() {
        _generatedImage = result;
        _isLoading = false;
      });
    } on VirtualTryOnException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareResult() async {
    if (_generatedImage == null) return;

    try {
      if (kIsWeb) {
        // On web, we can't share files the same way
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Right-click the image to save it')),
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(_generatedImage!);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out how I look in ${widget.product.title}! 👕✨');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Virtual Try-On',
          style: GoogleFonts.outfit(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSizes.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Preview Card
              _buildProductCard(),
              const SizedBox(height: 24),

              // User Photo Section
              _buildUserPhotoSection(),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) _buildErrorCard(),

              // Generated Result
              if (_generatedImage != null) _buildResultSection(),

              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.product.imageUrl != null
                ? SafeNetworkImage(
                    imageUrl: widget.product.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.gray200,
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Photo',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a full-body photo for best results',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.gray600),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: ResponsiveSizes.carouselHeight(context) * 0.75,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _userPhotoBytes != null
                    ? AppColors.purple.withOpacity(0.5)
                    : AppColors.gray300,
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _userPhotoBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        // Use Image.memory instead of Image.file for web compatibility
                        child: Image.memory(
                          _userPhotoBytes!,
                          width: double.infinity,
                          height: ResponsiveSizes.carouselHeight(context) * 0.75,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          backgroundColor: AppColors.white,
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.purple,
                            ),
                            onPressed: _showImageSourceDialog,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 48,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to upload your photo',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kIsWeb
                            ? 'Choose from your files'
                            : 'Take a selfie or choose from gallery',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                color: AppColors.errorDark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '✨ Your Try-On Result',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _shareResult,
              icon: const Icon(Icons.share_rounded),
              color: AppColors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(_generatedImage!, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: ResponsiveSizes.contentPadding(context),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity(0.08),
            offset: const Offset(0, -5),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: ResponsiveSizes.buttonPaddingVertical(context) * 3.5,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateTryOn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating magic...',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 8),
                      Text(
                        _generatedImage != null ? 'Try Again' : 'Try It On',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

