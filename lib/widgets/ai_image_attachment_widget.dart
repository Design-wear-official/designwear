import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../styles/app_colors.dart';

class AIImageAttachmentWidget extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final List<File> selectedImages;

  const AIImageAttachmentWidget({
    super.key,
    required this.onImagesSelected,
    required this.selectedImages,
  });

  @override
  State<AIImageAttachmentWidget> createState() =>
      _AIImageAttachmentWidgetState();
}

class _AIImageAttachmentWidgetState extends State<AIImageAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showPermissionDialog('Camera');
          return;
        }
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            _showPermissionDialog('Gallery');
            return;
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final updatedImages = [...widget.selectedImages, file];
        widget.onImagesSelected(updatedImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _removeImage(int index) {
    final updatedImages = [...widget.selectedImages];
    updatedImages.removeAt(index);
    widget.onImagesSelected(updatedImages);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.accentBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Permission Required',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Please grant $permission permission to upload images for AI design suggestions.',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Error',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image attachments display
        if (widget.selectedImages.isNotEmpty)
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          widget.selectedImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Add image button
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file, size: 18, color: AppColors.accentBlue),
                const SizedBox(width: 4),
                Text(
                  'Add Image',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
