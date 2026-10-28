import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_utils.dart';

class EnhancedTextEditor extends StatefulWidget {
  final DesignTemplateService templateService;
  final Function(String text, String fontFamily) onAddTextElement;

  /// When set, the editor opens in "edit" mode pre-filled with this text.
  final String? initialText;
  final String? initialFont;

  const EnhancedTextEditor({
    super.key,
    required this.templateService,
    required this.onAddTextElement,
    this.initialText,
    this.initialFont,
  });

  @override
  State<EnhancedTextEditor> createState() => _EnhancedTextEditorState();
}

class _EnhancedTextEditorState extends State<EnhancedTextEditor> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.initialText ?? '',
  );
  late String _selectedFont = widget.initialFont ?? 'Outfit';

  bool get _isEditing => widget.initialText != null;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Text' : 'Add Text',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Text input
          TextField(
            controller: _textController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter your text',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),

          const SizedBox(height: 16),

          // Font selection
          Text(
            'Font Style',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.templateService.getAvailableFonts().length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final font = widget.templateService.getAvailableFonts()[index];
                final isSelected = _selectedFont == font;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFont = font;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.marigold
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        font,
                        style: DesignStudioUtils.getSafeGoogleFont(
                          font,
                          textStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      widget.onAddTextElement(
                        _textController.text,
                        _selectedFont,
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marigold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(_isEditing ? 'SAVE' : 'ADD TEXT'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
