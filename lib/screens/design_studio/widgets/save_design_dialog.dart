import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';

class SaveDesignDialog {
  /// Shows the save dialog. If [captureCallback] is provided it is called
  /// before writing to storage and the resulting base64 PNG is stored as the
  /// thumbnail so the Saved Designs screen can render a preview.
  static void show(
    BuildContext context,
    CustomDesign design,
    DesignStorageService storageService, {
    Future<String?> Function()? captureCallback,
  }) {
    final nameController = TextEditingController(
      text: storageService.generateDefaultName(),
    );

    showDialog(
      context: context,
      builder: (ctx) => _SaveDesignDialogContent(
        nameController: nameController,
        design: design,
        storageService: storageService,
        captureCallback: captureCallback,
      ),
    );
  }
}

class _SaveDesignDialogContent extends StatefulWidget {
  final TextEditingController nameController;
  final CustomDesign design;
  final DesignStorageService storageService;
  final Future<String?> Function()? captureCallback;

  const _SaveDesignDialogContent({
    required this.nameController,
    required this.design,
    required this.storageService,
    required this.captureCallback,
  });

  @override
  State<_SaveDesignDialogContent> createState() => _SaveDesignDialogContentState();
}

class _SaveDesignDialogContentState extends State<_SaveDesignDialogContent> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final thumbnailBase64 = await widget.captureCallback?.call();
    final savedDesign = SavedDesign(
      id: widget.storageService.generateDesignId(),
      name: widget.nameController.text.trim(),
      design: widget.design,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      thumbnailPath: thumbnailBase64,
    );
    await widget.storageService.saveDesign(savedDesign);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Design "${savedDesign.name}" saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Save Design', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            decoration: const InputDecoration(
              labelText: 'Design Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

