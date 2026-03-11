import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/custom_design.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/design_template_service.dart';
import '../services/design_history_service.dart';
import '../services/design_storage_service.dart';
import '../styles/app_colors.dart';
import '../widgets/agent_chat_widget.dart';
import 'design_studio/design_canvas.dart';
import 'design_studio/tools_panel.dart';
import 'design_studio/templates_panel.dart';
import 'design_studio/layers_panel.dart';
import 'design_studio/design_studio_constants.dart';
import 'design_studio/design_studio_utils.dart';
import 'design_studio/widgets/save_design_dialog.dart';

class DesignStudioScreen extends StatefulWidget {
  const DesignStudioScreen({super.key});

  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> {
  CustomDesign _design = CustomDesign();
  final DesignHistoryService _historyService = DesignHistoryService();
  final DesignTemplateService _templateService = DesignTemplateService();
  final DesignStorageService _storageService = DesignStorageService();

  String? _selectedElementId;
  bool _showTemplates = false;
  bool _showLayers = false;

  // Auto-save timer
  late DateTime _lastAutoSave = DateTime.now();

  // Dummy product for the base t-shirt
  final Product _baseProduct = Product(
    id: "custom-tee-001",
    title: "Men's Custom T-Shirt",
    slug: "mens-custom-tee",
    description: "A unique T-Shirt designed by you.",
    price: 29.99,
    imageUrl:
        "https://raw.githubusercontent.com/yemon/react-native-tshirt-design/master/assets/images/tshirt_white.png",
    categoryId: "custom",
    stockStatus: 'inStock',
  );

  @override
  void initState() {
    super.initState();
    _loadAutoSavedDesign();
    _historyService.addToHistory(_design);
  }

  @override
  void dispose() {
    _autoSaveDesign();
    super.dispose();
  }

  void _loadAutoSavedDesign() async {
    final autoSaved = await _storageService.getAutoSavedDesign();
    if (autoSaved != null && !autoSaved.isEmpty) {
      setState(() {
        _design = autoSaved;
        _historyService.clear();
        _historyService.addToHistory(_design);
      });
    }
  }

  void _autoSaveDesign() {
    if (DateTime.now().difference(_lastAutoSave).inSeconds >
        DesignStudioConstants.autoSaveIntervalSeconds) {
      _storageService.autoSaveDesign(_design);
      _lastAutoSave = DateTime.now();
    }
  }

  void _updateDesign(CustomDesign newDesign) {
    setState(() {
      _design = newDesign;
      _historyService.addToHistory(newDesign);
    });
    _autoSaveDesign();
  }

  void _undo() {
    final previousDesign = _historyService.undo();
    if (previousDesign != null) {
      setState(() {
        _design = previousDesign;
      });
    }
  }

  void _redo() {
    final nextDesign = _historyService.redo();
    if (nextDesign != null) {
      setState(() {
        _design = nextDesign;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Column(
            children: [
              // Canvas Area
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  child: Stack(
                    children: [
                      // Main design canvas
                      Center(
                        child: DesignCanvas(
                          design: _design,
                          selectedElementId: _selectedElementId,
                          onElementSelected: (id) =>
                              setState(() => _selectedElementId = id),
                          onDesignUpdate: _updateDesign,
                        ),
                      ),

                      // Layer management panel (right side)
                      if (_showLayers)
                        LayersPanel(
                          design: _design,
                          selectedElementId: _selectedElementId,
                          onElementSelected: (id) =>
                              setState(() => _selectedElementId = id),
                          onDuplicateElement: _duplicateElement,
                          onDeleteElement: _deleteElement,
                          onClose: () => setState(() => _showLayers = false),
                        ),

                      // Templates panel (left side)
                      if (_showTemplates)
                        TemplatesPanel(
                          templateService: _templateService,
                          onApplyTemplate: _applyTemplate,
                          onClose: () => setState(() => _showTemplates = false),
                        ),
                    ],
                  ),
                ),
              ),

              // Tools Panel
              Expanded(
                flex: 2,
                child: ToolsPanel(
                  design: _design,
                  selectedElementId: _selectedElementId,
                  templateService: _templateService,
                  onDesignUpdate: _updateDesign,
                  onAddTextElement: _addTextElement,
                  onAddStickerElement: _addStickerElement,
                  onToggleTextEffect: _toggleTextEffect,
                ),
              ),
            ],
          ),

          // AI Agent Chat Widget
          AgentChatWidget(
            currentDesign: _design,
            onDesignUpdate: _updateDesign,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'DESIGN STUDIO',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      actions: [
        // Undo button
        IconButton(
          onPressed: _historyService.canUndo ? _undo : null,
          icon: Icon(
            Icons.undo,
            color: _historyService.canUndo
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          tooltip: 'Undo',
        ),

        // Redo button
        IconButton(
          onPressed: _historyService.canRedo ? _redo : null,
          icon: Icon(
            Icons.redo,
            color: _historyService.canRedo
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          tooltip: 'Redo',
        ),

        // Save button
        IconButton(
          onPressed: () =>
              SaveDesignDialog.show(context, _design, _storageService),
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save Design',
        ),

        // Templates button
        IconButton(
          onPressed: () {
            setState(() {
              _showTemplates = !_showTemplates;
              _showLayers = false;
            });
          },
          icon: Icon(
            Icons.admin_panel_settings_outlined,
            color: _showTemplates
                ? AppColors.accentBlue
                : Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Templates',
        ),

        // Layers button
        IconButton(
          onPressed: () {
            setState(() {
              _showLayers = !_showLayers;
              _showTemplates = false;
            });
          },
          icon: Icon(
            Icons.layers_outlined,
            color: _showLayers
                ? AppColors.accentBlue
                : Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Layers',
        ),

        // Add to cart button
        TextButton(
          onPressed: () {
            context.read<CartService>().addToCart(
              _baseProduct,
              customDesign: _design,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Design added to cart! 🎨')),
            );
            Navigator.pop(context);
          },
          child: Text(
            'ADD TO CART',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for element management

  void _applyTemplate(DesignTemplate template) {
    _updateDesign(
      template.design.copyWith(
        // Preserve any existing legacy elements
        text: _design.text,
        textX: _design.textX,
        textY: _design.textY,
        fontSize: _design.fontSize,
        textColor: _design.textColor,
        sticker: _design.sticker,
        stickerX: _design.stickerX,
        stickerY: _design.stickerY,
        stickerSize: _design.stickerSize,
      ),
    );
  }

  void _addTextElement(String text, {String? fontFamily, double? fontSize}) {
    final element = DesignElement(
      id: DesignStudioUtils.generateElementId('text'),
      type: 'text',
      content: text,
      x: 0,
      y: 0,
      size: fontSize ?? DesignStudioConstants.defaultFontSize,
      color: '0xFF000000',
      properties: {
        'fontFamily': fontFamily ?? 'Outfit',
        'bold': false,
        'italic': false,
        'shadow': false,
      },
    );

    _updateDesign(_design.addElement(element));
    setState(() {
      _selectedElementId = element.id;
    });
  }

  void _addStickerElement(String sticker) {
    final element = DesignElement(
      id: DesignStudioUtils.generateElementId('sticker'),
      type: 'sticker',
      content: sticker,
      x: 0,
      y: 0,
      size: DesignStudioConstants.defaultStickerSize,
      color: '0xFF000000',
      properties: {},
    );

    _updateDesign(_design.addElement(element));
    setState(() {
      _selectedElementId = element.id;
    });
  }

  void _duplicateElement(String elementId) {
    if (elementId == 'legacy_text' && _design.text.isNotEmpty) {
      _addTextElement(_design.text, fontSize: _design.fontSize);
    } else if (elementId == 'legacy_sticker' && _design.sticker.isNotEmpty) {
      _addStickerElement(_design.sticker);
    } else {
      final element = _design.elements
          .where((e) => e.id == elementId)
          .firstOrNull;
      if (element != null) {
        final duplicatedElement = element.copyWith(
          id: DesignStudioUtils.generateElementId(element.type),
          x: element.x + 20,
          y: element.y + 20,
        );
        _updateDesign(_design.addElement(duplicatedElement));
      }
    }
  }

  void _deleteElement(String elementId) {
    if (elementId == 'legacy_text') {
      _updateDesign(_design.copyWith(text: ''));
    } else if (elementId == 'legacy_sticker') {
      _updateDesign(_design.copyWith(sticker: ''));
    } else {
      _updateDesign(_design.removeElement(elementId));
    }

    if (_selectedElementId == elementId) {
      setState(() {
        _selectedElementId = null;
      });
    }
  }

  void _toggleTextEffect(DesignElement element, String effect) {
    final updatedProps = Map<String, dynamic>.from(element.properties);
    updatedProps[effect] = !(updatedProps[effect] ?? false);

    final updatedElement = element.copyWith(properties: updatedProps);
    _updateDesign(_design.updateElement(element.id, updatedElement));
  }
}
