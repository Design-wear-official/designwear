---
description: Architecture, data model, and extension guide for the Design Studio module
---

# Design Studio — Developer Playbook

The Design Studio lets users customise a garment (colour, collar, pocket, text, stickers, templates) and export a shareable design. It runs as a full-screen experience launched from the home app bar's **Create** button.

---

## 1. Entry Points

| File | Role |
|---|---|
| `lib/screens/design_studio_screen.dart` | Root `StatefulWidget`; owns `_design` state, tool routing, mobile/desktop layout split |
| `lib/screens/home/home_app_bar.dart` | "Create" pill button that pushes `/design-studio` route |

The screen adapts between a **desktop layout** (side panel + canvas + vertical tool rail) and a **mobile layout** (canvas + collapsible 240 px drawer + horizontal tool bar).

---

## 2. Module Structure

```
lib/screens/design_studio/
├── design_studio.dart              # Barrel export
├── design_studio_constants.dart    # Color palette, tab definitions, canvas sizes
├── design_studio_utils.dart        # colorToHex / parseColorFromHex helpers
├── design_canvas.dart              # Garment canvas + overlay painters
├── color_panel.dart                # Colour + collar + pocket picker (side panel)
├── layers_panel.dart               # Layer stack management
├── placement_panel.dart            # Print area positioning
├── templates_panel.dart            # Pre-built templates
├── tools_panel.dart                # Horizontal / vertical tool switcher
└── widgets/
    ├── colors_tab.dart             # Legacy tab-based colour grid (uses tShirtColors)
    ├── text_tab.dart               # Font / text controls
    ├── stickers_tab.dart           # Emoji sticker picker
    ├── templates_tab.dart          # Template preview grid
    ├── draggable_element_widget.dart
    ├── design_element_widget.dart
    └── enhanced_text_editor.dart
```

---

## 3. Data Model — `CustomDesign`

Located at `lib/models/custom_design.dart`.

```dart
class CustomDesign {
  // Garment appearance
  final String baseColor;     // hex e.g. "0xFFFFFFFF"
  final String collarStyle;   // 'crew' | 'vneck' | 'polo'
  final String pocketStyle;   // 'none' | 'left' | 'right' | 'both'
  final String trimColor;     // 'auto' or hex — collar/pocket/cuff accent
  final String sleeveCuff;    // 'none' | 'banded' | 'rolled'
  final String fabricFinish;  // 'solid' | 'heather' | 'vintage'

  // Legacy text/sticker (pre-element system, kept for back-compat)
  final String text;
  final String sticker;

  // Layer system
  final List<DesignElement> elements;  // text, sticker, shape layers

  // Metadata
  final String name;
  final String productType;    // 'T-Shirt', 'Hoodie', etc.
  final String printLocation;  // 'centre_chest', 'left_chest', etc.
  final String? thumbnailPath;

  // Runtime only — not serialised to JSON
  final String? designImageBase64;  // AI-generated graphic
}
```

`CustomDesign` is fully serialisable. Call `.toJson()` / `CustomDesign.fromJson()` for save/restore. The `designImageBase64` field is intentionally excluded from `toJson()`.

---

## 4. Colour System

### Fabric swatches — `ColorPanel` (`color_panel.dart`)

41 preset fabric colours across 7 hue groups (Whites, Reds/Pinks, Oranges/Yellows, Greens, Blues, Purples, Browns/Earth). To add a preset, append to the `fabrics` list:

```dart
{'name': 'Slate', 'color': Color(0xFF475569)},
```

### T-shirt colour grid — `DesignStudioConstants.tShirtColors` (`design_studio_constants.dart`)

56-colour flat list used by the tab-based `ColorsTab` widget. Grouped by hue for Wrap layout.

### Custom colour picker

Tap the rainbow `+` circle at the end of the swatches. A dialog prompts for a `#RRGGBB` hex string with a live preview circle. The picked colour is stored in `_ColorPanelState._customColor` and applied via `onDesignUpdate`.

### Recently used + Quick palettes

`ColorPanel` persists the last 8 base colours to `SharedPreferences` (key `ds_recent_colors`) via `_pushRecent()` — every `_applyBase()` records the colour. Below recents, four curated `palettes` (Mono / Earth / Neon / Pastel) render as labelled swatch rows; tapping any dot applies it as the fabric colour.

### Trim / Accent colour

`design.trimColor` is `'auto'` (derive a contrasting shade from the fabric colour — legacy behaviour) or a hex string. The "Auto" pill resets to `'auto'`; the `trimSwatches` row sets an explicit accent. The canvas resolves it to a `Color?` (`null` when `'auto'`) and passes it to `GarmentOverlayPainter.trimColor`, which recolours the collar, pocket stitching and sleeve cuffs.

### Garment construction lives under the Shapes tool

`collarStyle`, `pocketStyle`, `sleeveCuff` and `fabricFinish` are **not** in the Colour panel — they moved to the **Shapes** tool (`_buildShapesPane()` → `GarmentOptions` widget at `widgets/garment_options.dart`), since "Shapes" owns garment form and "Colours" owns colour. `sleeveCuff` is `none`/`banded`/`rolled`; `fabricFinish` is `solid`/`heather`/`vintage`. All four render in `GarmentOverlayPainter` — cuffs as accent bands at the sleeve hems, finish as a torso-clipped texture (heather flecks / vintage wash). The **Trim / Accent** colour (`trimColor`) stays in the Colour panel and recolours these overlays.

---

## 5. Garment Overlays — `_GarmentOverlayPainter`

Defined at the bottom of `design_canvas.dart`. A `CustomPainter` drawn via `Positioned.fill` on top of the `ColorFiltered` garment image.

### Canvas coordinate reference

Canvas total size: **332 × 407 px** (= `canvasWidth + 32` × `canvasWidth * 1.25 + 32`).
Garment image: 300 px wide, `BoxFit.contain`, centred → 16 px horizontal padding.

| Landmark | X | Y |
|---|---|---|
| Canvas centre | 166 | — |
| Collar top | 166 ± 46 | 80 |
| Collar deepest (V) | 166 | 126 |
| Left pocket centre | 108 | 168 + 20 |
| Right pocket centre | 224 | 168 + 20 |

### Collar styles

| Value | What is drawn |
|---|---|
| `crew` | Nothing — crew neck is already in the asset |
| `vneck` | Filled V triangle + border line from collar opening down to 126 px |
| `polo` | Rounded-rect collar block + button placket line + 2 button dots |

### Pocket styles

| Value | What is drawn |
|---|---|
| `none` | Nothing |
| `left` | Shaded rounded-rect patch at left chest with inner stitch border |
| `right` | Same at right chest |
| `both` | Both pockets |

Overlay colours auto-adapt: **lighten** for dark shirts (luminance < 0.25), **darken** for light shirts — so the pocket/collar is always visible at any base colour.

---

## 6. Tools Panel

Five tools, each renders a pane via `_buildActivePaneContent()`:

| Tool ID | Pane |
|---|---|
| `layers` | `LayersPanel` — reorder / delete layers |
| `color` | `ColorPanel` — fabric swatches, recents, palettes, trim/accent |
| `text` | `TextTab` — font picker + text input |
| `emoji` | `StickersTab` — emoji grid |
| `shapes` | `_buildShapesPane()` — garment construction (`GarmentOptions`) + add shape primitives |
| `place` | `PlacementPanel` — print location selector |

---

## 7. Garment Types

The canvas supports multiple garment types via `_garmentAssets` in `design_canvas.dart`. Currently only `tshirt_white.png` is available. To add a new garment:

1. Add a white/neutral PNG to `assets/images/`
2. Add an entry to `_garmentAssets` and `_garmentLabels`
3. The `ColorFilter.modulate` tint will apply the user's chosen colour automatically

---

## 8. Adding a New Collar or Pocket Style

1. Add a new chip option to the `options` list in `color_panel.dart` under `_buildStyleChips()`.
2. Add a new drawing branch in `_GarmentOverlayPainter._paintCollar()` or `_paintPockets()`.
3. The `collarStyle` / `pocketStyle` string flows through `CustomDesign` automatically.

---

## 9. Save / Export Flow

`_saveDesign()` in `design_studio_screen.dart`:
- Renders the canvas to a PNG via `canvasKey` + `RenderRepaintBoundary`
- Stores `thumbnailPath` in `CustomDesign`
- Navigates to `SaveDesignDialog` for name + publish

---

## 10. Constants Reference

```dart
DesignStudioConstants.canvasWidth          // 300.0
DesignStudioConstants.defaultFontSize      // 24.0
DesignStudioConstants.minFontSize          // 10.0
DesignStudioConstants.maxFontSize          // 80.0
DesignStudioConstants.defaultStickerSize   // 60.0
DesignStudioConstants.autoSaveIntervalSeconds // 10
```
