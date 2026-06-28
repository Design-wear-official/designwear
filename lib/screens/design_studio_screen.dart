import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

part 'design_studio/design_studio_screen_layout.dart';
part 'design_studio/design_studio_screen_actions.dart';

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
  final GlobalKey _backCanvasKey = GlobalKey();

  final AIAgentService _aiService = AIAgentService();
  bool _isAutoGenerating = false;

  String? _selectedElementId;
  bool _showTemplates = false;
  String _selectedGarmentType = 'tshirt';
  DesignSide _side = DesignSide.front;

  String _activeTool = 'layers';
  bool _isPanelCollapsedOnMobile = false;

  // Pre-load fallback shown until Sanity categories arrive. We currently sell
  // only T-Shirts, so this lists T-Shirt only — hoodie/polo/cap/tote stay
  // hidden from users until they're a real category. Once _loadCategories()
  // returns, the live category list replaces this.
  List<Map<String, String>> _garmentTypes = [
    {'id': 'tshirt', 'label': 'T-Shirt'},
  ];

  late DateTime _lastAutoSave = DateTime.now();
  bool _isPublishing = false;

  // Live centre-snap guide state, shared with the canvas + element drags.
  final ValueNotifier<({bool v, bool h})> _snapGuides =
      ValueNotifier((v: false, h: false));

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

  String? get _provenanceLabel {
    final src = widget.remixSource;
    if (src == null) return null;
    return 'from ${src.creatorHandle ?? src.title}';
  }

  @override
  void initState() {
    super.initState();
    _loadAutoSavedDesign();
    _historyService.addToHistory(_design);
    _loadCategories();
    // Ensure garment images are loaded from the backend before the first frame.
    GarmentService.loadGarments();
  }

  @override
  void dispose() {
    _autoSaveDesign();
    _snapGuides.dispose();
    super.dispose();
  }

  void _updateDesign(CustomDesign newDesign) {
    setState(() {
      _design = newDesign;
      _historyService.addToHistory(newDesign);
    });
    _autoSaveDesign();
  }

  void _undo() {
    final prev = _historyService.undo();
    if (prev != null) setState(() => _design = prev);
  }

  void _redo() {
    final next = _historyService.redo();
    if (next != null) setState(() => _design = next);
  }

  void _autoSaveDesign() {
    if (DateTime.now().difference(_lastAutoSave).inSeconds >
        DesignStudioConstants.autoSaveIntervalSeconds) {
      _storageService.autoSaveDesign(_design);
      _lastAutoSave = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    // On mobile the AI launcher must clear the bottom tools row (64) and, when
    // open, the active tool panel (240) instead of overlapping them.
    double aiBottomOffset = 20;
    if (isMobile) {
      const toolsRowHeight = 64.0;
      final panelHeight = _isPanelCollapsedOnMobile ? 0.0 : 240.0;
      aiBottomOffset =
          MediaQuery.paddingOf(context).bottom + toolsRowHeight + panelHeight + 14;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Focus enables desktop/web keyboard shortcuts for the selected
          // element (nudge / delete / duplicate / z-order / deselect).
          Focus(
            autofocus: true,
            onKeyEvent: _handleKey,
            child: SafeArea(
              child: isMobile ? _buildMobileBody() : _buildDesktopTabletBody(),
            ),
          ),
          AgentChatWidget(
            currentDesign: _design,
            onDesignUpdate: _onAiDesignUpdate,
            bottomOffset: aiBottomOffset,
          ),
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
}
