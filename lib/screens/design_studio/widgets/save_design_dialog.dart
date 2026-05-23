import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/custom_design.dart';
import '../../../services/design_storage_service.dart';
import '../../../presentation/styles/app_colors.dart';

class SaveDesignDialog {
  static void show(
    BuildContext context,
    CustomDesign design,
    DesignStorageService storageService,
  ) {
    final nameController = TextEditingController(
      text: storageService.generateDefaultName(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Design',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Design Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final savedDesign = SavedDesign(
                id: storageService.generateDesignId(),
                name: nameController.text.trim(),
                design: design,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await storageService.saveDesign(savedDesign);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Design "${savedDesign.name}" saved! 💾'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

