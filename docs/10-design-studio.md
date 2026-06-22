# 10 · Design Studio

The Design Studio is the interactive garment designer—the product's signature
feature. This page documents the module's architecture, state, data model,
constants, and how AI plugs in. For the user-facing feature changelog see
[DESIGN_STUDIO_FEATURES.md](DESIGN_STUDIO_FEATURES.md).

---

## Entry point

[`DesignStudioScreen`](../lib/screens/design_studio_screen.dart) is the host
`StatefulWidget`:

```dart
DesignStudioScreen({ Product? remixSource });
```

- **Fresh design:** `const DesignStudioScreen()`.
- **Remix mode:** pass `remixSource` (a `Product`). A provenance chip shows the
  parent creator, and **Publish** creates a new product linked to it via
  lineage (`ApiService.publishRemix`).

It is reached imperatively (e.g. the home "Remix" banner, product detail) with
`RouteSettings(name: '/design-studio')`. See
[Screens & Navigation](08-screens-and-navigation.md).

---

## Module layout

```
lib/screens/design_studio_screen.dart   # host screen, orchestrates state
lib/screens/design_studio/              # module (barrel: design_studio.dart)
├── design_canvas.dart          # the garment + layered elements render surface
├── color_panel.dart            # garment color picker
├── layers_panel.dart           # element list: select, reorder, duplicate, delete
├── placement_panel.dart        # print location / collar / pocket controls
├── templates_panel.dart        # slide-out template browser
├── tools_panel.dart            # tabbed tools (Colors/Text/Stickers/Templates)
├── design_studio_constants.dart
├── design_studio_utils.dart
└── widgets/                    # (barrel: widgets.dart)
    ├── colors_tab.dart  text_tab.dart  stickers_tab.dart  templates_tab.dart
    ├── text_controls_widget.dart  enhanced_text_editor.dart
    ├── design_element_widget.dart  draggable_element_widget.dart
    └── save_design_dialog.dart
```

---

## State held by the host screen

From `_DesignStudioScreenState`:

| State | Purpose |
|-------|---------|
| `CustomDesign _design` | The current design (see [Data Models](06-data-models.md#customdesign-designelement)) |
| `DesignHistoryService _historyService` | Undo/redo stack |
| `DesignTemplateService _templateService` | Built-in + custom templates |
| `DesignStorageService _storageService` | Save / load / auto-save |
| `AIAgentService _aiService` | DesignBot + AI image generation |
| `GlobalKey _canvasKey` | Captures the canvas for thumbnails / try-on |
| `_selectedElementId` | Currently selected layer |
| `_activeTool` (`layers`/…) | Active sidebar tool |
| `_selectedGarmentType` | `tshirt`/`hoodie`/`polo`/`cap`/`totebag` |
| `_showTemplates`, `_isPanelCollapsedOnMobile` | Panel visibility |
| `_isAutoGenerating`, `_isPublishing` | Async flags |
| `_lastAutoSave` | Auto-save throttle |
| `_baseProduct` | The synthetic "Custom T-Shirt" product backing cart/checkout |

Garment types offered: **T-Shirt, Hoodie, Polo, Cap, Tote Bag**.

---

## Interaction model

1. **Pick a garment + color** (`color_panel` / `colors_tab`).
2. **Add elements** — text (`text_tab` → `enhanced_text_editor`), stickers
   (`stickers_tab`), or apply a **template** (`templates_tab` / `templates_panel`).
3. **Manipulate on canvas** — drag/select via `draggable_element_widget`;
   each renders through `design_element_widget`.
4. **Manage layers** — reorder/duplicate/delete in `layers_panel`.
5. **Adjust placement** — print location, collar, pocket (`placement_panel`).
6. **Use AI** — DesignBot edits the design conversationally (see below).
7. **Save / auto-save** — `save_design_dialog` + 10s auto-save.
8. **Try-on / Publish / Add to cart**.

Every meaningful mutation is pushed to `DesignHistoryService` for undo/redo
(capped at `AppConstants.maxUndoHistory = 30`).

---

## Constants — `DesignStudioConstants`

[`design_studio_constants.dart`](../lib/screens/design_studio/design_studio_constants.dart):

| Constant | Value | Notes |
|----------|-------|-------|
| `tShirtColors` | ~55 colors | Full palette grouped by hue (whites→browns) |
| `availableStickers` | 23 emojis | ⭐🔥❤️🎸👑😎💀🍕… |
| `toolTabs` | 4 tabs | Colors, Text, Stickers, Templates |
| `canvasWidth` | `300` | Canvas render width |
| `text/sticker/elementCanvasOffset*` | | Default drop offsets |
| `autoSaveIntervalSeconds` | `10` | Auto-save cadence |
| `minFontSize` / `maxFontSize` / `defaultFontSize` | `10` / `80` / `24` | |
| `defaultStickerSize` | `60` | |
| `templatesPanelWidth` / `layersPanelWidth` | `300` / `280` | Slide-out widths |

> Some sizing also references the app-wide
> [`AppConstants`](04-configuration.md#appconstants-non-env-constants)
> (`maxDesignElements 50`, `designCanvasWidth/Height 400×500`, `supportedFonts`).

---

## The AI design contract

DesignBot is driven by [`assets/system_prompt.txt`](../assets/system_prompt.txt),
loaded by `AIAgentService.sendMessage` with `{{CURRENT_STATE}}` replaced by the
current design JSON. Key rules the model must follow:

- It controls **`baseColor`** and the **`elements[]`** array (text/sticker/shape).
- Element schema: `id`, `type`, `content`, `x` (−130..130), `y` (−100..200),
  `size` (10..80), `color` (`0xFFRRGGBB`), and `properties`
  (`fontFamily`, `bold`, `italic`, `shadow`).
- **Positioning:** `x=0,y=0` = center chest; negative `y` = toward collar.
- Colors **must** be `0xFFRRGGBB` (never `#RRGGBB`).
- The model returns conversational text **before** a single fenced ```json```
  block containing `{"design": { ... }}`.
- It must list **all** elements every time (omitted elements are removed).
- It **cannot** generate raster graphics—only colors, text, and emoji stickers.

`AIAgentService` parses the fenced block into a `CustomDesign`, and—when the
parallel `/ai/generate-design` call succeeds—attaches the generated PNG via
`designImageBase64`. Full flow: [AI & Virtual Try-On](11-ai-and-virtual-tryon.md).

### Available fonts (AI + editor)
`Outfit`, `Roboto`, `Lato`, `Playfair Display`, `Dancing Script`, `Bebas Neue`,
`Pacifico` (the prompt's list; the editor also exposes
`DesignTemplateService.getAvailableFonts()`).

---

## Persistence & auto-save

- **Manual save:** `save_design_dialog` → `DesignStorageService.saveDesign`.
- **Auto-save:** every ~10s the current design is written; recover via
  `getAutoSavedDesign()` / clear via `clearAutoSave()`.
- **Library:** [`SavedDesignsScreen`](../lib/screens/saved_designs_screen.dart)
  lists saved designs (`getSavedDesigns`, `deleteDesign`).
- **Thumbnails:** captured from `_canvasKey` (RepaintBoundary) and stored at
  `thumbnailPath`.

---

## Templates & starters

`DesignTemplateService` supplies:
- `getAllTemplates()` / `getTemplatesByCategory(cat)` / `getTemplateById(id)`
- `getCustomTemplates()` (user-saved)
- `getStarterDesigns()` (quick-start designs)
- `getAvailableCategories()` and `getAvailableFonts()`

Templates can also come from Sanity via `ApiService.fetchDesignTemplates()`
(always Sanity-sourced). See [Sanity CMS](13-sanity-cms.md).

---

## Publish (remix)

When the studio was opened with a `remixSource` (or the user publishes their
creation), `ApiService.publishRemix(...)` posts to `/publish-remix`:

```
creatorHandle, creatorName, garmentType, title?, garmentBaseColor?, artText?,
remixedFromId?, remixedFromHandle?, remixedFromVersion?, lineage[], tags[]
```

The backend writes a Sanity product, syncs it to Firebase, and returns the new
product id. Lineage is rendered in the UI via `LineageNode`. See
[Backend & API Reference](12-backend-and-api.md#publish-remix).
