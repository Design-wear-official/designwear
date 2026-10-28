import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/challenge.dart';
import 'package:designwear/models/design.dart' show CommunityDesign;
import 'package:designwear/models/models.dart';
import 'package:designwear/api/api_client.dart';
import 'package:designwear/logging/app_log.dart';
import 'package:designwear/screens/account/auth_screens.dart'
    show requireSignIn;
import 'package:designwear/services/community/community_service.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'package:designwear/screens/studio/editor/design_studio.dart';
import 'package:designwear/screens/studio/editor/widgets/widgets.dart';
import 'package:designwear/screens/ai/virtual_tryon_screen.dart';

part 'screen/design_studio_screen_layout.dart';
part 'screen/design_studio_screen_actions.dart';

class DesignStudioScreen extends StatefulWidget {
  /// A design to start from (a saved one, or a community design being remixed).
  final CustomDesign? initialDesign;

  /// When set, the studio opens in "remix" mode: the provenance chip shows the
  /// parent's creator and PUBLISH creates a new design linked to it.
  final CommunityDesign? remixSource;

  /// A catalog product being remixed (the provenance chip names it).
  final Product? remixProduct;

  /// A weekly challenge this design is entered into when it is published.
  final Challenge? challenge;

  const DesignStudioScreen({
    super.key,
    this.initialDesign,
    this.remixSource,
    this.remixProduct,
    this.challenge,
  });

  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> {
  CustomDesign _design = CustomDesign();
  final DesignHistoryService _historyService = DesignHistoryService();
  final DesignTemplateService _templateService = DesignTemplateService();
  final DesignStorageService _storageService = DesignStorageService();
  final GlobalKey _canvasKey = GlobalKey();
  // Always-rendered, offstage front and back canvases: publishing captures
  // these, so it works whichever view (front/back/left/right) is active.
  final GlobalKey _frontCaptureKey = GlobalKey();
  final GlobalKey _backCaptureKey = GlobalKey();

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
  final List<Map<String, String>> _garmentTypes = [
    {'id': 'tshirt', 'label': 'T-Shirt'},
  ];

  late DateTime _lastAutoSave = DateTime.now();
  bool _isPublishing = false;

  // Live centre-snap guide state, shared with the canvas + element drags.
  final ValueNotifier<({bool v, bool h})> _snapGuides = ValueNotifier((
    v: false,
    h: false,
  ));

  // Stand-in product the try-on screen needs; the garment image itself is the
  // design, passed separately as bytes.
  final Product _baseProduct = const Product(
    id: 'custom-tee-001',
    title: "Men's Custom T-Shirt",
    price: 499,
    description: 'A unique T-Shirt designed by you.',
  );

  /// Id of this design on the API once it has been published (so a second
  /// publish updates it instead of creating a duplicate).
  String? _serverId;

  String? get _provenanceLabel {
    final src = widget.remixSource;
    if (src != null) return 'from @${src.creatorHandle}';
    final product = widget.remixProduct;
    if (product != null) return 'from ${product.title}';
    final challenge = widget.challenge;
    return challenge == null ? null : 'challenge: ${challenge.title}';
  }

  @override
  void initState() {
    super.initState();
    _loadAutoSavedDesign();
    _historyService.addToHistory(_design);
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
          MediaQuery.paddingOf(context).bottom +
          toolsRowHeight +
          panelHeight +
          14;
    }

    return Scaffold(
      backgroundColor: AppColors.dsPageBg(
        Theme.of(context).brightness == Brightness.dark,
      ),
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
