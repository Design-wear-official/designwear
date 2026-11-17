// These extension methods on the screen's State call setState directly; the
// extension only exists to split one large State class across files.
// ignore_for_file: invalid_use_of_protected_member
part of '../design_studio_screen.dart';

extension _LayoutMethods on _DesignStudioScreenState {
  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = AppColors.dsBarBg(isDark);
    final hair = AppColors.dsBorder(isDark);
    final textPrimary = AppColors.dsTextPrimary(isDark);
    final textSecondary = AppColors.dsTextSecondary(isDark);

    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 16,
      title: ResponsiveUtils.isMobile(context)
          ? null
          // Shrinks the wordmark instead of overflowing when the toolbar
          // actions take most of the width (tablet-sized windows).
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DESIGN',
                    style: GoogleFonts.archivo(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    'WEAR',
                    style: GoogleFonts.archivo(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.dsAccent,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
      centerTitle: false,
      backgroundColor: barBg,
      foregroundColor: textPrimary,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: hair),
      ),
      actions: [
        if (!ResponsiveUtils.isMobile(context))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dsPillBg(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hair),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fork_right, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Remixing ',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      widget.remixSource != null
                          ? '@${widget.remixSource!.creatorHandle}\'s ${widget.remixSource!.name}'
                          : widget.remixProduct?.title ?? 'an original tee',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
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
            color: _historyService.canUndo
                ? textSecondary
                : textSecondary.withValues(alpha: 0.35),
            size: 20,
          ),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _historyService.canRedo ? _redo : null,
          icon: Icon(
            Icons.redo,
            color: _historyService.canRedo
                ? textSecondary
                : textSecondary.withValues(alpha: 0.35),
            size: 20,
          ),
          tooltip: 'Redo',
        ),
        // Secondary actions: inline on desktop/tablet, overflow menu on mobile
        // so the bar doesn't overflow on narrow phones.
        if (!ResponsiveUtils.isMobile(context)) ...[
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: hair,
          ),
          IconButton(
            onPressed: () => SaveDesignDialog.show(
              context,
              _design,
              _storageService,
              captureCallback: _captureCanvasPng,
            ),
            icon: Icon(Icons.save_outlined, size: 20, color: textSecondary),
            tooltip: 'Save Design',
          ),
          IconButton(
            onPressed: _showAllViews,
            icon: Icon(
              Icons.grid_view_outlined,
              size: 20,
              color: textSecondary,
            ),
            tooltip: 'All areas',
          ),
          IconButton(
            onPressed: _open3DPreview,
            icon: Icon(
              Icons.view_in_ar_outlined,
              size: 20,
              color: textSecondary,
            ),
            tooltip: '3D Preview',
          ),
          IconButton(
            onPressed: _navigateToTryOn,
            icon: Icon(
              Icons.face_retouching_natural_outlined,
              size: 20,
              color: textSecondary,
            ),
            tooltip: 'Virtual Try-On',
          ),
          IconButton(
            onPressed: () => setState(() => _showTemplates = !_showTemplates),
            icon: Icon(
              Icons.style_outlined,
              size: 20,
              color: _showTemplates ? AppColors.dsAccent : textSecondary,
            ),
            tooltip: 'Templates',
          ),
        ] else
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: textSecondary),
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'save':
                  SaveDesignDialog.show(
                    context,
                    _design,
                    _storageService,
                    captureCallback: _captureCanvasPng,
                  );
                  break;
                case 'areas':
                  _showAllViews();
                  break;
                case '3d':
                  _open3DPreview();
                  break;
                case 'tryon':
                  _navigateToTryOn();
                  break;
                case 'templates':
                  setState(() => _showTemplates = !_showTemplates);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.save_outlined, size: 20),
                  title: Text('Save Design'),
                ),
              ),
              PopupMenuItem(
                value: 'areas',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.grid_view_outlined, size: 20),
                  title: Text('All areas'),
                ),
              ),
              PopupMenuItem(
                value: '3d',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.view_in_ar_outlined, size: 20),
                  title: Text('3D Preview'),
                ),
              ),
              PopupMenuItem(
                value: 'tryon',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.face_retouching_natural_outlined,
                    size: 20,
                  ),
                  title: Text('Virtual Try-On'),
                ),
              ),
              PopupMenuItem(
                value: 'templates',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.style_outlined, size: 20),
                  title: Text('Templates'),
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 6),
          child: Center(
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishAndSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dsPublishBg(isDark),
                foregroundColor: AppColors.dsPublishText(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.dsPublishText(isDark),
                      ),
                    )
                  : Text(
                      'PUBLISH',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop / Tablet 3-pane ─────────────────────────────────────────────────

  /// The canvas with the off-screen front/back capture copies and the busy overlay.
  Widget _canvasStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        DesignCanvas(
          canvasKey: _canvasKey,
          design: _design,
          selectedElementId: _selectedElementId,
          garmentType: _selectedGarmentType,
          side: _side,
          provenanceLabel: _provenanceLabel,
          onElementSelected: (id) => setState(() => _selectedElementId = id),
          onElementPreview: _previewElement,
          onElementCommit: _commitElementChange,
          onElementDelete: _deleteElement,
          onElementEdit: _editElement,
          onSideChanged: (s) => setState(() => _side = s),
          showSideToggle: false,
          bare: _capturingViews,
          snapGuides: _snapGuides,
          mockupUrl: _capturingViews ? null : _mockupUrl,
          onOpenLayers: _layerJob == null ? null : _openLayers,
        ),
        // Off-screen front and back canvases, captured for the published previews.

        Offstage(
          child: DesignCanvas(
            canvasKey: _frontCaptureKey,

            design: _design,

            selectedElementId: null,

            garmentType: _selectedGarmentType,

            side: DesignSide.front,

            onElementSelected: (_) {},

            onElementPreview: (_) {},

            onElementCommit: () {},

            onElementDelete: (_) {},

            onSideChanged: (_) {},
          ),
        ),

        Offstage(
          child: DesignCanvas(
            canvasKey: _backCaptureKey,

            design: _design,

            selectedElementId: null,

            garmentType: _selectedGarmentType,

            side: DesignSide.back,

            onElementSelected: (_) {},

            onElementPreview: (_) {},

            onElementCommit: () {},

            onElementDelete: (_) {},

            onSideChanged: (_) {},
          ),
        ),
        if (_isAutoGenerating) _buildGeneratingOverlay(),
      ],
    );
  }

  /// How much larger than its natural 332 px the canvas is drawn: as big as the free space allows on
  /// desktop and tablet, filling the width on a phone.
  double _canvasScale() {
    final size = MediaQuery.sizeOf(context);
    const w = DesignStudioConstants.canvasWidth + 32;
    const h = DesignStudioConstants.canvasWidth * 1.25 + 32;
    if (ResponsiveUtils.isMobile(context)) {
      // Fit the whole shirt above the tools panel (when it is open) instead of cutting it off.
      final panel = _isPanelCollapsedOnMobile ? 0 : 240;
      final freeH =
          size.height -
          MediaQuery.paddingOf(context).vertical -
          56 -
          48 -
          52 -
          64 -
          32 -
          panel;
      return math
          .min(math.min((size.width - 24) / w, freeH / h), 1.25)
          .clamp(0.7, 1.25)
          .toDouble();
    }
    final freeW = size.width - 88 - 340 - 80;
    final freeH = size.height - 64 - 48 - 56 - 72 - 120;
    return math.min(freeW / w, freeH / h).clamp(1.0, 1.9).toDouble();
  }

  Widget _scaledCanvas(Widget canvas) {
    const w = DesignStudioConstants.canvasWidth + 32;
    const h = DesignStudioConstants.canvasWidth * 1.25 + 32;
    final scale = _canvasScale();
    return CanvasScale(
      scale: scale,
      child: SizedBox(
        width: w * scale,
        height: h * scale,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(width: w, height: h, child: canvas),
        ),
      ),
    );
  }

  /// Front / Back / sleeves / pockets as a bar above the canvas (not on top of the garment), with
  /// large touch targets; it scrolls sideways on a phone.
  Widget _buildSideBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final garment = GarmentRegistry.byId(_selectedGarmentType);
    final style = GarmentStyles.resolve(_selectedGarmentType, _design.styleId);
    final sides = <(String, DesignSide)>[
      ('Front', DesignSide.front),
      ('Back', DesignSide.back),
      if (garment.hasSleeves) ('Left', DesignSide.left),
      if (garment.hasSleeves) ('Right', DesignSide.right),
      // A pocket is the customer's choice (Pocket tee styles): its print area only
      // appears for a pocket the chosen style actually has.
      if (style != null && style.hasPocket(DesignSide.leftPocket))
        ('L Pocket', DesignSide.leftPocket),
      if (style != null && style.hasPocket(DesignSide.rightPocket))
        ('R Pocket', DesignSide.rightPocket),
    ];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sides.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, target) = sides[i];
          final active = _side == target;
          return GestureDetector(
            onTap: () => setState(() {
              _side = target;
              _selectedElementId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.white : AppColors.dsFrameChrome,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? Colors.white : AppColors.dsBorder(isDark),
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: active
                      ? const Color(0xFF14161C)
                      : const Color(0xFFC9C6BC),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTabletBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = AppColors.dsBorder(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 88,
          child: ToolsPanel(
            activeTool: _activeTool,
            isVertical: true,
            onToolSelected: (t) => setState(() => _activeTool = t),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.dsPageBg(isDark),
            child: Column(
              children: [
                _buildGarmentTypeSelector(),
                _buildSideBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      child: _scaledCanvas(_canvasStack()),
                    ),
                  ),
                ),
                _buildElementActionBar(),
              ],
            ),
          ),
        ),
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: AppColors.dsBarBg(isDark),
            border: Border(left: BorderSide(color: hair, width: 1)),
          ),
          padding: const EdgeInsets.all(24),
          child: _buildActivePaneContent(),
        ),
      ],
    );
  }

  // ── Mobile layout ───────────────────────────────────────────────────────────

  Widget _buildMobileBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildGarmentTypeSelector(),
        _buildSideBar(),
        Expanded(
          child: Container(
            color: AppColors.dsPageBg(isDark),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _scaledCanvas(_canvasStack()),
              ),
            ),
          ),
        ),
        _buildElementActionBar(),
        if (!_isPanelCollapsedOnMobile)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.dsBarBg(isDark),
              border: Border(
                top: BorderSide(color: AppColors.dsBorder(isDark), width: 1),
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
                    onPressed: () =>
                        setState(() => _isPanelCollapsedOnMobile = true),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 64,
          child: ToolsPanel(
            activeTool: _activeTool,
            isVertical: false,
            onToolSelected: (t) {
              setState(() {
                _activeTool = t;
                _isPanelCollapsedOnMobile = false;
              });
            },
          ),
        ),
      ],
    );
  }

  // ── Active pane content ─────────────────────────────────────────────────────

  Widget _buildActivePaneContent() {
    switch (_activeTool) {
      case 'layers':
        return LayersPanel(
          design: _design,
          selectedElementId: _selectedElementId,
          provenanceLabel: _provenanceLabel,
          onElementSelected: (id) => setState(() => _selectedElementId = id),
          onDuplicateElement: _duplicateElement,
          onDeleteElement: _deleteElement,
          onReorderElements: _reorderElements,
          onAddLayerTap: () => _addTextElement('NEW TEXT'),
        );
      case 'color':
        return ColorPanel(
          design: _design,
          onDesignUpdate: _updateDesign,
          garmentColors: GarmentRegistry.byId(_selectedGarmentType).colors,
        );
      case 'text':
        return TextTab(
          design: _design,
          selectedElementId: _selectedElementId,
          templateService: _templateService,
          onDesignUpdate: _updateDesign,
          onAddTextElement: (text, font) =>
              _addTextElement(text, fontFamily: font),
          onToggleTextEffect: _toggleTextEffect,
        );
      case 'emoji':
        return StickersTab(
          onAddStickerElement: _addStickerElement,
          onAddImageSticker: _addImageStickerElement,
        );
      case 'shapes':
        return _buildShapesPane();
      case 'place':
        return PlacementPanel(design: _design, onDesignUpdate: _updateDesign);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Element action bar (appears when an element is selected) ────────────────

  Widget _buildElementActionBar() {
    if (_selectedElementId == null) return const SizedBox.shrink();

    final selected = _design.elements.cast<DesignElement?>().firstWhere(
      (e) => e?.id == _selectedElementId,
      orElse: () => null,
    );
    if (selected == null) return const SizedBox.shrink();

    final sideElements = _design.elementsForSide(_side);
    final idx = sideElements.indexWhere((e) => e.id == _selectedElementId);
    final canSendBack = idx > 0;
    final canBringForward = idx >= 0 && idx < sideElements.length - 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = AppColors.dsBorder(isDark);
    final cs = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.dsBarBg(isDark),
          border: Border(top: BorderSide(color: hair)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _elementTypeIcon(selected.type),
                    size: 15,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _elementTypeName(selected.type),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ElementActionBtn(
                    icon: Icons.flip_to_back,
                    tooltip: 'Send back',
                    enabled: canSendBack,
                    onTap: () => _reorderElements(idx, idx - 1),
                  ),
                  _ElementActionBtn(
                    icon: Icons.flip_to_front,
                    tooltip: 'Bring forward',
                    enabled: canBringForward,
                    onTap: () => _reorderElements(idx, idx + 1),
                  ),
                  _ElementActionBtn(
                    icon: Icons.copy_all_outlined,
                    tooltip: 'Duplicate',
                    onTap: () => _duplicateElement(_selectedElementId!),
                  ),
                  const Spacer(),
                  // Remove — prominent red button
                  GestureDetector(
                    onTap: () => _deleteElement(_selectedElementId!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Remove',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildElementAdjustRow(selected, cs),
              _buildPlacementRow(cs),
            ],
          ),
        ),
      ),
    );
  }

  // ── Opacity + flip controls for the selected element ────────────────────────

  Widget _buildElementAdjustRow(DesignElement selected, ColorScheme cs) {
    final flipH = selected.properties['flipH'] == true;
    final flipV = selected.properties['flipV'] == true;
    final muted = cs.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.opacity, size: 15, color: muted),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: selected.opacity.clamp(0.0, 1.0),
                min: 0.1,
                max: 1.0,
                activeColor: AppColors.marigold,
                onChanged: _previewSelectedOpacity,
                onChangeEnd: (_) => _commitElementChange(),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${(selected.opacity * 100).round()}%',
              style: GoogleFonts.spaceMono(fontSize: 11, color: muted),
            ),
          ),
          const SizedBox(width: 4),
          _ElementActionBtn(
            icon: Icons.align_horizontal_center,
            tooltip: 'Centre horizontally',
            onTap: () => _centreSelected(horizontal: true),
          ),
          _ElementActionBtn(
            icon: Icons.align_vertical_center,
            tooltip: 'Centre vertically',
            onTap: () => _centreSelected(vertical: true),
          ),
          _ElementActionBtn(
            icon: Icons.swap_horiz,
            tooltip: 'Flip horizontal',
            onTap: () => _toggleFlip('flipH'),
            active: flipH,
          ),
          _ElementActionBtn(
            icon: Icons.swap_vert,
            tooltip: 'Flip vertical',
            onTap: () => _toggleFlip('flipV'),
            active: flipV,
          ),
        ],
      ),
    );
  }

  // ── Exact placement: arrow buttons (hold to repeat) and smaller / bigger ─────

  Widget _buildPlacementRow(ColorScheme cs) {
    final muted = cs.onSurface.withValues(alpha: 0.6);
    final step = _nudgeStep;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.open_with, size: 15, color: muted),
          const SizedBox(width: 4),
          HoldButton(
            icon: Icons.arrow_back,
            tooltip: 'Move left',
            onStep: () => _nudgeHeld(-step, 0),
            onEnd: _commitElementChange,
          ),
          HoldButton(
            icon: Icons.arrow_upward,
            tooltip: 'Move up',
            onStep: () => _nudgeHeld(0, -step),
            onEnd: _commitElementChange,
          ),
          HoldButton(
            icon: Icons.arrow_downward,
            tooltip: 'Move down',
            onStep: () => _nudgeHeld(0, step),
            onEnd: _commitElementChange,
          ),
          HoldButton(
            icon: Icons.arrow_forward,
            tooltip: 'Move right',
            onStep: () => _nudgeHeld(step, 0),
            onEnd: _commitElementChange,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _nudgeStep = step == 1 ? 10 : 1),
            child: Tooltip(
              message: 'How far each arrow press moves',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: muted.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Step ${step.round()}',
                  style: GoogleFonts.spaceMono(fontSize: 11, color: muted),
                ),
              ),
            ),
          ),
          const Spacer(),
          Icon(Icons.aspect_ratio, size: 15, color: muted),
          HoldButton(
            icon: Icons.remove,
            tooltip: 'Smaller',
            onStep: () => _resizeHeld(0.97),
            onEnd: _commitElementChange,
          ),
          HoldButton(
            icon: Icons.add,
            tooltip: 'Bigger',
            onStep: () => _resizeHeld(1.03),
            onEnd: _commitElementChange,
          ),
        ],
      ),
    );
  }

  IconData _elementTypeIcon(DesignElementType type) {
    switch (type) {
      case DesignElementType.text:
        return Icons.text_fields;
      case DesignElementType.sticker:
        return Icons.emoji_emotions_outlined;
      case DesignElementType.shape:
        return Icons.category_outlined;
      case DesignElementType.image:
        return Icons.image_outlined;
    }
  }

  String _elementTypeName(DesignElementType type) {
    switch (type) {
      case DesignElementType.text:
        return 'Text';
      case DesignElementType.sticker:
        return 'Sticker';
      case DesignElementType.shape:
        return 'Shape';
      case DesignElementType.image:
        return 'Image';
    }
  }

  // ── Shapes pane ─────────────────────────────────────────────────────────────

  Widget _buildShapesPane() {
    const shapes = DesignStudioConstants.availableShapes;
    const labels = {
      'rect': 'Square',
      'circle': 'Circle',
      'triangle': 'Triangle',
      'line': 'Line',
    };
    const icons = {
      'rect': Icons.crop_square,
      'circle': Icons.circle_outlined,
      'triangle': Icons.change_history,
      'line': Icons.horizontal_rule,
    };
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = AppColors.dsBorder(isDark);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Garment construction (moved here from the Colours panel) ────────
          Text(
            'Garment',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GarmentOptions(
            design: _design,
            onDesignUpdate: _updateDesign,
            garmentType: _selectedGarmentType,
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: hair),
          const SizedBox(height: 16),

          // ── Add shape elements ─────────────────────────────────────────────
          Text(
            'Add Shape',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: shapes.map((s) {
              return GestureDetector(
                onTap: () => _addShapeElement(s),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[s], size: 24, color: cs.onSurface),
                      const SizedBox(height: 4),
                      Text(
                        labels[s] ?? s,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Generating overlay ──────────────────────────────────────────────────────

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

  // ── Garment type selector ───────────────────────────────────────────────────

  Widget _buildGarmentTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<int>(
      valueListenable: GarmentRegistry.revision,
      builder: (context, _, _) => SizedBox(
        height: 48.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: _garmentTypes.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == _garmentTypes.length) {
              return ActionChip(
                key: const ValueKey('size-chip-open'),
                onPressed: _openSizes,
                avatar: const Icon(Icons.straighten, size: 16),
                label: Text(
                  _design.size == null
                      ? 'Size'
                      : 'Size ${_design.size}${_design.fit == null ? '' : ', ${_design.fit}'}',
                ),
              );
            }
            final type = _garmentTypes[index];
            final isSelected = _selectedGarmentType == type['id'];
            return GestureDetector(
              onTap: () => _selectGarment(type['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.dsAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.dsAccent
                        : AppColors.dsBorder(isDark),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type['label']!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.dsAccentInk
                            : AppColors.dsTextPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Private helper widget for element action bar buttons ─────────────────────

class _ElementActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final bool active;
  final VoidCallback? onTap;

  const _ElementActionBtn({
    required this.icon,
    required this.tooltip,
    this.enabled = true,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = !enabled
        ? cs.onSurface.withValues(alpha: 0.25)
        : active
        ? AppColors.marigold
        : cs.onSurface;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.all(2),
          decoration: active
              ? BoxDecoration(
                  color: AppColors.marigold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
