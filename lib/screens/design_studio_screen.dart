import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'package:designwear/screens/design_studio/design_studio.dart';
import 'package:designwear/screens/design_studio/widgets/widgets.dart';
import 'package:designwear/screens/virtual_tryon_screen.dart';
import 'package:designwear/config/config.dart';

class DesignStudioScreen extends StatefulWidget {
  /// When set, the studio opens in "remix" mode — provenance chip shows the
  /// parent's creator info and PUBLISH creates a new product linked to it.
  final Product? remixSource;

  const DesignStudioScreen({super.key, this.remixSource});

  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> {
  CustomDesign _design = CustomDesign();
  final DesignHistoryService _historyService = DesignHistoryService();
  final DesignTemplateService _templateService = DesignTemplateService();
  final DesignStorageService _storageService = DesignStorageService();
  final GlobalKey _canvasKey = GlobalKey();

  final AIAgentService _aiService = AIAgentService();
  bool _isAutoGenerating = false;

  String? _selectedElementId;
  bool _showTemplates = false;
  String _selectedGarmentType = 'tshirt';

  // Active tool state matching the 4-tool sidebar redesign
  String _activeTool = 'layers';
  bool _isPanelCollapsedOnMobile = false;

  List<Map<String, String>> _garmentTypes = [
    {'id': 'tshirt',  'label': 'T-Shirt' },
    {'id': 'hoodie',  'label': 'Hoodie'  },
    {'id': 'polo',    'label': 'Polo'    },
    {'id': 'cap',     'label': 'Cap'     },
    {'id': 'totebag', 'label': 'Tote Bag'},
  ];

  late DateTime _lastAutoSave = DateTime.now();
  bool _isPublishing = false;

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
    _loadCategories();
  }

  Future<void> _publishAndSync() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final creatorName = user?.name ?? 'Anonymous';
    final rawHandle = (user?.name ?? 'user')
        .split(' ')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final creatorHandle = '@$rawHandle';

    // Build lineage: parent's ancestors + parent as a new entry
    final remixSource = widget.remixSource;
    final parentLineage = remixSource?.lineage ?? [];
    final newLineage = [
      ...parentLineage,
      if (remixSource != null)
        {
          'handle': remixSource.creatorHandle ?? '',
          'version': remixSource.title,
          'baseColor': remixSource.garmentBaseColor ?? '',
          'artText': remixSource.artText ?? '',
        },
    ];

    // Convert Flutter '0xFFRRGGBB' → '#RRGGBB'
    final baseColorHex = _design.baseColor.startsWith('0x')
        ? '#${_design.baseColor.substring(4)}'
        : _design.baseColor;

    // First text element content as art text
    final textEl = _design.elements
        .where((e) => e.type == DesignElementType.text)
        .firstOrNull;
    final artText = (textEl != null && textEl.content.isNotEmpty)
        ? textEl.content
        : (_design.name.isNotEmpty ? _design.name : null);

    final designName = _design.name.isNotEmpty ? _design.name : 'Remix by $creatorHandle';

    setState(() => _isPublishing = true);
    try {
      final apiService = ApiService.webApi(WebApiConfig.baseUrl);
      final productId = await apiService.publishRemix(
        creatorHandle: creatorHandle,
        creatorName: creatorName,
        garmentType: _selectedGarmentType,
        title: designName,
        garmentBaseColor: baseColorHex,
        artText: artText,
        remixedFromId: remixSource?.id,
        remixedFromHandle: remixSource?.creatorHandle,
        remixedFromVersion: remixSource?.title,
        lineage: newLineage,
        tags: remixSource?.tags ?? [],
      );

      // Save to local storage so it's accessible offline
      await _storageService.saveDesign(SavedDesign(
        id: productId,
        name: designName,
        design: _design,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Design published and synced to Sanity + Firebase!'),
          backgroundColor: Color(0xFF2D8B57),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publish failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _loadCategories() async {
    try {
      final sanityService = SanityService();
      final categories = await sanityService.fetchCategories();
      if (!mounted) return;
      if (categories.isNotEmpty) {
        setState(() {
          _garmentTypes = categories.map((cat) => {
            'id': cat.slug.isNotEmpty ? cat.slug : cat.id,
            'label': cat.title,
          }).toList();
          // Ensure selected garment type matches one of the fetched ones if possible
          if (_garmentTypes.isNotEmpty && !_garmentTypes.any((t) => t['id'] == _selectedGarmentType)) {
            _selectedGarmentType = _garmentTypes.first['id']!;
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _autoSaveDesign();
    super.dispose();
  }

  static const _autoThemes = [
    'sunrise vibes streetwear',
    'midnight galaxy abstract',
    'wild nature adventure',
    'urban hustle city',
    'summer beach waves',
    'retro 80s neon',
    'minimal zen geometric',
    'hip hop music culture',
  ];

  void _loadAutoSavedDesign() async {
    final autoSaved = await _storageService.getAutoSavedDesign();
    if (autoSaved != null && !autoSaved.isEmpty) {
      setState(() {
        _design = autoSaved;
        _historyService.clear();
        _historyService.addToHistory(_design);
      });
    } else {
      _autoGenerateDesign();
    }
  }

  void _autoGenerateDesign() async {
    setState(() => _isAutoGenerating = true);
    final theme = _autoThemes[math.Random().nextInt(_autoThemes.length)];
    final imageBase64 = await _aiService.generateDesignImage(theme);
    if (!mounted) return;
    setState(() {
      _isAutoGenerating = false;
      if (imageBase64 != null) {
        _design = CustomDesign(designImageBase64: imageBase64, name: theme);
        _historyService.clear();
        _historyService.addToHistory(_design);
      }
    });
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
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SafeArea(
            child: isMobile ? _buildMobileBody() : _buildDesktopTabletBody(),
          ),

          // AI Agent Chat Widget (positioned absolute overlay)
          AgentChatWidget(
            currentDesign: _design,
            onDesignUpdate: _updateDesign,
          ),

          // Templates Panel overlay
          if (_showTemplates)
            TemplatesPanel(
              templateService: _templateService,
              onApplyTemplate: _applyTemplate,
              onClose: () => setState(() => _showTemplates = false),
            ),
        ],
      ),
    );
  }

  // ── 3-Pane Layout for Desktop / Tablet ─────────────────────────────────────
  Widget _buildDesktopTabletBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pane 1: Sidebar Tool Selector
        SizedBox(
          width: 88,
          child: ToolsPanel(
            activeTool: _activeTool,
            isVertical: true,
            onToolSelected: (toolId) {
              setState(() {
                _activeTool = toolId;
              });
            },
          ),
        ),

        // Pane 2: Mid Canvas Area
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildGarmentTypeSelector(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DesignCanvas(
                            canvasKey: _canvasKey,
                            design: _design,
                            selectedElementId: _selectedElementId,
                            garmentType: _selectedGarmentType,
                            onElementSelected: (id) =>
                                setState(() => _selectedElementId = id),
                            onDesignUpdate: _updateDesign,
                          ),
                          if (_isAutoGenerating) _buildGeneratingOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Pane 3: Side Panel (active pane contents)
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(left: BorderSide(color: hair, width: 1)),
          ),
          padding: const EdgeInsets.all(20),
          child: _buildActivePaneContent(),
        ),
      ],
    );
  }

  // ── Layout for Mobile ──────────────────────────────────────────────────────
  Widget _buildMobileBody() {
    return Column(
      children: [
        _buildGarmentTypeSelector(),

        // Canvas Area (Flex fill)
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DesignCanvas(
                      canvasKey: _canvasKey,
                      design: _design,
                      selectedElementId: _selectedElementId,
                      garmentType: _selectedGarmentType,
                      onElementSelected: (id) =>
                          setState(() => _selectedElementId = id),
                      onDesignUpdate: _updateDesign,
                    ),
                    if (_isAutoGenerating) _buildGeneratingOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mobile active panel (collapsible drawer above tools)
        if (!_isPanelCollapsedOnMobile)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.hairDark
                      : AppColors.hairLight,
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: _buildActivePaneContent(),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _isPanelCollapsedOnMobile = true),
                  ),
                ),
              ],
            ),
          ),

        // Mobile Tools Bar (horizontal)
        SizedBox(
          height: 64,
          child: ToolsPanel(
            activeTool: _activeTool,
            isVertical: false,
            onToolSelected: (toolId) {
              setState(() {
                _activeTool = toolId;
                _isPanelCollapsedOnMobile = false; // Expand panel on tap
              });
            },
          ),
        ),
      ],
    );
  }

  // Helper to build current active pane
  Widget _buildActivePaneContent() {
    switch (_activeTool) {
      case 'layers':
        return LayersPanel(
          design: _design,
          selectedElementId: _selectedElementId,
          onElementSelected: (id) => setState(() => _selectedElementId = id),
          onDuplicateElement: _duplicateElement,
          onDeleteElement: _deleteElement,
          onReorderElements: _reorderElements,
          onAddLayerTap: () {
            // Add a default text layer as demo flow
            _addTextElement('NEW TEXT');
          },
        );
      case 'color':
        return ColorPanel(
          design: _design,
          onDesignUpdate: _updateDesign,
        );
      case 'text':
        return TextTab(
          design: _design,
          selectedElementId: _selectedElementId,
          templateService: _templateService,
          onDesignUpdate: _updateDesign,
          onAddTextElement: (text, font) => _addTextElement(text, fontFamily: font),
          onToggleTextEffect: _toggleTextEffect,
        );
      case 'emoji':
        return StickersTab(
          onAddStickerElement: _addStickerElement,
        );
      case 'place':
        return PlacementPanel(
          design: _design,
          onDesignUpdate: _updateDesign,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGeneratingOverlay() {
    return Container(
      width: DesignStudioConstants.canvasWidth + 32,
      height: DesignStudioConstants.canvasWidth * 1.25 + 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Generating your design…',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return AppBar(
      titleSpacing: 16,
      title: ResponsiveUtils.isMobile(context)
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DESIGN',
                  style: GoogleFonts.archivo(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cs.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'WEAR',
                  style: GoogleFonts.archivo(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.marigold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
      centerTitle: false,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: hair),
      ),
      actions: [
        // Provenance Mini Chip (visible on tablet/desktop)
        if (!ResponsiveUtils.isMobile(context))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2232) : const Color(0xFFEBEBF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fork_right, size: 14, color: isDark ? AppColors.stone : Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Remixing ',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: isDark ? AppColors.stone : Colors.black54),
                    ),
                    Text(
                      widget.remixSource != null
                          ? '${widget.remixSource!.creatorHandle ?? widget.remixSource!.title}\'s ${widget.remixSource!.productType ?? 'Design'}'
                          : 'New Design',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: _historyService.canUndo ? _undo : null,
          icon: Icon(
            Icons.undo,
            color: _historyService.canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
            size: 20,
          ),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _historyService.canRedo ? _redo : null,
          icon: Icon(
            Icons.redo,
            color: _historyService.canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
            size: 20,
          ),
          tooltip: 'Redo',
        ),
        IconButton(
          onPressed: () => SaveDesignDialog.show(context, _design, _storageService),
          icon: const Icon(Icons.save_outlined, size: 20),
          tooltip: 'Save Design',
        ),
        IconButton(
          onPressed: _navigateToTryOn,
          icon: const Icon(Icons.face_retouching_natural_outlined, size: 20),
          tooltip: 'Virtual Try-On',
        ),
        IconButton(
          onPressed: () => setState(() => _showTemplates = !_showTemplates),
          icon: Icon(Icons.style_outlined, size: 20, color: _showTemplates ? AppColors.marigold : cs.onSurface),
          tooltip: 'Templates',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 6),
          child: Center(
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishAndSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF15182B),
                foregroundColor: isDark ? const Color(0xFF15182B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFF15182B) : Colors.white,
                      ),
                    )
                  : Text(
                      'PUBLISH',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentTypeSelector() {
    return SizedBox(
      height: 48.h,
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
                color: isSelected ? AppColors.marigold : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.marigold
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.marigold.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
    _updateDesign(template.design);
  }

  void _addTextElement(String text, {String? fontFamily, double? fontSize}) {
    final element = DesignElement(
      id: DesignStudioUtils.generateElementId(DesignElementType.text),
      type: DesignElementType.text,
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

  void _addStickerElement(String emoji) {
    final element = DesignElement(
      id: DesignStudioUtils.generateElementId(DesignElementType.sticker),
      type: DesignElementType.sticker,
      content: emoji,
      x: 0,
      y: 0,
      size: DesignStudioConstants.defaultStickerSize,
      color: '0xFF000000',
      properties: const {},
    );
    _updateDesign(_design.addElement(element));
    setState(() => _selectedElementId = element.id);
  }

  void _duplicateElement(String elementId) {
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

  void _deleteElement(String elementId) {
    _updateDesign(_design.removeElement(elementId));

    if (_selectedElementId == elementId) {
      setState(() {
        _selectedElementId = null;
      });
    }
  }

  void _reorderElements(int oldIndex, int newIndex) {
    _updateDesign(_design.reorderElements(oldIndex, newIndex));
  }

  void _toggleTextEffect(DesignElement element, String effect) {
    final updatedProps = Map<String, dynamic>.from(element.properties);
    updatedProps[effect] = !(updatedProps[effect] ?? false);

    final updatedElement = element.copyWith(properties: updatedProps);
    _updateDesign(_design.updateElement(element.id, updatedElement));
  }

  void _navigateToTryOn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.marigold),
      ),
    );

    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture canvas context.')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted) return;
      Navigator.pop(context);

      if (bytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VirtualTryOnScreen(
              product: _baseProduct.copyWith(
                title: _design.name.isNotEmpty ? _design.name : _baseProduct.title,
              ),
              customClothingBytes: bytes,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export custom design.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing try-on: $e')),
        );
      }
    }
  }

}
