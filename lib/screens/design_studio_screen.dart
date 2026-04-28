import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/custom_design.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/design_template_service.dart';
import '../services/design_history_service.dart';
import '../services/design_storage_service.dart';
import '../services/design_studio_demo_service.dart';
import '../styles/app_colors.dart';
import '../utils/responsive_utils.dart';
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
  bool _showDemoHints = true;
  int _currentDemoTipIndex = 0;
  String _selectedGarmentType = 'tshirt';

  static const _garmentTypes = [
    {'id': 'tshirt',  'label': 'T-Shirt',  'emoji': '👕'},
    {'id': 'hoodie',  'label': 'Hoodie',   'emoji': '🧥'},
    {'id': 'polo',    'label': 'Polo',     'emoji': '👔'},
    {'id': 'cap',     'label': 'Cap',      'emoji': '🧢'},
    {'id': 'totebag', 'label': 'Tote Bag', 'emoji': '👜'},
  ];

  late DateTime _lastAutoSave = DateTime.now();

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
              if (_showDemoHints) _buildDemoHintBanner(),
              _buildGarmentTypeSelector(),
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

          // Demo quick start overlay
          if (_showDemoHints && _design.isEmpty) _buildDemoQuickStartOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                'DW',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DESIGN STUDIO',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cs.outline.withValues(alpha: 0.12)),
      ),
      actions: [
        IconButton(
          onPressed: _historyService.canUndo ? _undo : null,
          icon: Icon(
            Icons.undo,
            color: _historyService.canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
          ),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _historyService.canRedo ? _redo : null,
          icon: Icon(
            Icons.redo,
            color: _historyService.canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
          ),
          tooltip: 'Redo',
        ),
        IconButton(
          onPressed: () => SaveDesignDialog.show(context, _design, _storageService),
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save Design',
        ),
        IconButton(
          onPressed: () => setState(() { _showTemplates = !_showTemplates; _showLayers = false; }),
          icon: Icon(Icons.style_outlined, color: _showTemplates ? AppColors.accentBlue : cs.onSurface),
          tooltip: 'Templates',
        ),
        IconButton(
          onPressed: () => setState(() { _showLayers = !_showLayers; _showTemplates = false; }),
          icon: Icon(Icons.layers_outlined, color: _showLayers ? AppColors.accentBlue : cs.onSurface),
          tooltip: 'Layers',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () {
              context.read<CartService>().addToCart(_baseProduct, customDesign: _design);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Design added to cart! 🎨')),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
              foregroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'ADD TO CART',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentTypeSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _garmentTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _garmentTypes[index];
          final isSelected = _selectedGarmentType == type['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedGarmentType = type['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentBlue
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type['emoji']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    type['label']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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


  Widget _buildDemoHintBanner() {
    final demoService = DesignStudioDemoService();
    final tips = demoService.demoTips;
    
    if (tips.isEmpty) return const SizedBox.shrink();

    final currentTip = tips[_currentDemoTipIndex % tips.length];
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.horizontalPadding(context),
        vertical: ResponsiveSizes.verticalPadding(context),
      ),
      padding: EdgeInsets.all(ResponsiveSizes.verticalPadding(context) + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            currentTip['icon']!,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTip['title']!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  currentTip['description']!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (_currentDemoTipIndex > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () => setState(() => _currentDemoTipIndex--),
                ),
              if (_currentDemoTipIndex < tips.length - 1)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => setState(() => _currentDemoTipIndex++),
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _showDemoHints = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoQuickStartOverlay() {
    final topOffset = MediaQuery.of(context).padding.top +
        kToolbarHeight +
        ResponsiveSizes.verticalPadding(context);
    return Positioned(
      top: topOffset,
      left: ResponsiveSizes.horizontalPadding(context),
      right: ResponsiveSizes.horizontalPadding(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentBlue),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎨 Welcome to Design Studio!',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start creating your custom design or choose from our demo templates',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStartButton(
                    'Add Text',
                    Icons.text_fields,
                    () {
                      _addTextElement('Your Text Here');
                      setState(() => _showDemoHints = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickStartButton(
                    'Add Sticker',
                    Icons.emoji_emotions,
                    () {
                      _addStickerElement('😎');
                      setState(() => _showDemoHints = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickStartButton(
                    'Templates',
                    Icons.admin_panel_settings,
                    () {
                      setState(() {
                        _showTemplates = true;
                        _showDemoHints = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTextEffect(DesignElement element, String effect) {
    final updatedProps = Map<String, dynamic>.from(element.properties);
    updatedProps[effect] = !(updatedProps[effect] ?? false);

    final updatedElement = element.copyWith(properties: updatedProps);
    _updateDesign(_design.updateElement(element.id, updatedElement));
  }
}
