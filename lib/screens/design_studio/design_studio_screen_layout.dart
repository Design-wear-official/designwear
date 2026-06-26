part of '../design_studio_screen.dart';

extension _LayoutMethods on _DesignStudioScreenState {
  // ── AppBar ──────────────────────────────────────────────────────────────────

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
                Text('DESIGN',
                    style: GoogleFonts.archivo(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: cs.onSurface,
                        letterSpacing: 1.2)),
                Text('WEAR',
                    style: GoogleFonts.archivo(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.marigold,
                        letterSpacing: 1.2)),
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
        if (!ResponsiveUtils.isMobile(context))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2232)
                      : const Color(0xFFEBEBF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fork_right,
                        size: 14,
                        color: isDark ? AppColors.stone : Colors.black54),
                    const SizedBox(width: 4),
                    Text('Remixing ',
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: isDark ? AppColors.stone : Colors.black54)),
                    Text(
                      widget.remixSource != null
                          ? '${widget.remixSource!.creatorHandle ?? widget.remixSource!.title}\'s ${widget.remixSource!.productType ?? 'Design'}'
                          : 'New Design',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: _historyService.canUndo ? _undo : null,
          icon: Icon(Icons.undo,
              color: _historyService.canUndo
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.3),
              size: 20),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _historyService.canRedo ? _redo : null,
          icon: Icon(Icons.redo,
              color: _historyService.canRedo
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.3),
              size: 20),
          tooltip: 'Redo',
        ),
        // Secondary actions: inline on desktop/tablet, overflow menu on mobile
        // so the bar doesn't overflow on narrow phones.
        if (!ResponsiveUtils.isMobile(context)) ...[
          IconButton(
            onPressed: () => SaveDesignDialog.show(context, _design, _storageService,
                captureCallback: _captureCanvasPng),
            icon: const Icon(Icons.save_outlined, size: 20),
            tooltip: 'Save Design',
          ),
          IconButton(
            onPressed: _open3DPreview,
            icon: const Icon(Icons.view_in_ar_outlined, size: 20),
            tooltip: '3D Preview',
          ),
          IconButton(
            onPressed: _navigateToTryOn,
            icon: const Icon(Icons.face_retouching_natural_outlined, size: 20),
            tooltip: 'Virtual Try-On',
          ),
          IconButton(
            onPressed: () => setState(() => _showTemplates = !_showTemplates),
            icon: Icon(Icons.style_outlined,
                size: 20,
                color: _showTemplates ? AppColors.marigold : cs.onSurface),
            tooltip: 'Templates',
          ),
        ] else
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'save':
                  SaveDesignDialog.show(context, _design, _storageService,
                      captureCallback: _captureCanvasPng);
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
                    title: Text('Save Design')),
              ),
              PopupMenuItem(
                value: '3d',
                child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.view_in_ar_outlined, size: 20),
                    title: Text('3D Preview')),
              ),
              PopupMenuItem(
                value: 'tryon',
                child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.face_retouching_natural_outlined, size: 20),
                    title: Text('Virtual Try-On')),
              ),
              PopupMenuItem(
                value: 'templates',
                child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.style_outlined, size: 20),
                    title: Text('Templates')),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 6),
          child: Center(
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishAndSync,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white : const Color(0xFF15182B),
                foregroundColor:
                    isDark ? const Color(0xFF15182B) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? const Color(0xFF15182B)
                              : Colors.white))
                  : Text('PUBLISH',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          letterSpacing: 0.8)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop / Tablet 3-pane ─────────────────────────────────────────────────

  Widget _buildDesktopTabletBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

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
                            side: _side,
                            provenanceLabel: _provenanceLabel,
                            onElementSelected: (id) =>
                                setState(() => _selectedElementId = id),
                            onElementPreview: _previewElement,
                            onElementCommit: _commitElementChange,
                            onElementDelete: _deleteElement,
                            onElementEdit: _editElement,
                            onSideChanged: (s) => setState(() => _side = s),
                            snapGuides: _snapGuides,
                          ),
                          // Off-screen canvas for capturing the opposite side during publish
                          Offstage(
                            child: DesignCanvas(
                              canvasKey: _backCanvasKey,
                              design: _design,
                              selectedElementId: null,
                              garmentType: _selectedGarmentType,
                              side: _side == DesignSide.front
                                  ? DesignSide.back
                                  : DesignSide.front,
                              onElementSelected: (_) {},
                              onElementPreview: (_) {},
                              onElementCommit: () {},
                              onElementDelete: (_) {},
                              onSideChanged: (_) {},
                            ),
                          ),
                          if (_isAutoGenerating) _buildGeneratingOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildElementActionBar(),
              ],
            ),
          ),
        ),
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

  // ── Mobile layout ───────────────────────────────────────────────────────────

  Widget _buildMobileBody() {
    return Column(
      children: [
        _buildGarmentTypeSelector(),
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
                      side: _side,
                      provenanceLabel: _provenanceLabel,
                      onElementSelected: (id) =>
                          setState(() => _selectedElementId = id),
                      onElementPreview: _previewElement,
                      onElementCommit: _commitElementChange,
                      onElementDelete: _deleteElement,
                      onElementEdit: _editElement,
                      onSideChanged: (s) => setState(() => _side = s),
                      snapGuides: _snapGuides,
                    ),
                    // Off-screen canvas for capturing the opposite side during publish
                    Offstage(
                      child: DesignCanvas(
                        canvasKey: _backCanvasKey,
                        design: _design,
                        selectedElementId: null,
                        garmentType: _selectedGarmentType,
                        side: _side == DesignSide.front
                            ? DesignSide.back
                            : DesignSide.front,
                        onElementSelected: (_) {},
                        onElementPreview: (_) {},
                        onElementCommit: () {},
                        onElementDelete: (_) {},
                        onSideChanged: (_) {},
                      ),
                    ),
                    if (_isAutoGenerating) _buildGeneratingOverlay(),
                  ],
                ),
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
        return ColorPanel(design: _design, onDesignUpdate: _updateDesign);
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
        return StickersTab(onAddStickerElement: _addStickerElement);
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

    final selected = _design.elements
        .cast<DesignElement?>()
        .firstWhere((e) => e?.id == _selectedElementId, orElse: () => null);
    if (selected == null) return const SizedBox.shrink();

    final sideElements = _design.elementsForSide(_side);
    final idx = sideElements.indexWhere((e) => e.id == _selectedElementId);
    final canSendBack = idx > 0;
    final canBringForward = idx >= 0 && idx < sideElements.length - 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final cs = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: hair)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_elementTypeIcon(selected.type),
                      size: 15, color: cs.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    _elementTypeName(selected.type),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: cs.onSurface),
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
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 5),
                          Text('Remove',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildElementAdjustRow(selected, cs),
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
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
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
            child: Text('${(selected.opacity * 100).round()}%',
                style: GoogleFonts.spaceMono(fontSize: 11, color: muted)),
          ),
          const SizedBox(width: 4),
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

  IconData _elementTypeIcon(DesignElementType type) {
    switch (type) {
      case DesignElementType.text:    return Icons.text_fields;
      case DesignElementType.sticker: return Icons.emoji_emotions_outlined;
      case DesignElementType.shape:   return Icons.category_outlined;
      case DesignElementType.image:   return Icons.image_outlined;
      default:                        return Icons.layers_outlined;
    }
  }

  String _elementTypeName(DesignElementType type) {
    switch (type) {
      case DesignElementType.text:    return 'Text';
      case DesignElementType.sticker: return 'Sticker';
      case DesignElementType.shape:   return 'Shape';
      case DesignElementType.image:   return 'Image';
      default:                        return 'Element';
    }
  }

  // ── Shapes pane ─────────────────────────────────────────────────────────────

  Widget _buildShapesPane() {
    const shapes = DesignStudioConstants.availableShapes;
    const labels = {
      'rect': 'Square', 'circle': 'Circle',
      'triangle': 'Triangle', 'line': 'Line',
    };
    const icons = {
      'rect': Icons.crop_square, 'circle': Icons.circle_outlined,
      'triangle': Icons.change_history, 'line': Icons.horizontal_rule,
    };
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Garment construction (moved here from the Colours panel) ────────
          Text('Garment',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GarmentOptions(design: _design, onDesignUpdate: _updateDesign),

          const SizedBox(height: 20),
          Container(height: 1, color: hair),
          const SizedBox(height: 16),

          // ── Add shape elements ─────────────────────────────────────────────
          Text('Add Shape',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700)),
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
                        color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[s], size: 24, color: cs.onSurface),
                      const SizedBox(height: 4),
                      Text(labels[s] ?? s,
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: cs.onSurface)),
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
              color: Colors.white, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Generating your design…',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Garment type selector ───────────────────────────────────────────────────

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
            onTap: () =>
                setState(() => _selectedGarmentType = type['id']!),
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
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.marigold.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type['label']!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
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
