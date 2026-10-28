import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';

import '../text/text_controls_widget.dart';
import '../text/enhanced_text_editor.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD TEXT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.dsTextSecondary(isDark),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _showEnhancedTextEditor(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dsBorder(isDark)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Type your text…',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.dsTextSecondary(isDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showEnhancedTextEditor(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dsAccent,
              foregroundColor: AppColors.dsAccentInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              textStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            child: const Text('Add to design'),
          ),
        ),

        if (selectedElementId != null &&
            selectedElementId!.startsWith('text')) ...[
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
