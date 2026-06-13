import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'text_controls_widget.dart';
import 'enhanced_text_editor.dart';

class TextTab extends StatelessWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final DesignTemplateService templateService;
  final Function(CustomDesign) onDesignUpdate;
  final Function(String text, String fontFamily) onAddTextElement;
  final Function(DesignElement, String) onToggleTextEffect;

  const TextTab({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.templateService,
    required this.onDesignUpdate,
    required this.onAddTextElement,
    required this.onToggleTextEffect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEnhancedTextEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('ADD TEXT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        if (selectedElementId != null &&
            (selectedElementId!.startsWith('text') ||
                selectedElementId == 'legacy_text')) ...[
          const SizedBox(height: 16),
          Text(
            'Text Properties',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextControlsWidget(
            design: design,
            selectedElementId: selectedElementId!,
            onDesignUpdate: onDesignUpdate,
            onToggleTextEffect: onToggleTextEffect,
            templateService: templateService,
          ),
        ],
      ],
    );
  }

  void _showEnhancedTextEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EnhancedTextEditor(
        templateService: templateService,
        onAddTextElement: onAddTextElement,
      ),
    );
  }
}

