# Multi-style T-shirt garments and per-part layers: architecture proposal

Scope: read-only investigation of `designwear` (Flutter) and `designwear-backend/src`. Citations are `file:line` against the current working tree (which has uncommitted edits, so Dart line numbers may drift). Paths: `D/` = `/home/kasinadhsarma/designwear-platform/designwear/lib`, `B/` = `/home/kasinadhsarma/designwear-platform/designwear-backend/src`. Nothing was run; findings are from reading source. The prior coverage audit (`reports/Tshirt studio coverage audit.md`) was not redone.

## 1. What blocks multiple styles and per-part layers today (file:line)

### Takeaway
The backend already models "style" and "placements" as data, but the Flutter app ignores both: styles are three hard-coded strings on `CustomDesign`, every garment is one 4-photo `Garment`, and colour/print geometry is hard-coded in painters. The two sides (backend mock-up renderer vs. Flutter canvas) use different style vocabularies and different geometry, so a new style needs code edits in at least five places.

### Cited Findings
**Flutter, garment model**
- `Garment` has only four fixed image slots (`frontAsset/backAsset/leftAsset/rightAsset` plus URL twins) and one boolean `supportsCollarPocketOverlay`; no style, no colour zones, no print areas, no mask layers. `D/screens/studio/editor/canvas/garment_registry.dart:9-35`.
- `Garment.fromJson` reads only `id,label,*ImageUrl,supportsCollarPocket`; it drops the `style`, `placements`, `colors`, `sizes`, `basePrice` that the backend already sends. `garment_registry.dart:75-83` vs backend `B/garments.js:113-136`.
- `GarmentRegistry._defaults` contains one real garment (`tshirt`); hoodie/polo/cap/totebag are empty shells with no assets. `garment_registry.dart:90-104`. Only `T-Shirt` is offered in the picker. `D/screens/studio/editor/design_studio_screen.dart:81-83`.
- `updateFromBackend` exists but nothing calls it: `GarmentService.loadGarments()` is an empty body (`D/services/studio/garment_service.dart:6-9`), and grep finds no other caller. So `GET /v1/garments` (`B/routes/catalog.js:66`) is never consumed by the studio.
- `updateFromBackend` rebuilds each `Garment` field by field, so any new field would be silently dropped at the merge. `garment_registry.dart:111-136`.
- Aliases map slugs to ids (`shirt`, `tee`, ...) but only to the 5 default ids; there is no style dimension. `garment_registry.dart:141-153`.

**Flutter, design model**
- Garment construction is flat string fields: `collarStyle` ('crew'|'vneck'|'polo'), `pocketStyle`, `trimColor`, `collarColor`, `pocketColor`, `cuffColor`, `sleeveCuff`, `fabricFinish`, and a single `baseColor`. `D/models/custom_design.dart:183-191`. Each new part costs a field in the constructor, `copyWith`, `toJson` and `fromJson` (`custom_design.dart:195-223, 225-285, 289-320, 322-360`).
- There is no style id on the design. `productType` is a display string ('T-Shirt') and `collarStyle` is the only neckline selector (`custom_design.dart:178, 183`). The backend's 9 styles (`crew, vneck, scoop, henley, polo, raglan, longsleeve, tank, oversized`, `B/garments.js:68`, `B/imaging/mockup.js:13`) cannot be expressed in a saved Flutter design. Raglan, long sleeve, tank, henley, oversized, scoop have no representation.
- Parts that cannot be coloured: body only via `baseColor`; sleeves, hem, placket, buttons, hood have no field. Note the audit says buttons are drawn but not colourable (see prior report).
- `fromJson` is tolerant: every field has a default (`custom_design.dart:324-358`), unknown keys are ignored, so adding fields is JSON-safe for old saves. The backend stores `designJson` as an opaque object and only checks `elements` is an array of at most 60 and the size is at most 400 KB. `B/validate.js:113-122`. So extra keys round-trip with no backend change.
- `DesignSide` is a Dart enum of six values (front, back, left, right, leftPocket, rightPocket) serialised by name, with unknown names falling back to `front`. `custom_design.dart:19-49`. The backend knows only `front/back/sleeve_left/sleeve_right/neck_label`, and `neck_label` maps to `null` (no app side). `B/garments.js:17`. Pockets are app-only; neck label is backend-only.
- Elements carry only `side`; there is no per-part target, no mask/clip reference. `custom_design.dart:75-76`.

**Flutter, canvas and painters**
- The canvas recolours the garment photo with a single `ColorFilter.mode(baseColor, BlendMode.modulate)` over the whole image, so per-part colour is impossible without separate masks. `D/screens/studio/editor/canvas/design_canvas.dart:138-142, 181-185`.
- Collar/pocket/cuff are procedural overlays drawn only for `side == front && supportsCollarPocketOverlay`; coordinates are constants calibrated to one photo (e.g. `_rightPocketCX = 224`, cuff endpoints). `design_canvas.dart:228-248`; `D/.../design_canvas_painters.dart:84-145` (constants around 120-125). Collar is a literal `if (collarStyle == 'crew') return; vneck ...; polo ...`. `design_canvas_painters.dart:143-168`.
- Views are hard-coded: sleeve branch, pocket branch, front/back branch, and a hard-coded button list. `design_canvas.dart:107-226, 370-381`. The right sleeve is the left photo mirrored. `design_canvas.dart:127-137`.
- Print-size readout is a hard-coded string per category ('8 x 8', '8 x 10', '30 x 40 cm'). `design_canvas.dart:414-418`. Element coordinates use a fixed canvas (300 wide) with constant offsets 150/120. `D/.../support/design_studio_constants.dart:85-91`. There is no px-to-cm or dpi mapping on the client, and the print boundary is not per style.
- Legacy AI graphic is positioned at fixed `left:86, top:78, 160x160`. `design_canvas.dart:250-267`.

**Flutter, panels**
- `GarmentOptions` offers only Crew/V-Neck/Polo, Pocket, Cuffs, Finish, hard-coded. `D/screens/studio/editor/panels/garment_options.dart:27-80`.
- `ColorPanel` has a hard-coded trim-area chip set `'all'|'collar'|'pocket'|'cuff'` and a switch in `_trimValue/_setTrim`. `D/screens/studio/editor/panels/color_panel.dart:27-29, 544-565`. Adding hem/placket/buttons/hood means editing this switch, the model, the painter and the canvas.

**Backend**
- Positive: `B/garments.js` already has `STYLES` (line 68), `placements[]` with width/height/dpi/technique/bleed/safeInset/provisional (lines 19-25, 32-64), per-garment `colors` (104-108) and `sizes` (85-103), `basePrice`, image URLs, and `style` (130). `normaliseGarment` runs on SethuCMS rows (113-136) and `/v1/garments` serves them (`B/routes/catalog.js:66`).
- Limits: only 4 image URLs per garment (`garments.js:125-128`), `PLACEMENT_KEYS` is a closed list of 5 keys (`garments.js:17-18`, filter at 46), so pocket zones and per-part colour zones cannot be expressed. `supportsCollarPocket` is a single flag (133). Style is one string on the garment; a "style" is not a variant of one garment (T-shirt crew vs V-neck are two separate garments or one with a fixed style).
- Mock-up print areas are hard-coded in pixel space of an 800x1000 vector silhouette, not read from `placements`: `PRINT_AREAS` (`B/imaging/mockup.js:95-100`), adjusted per style in `areasFor` (102-118); for photo bases `photoAreas` uses only `Object.keys(rel)[0]` and fixed magic numbers (95,150,610,755). `mockup.js:312-324`. So the CMS-defined `placements` width/height/dpi are not used to render, only for `layers.js` generation. Two parallel sources of truth.
- The server mock-up draws styles procedurally from `SPEC` (outline + neck + placket/buttons/collar/raglan), `B/imaging/mockup.js:14-32`. This is a good existing precedent for data-driven style specs, but it is JS-only and has no per-part colour (single `color` triple, `mockup.js:331-345`).
- Pricing: server price keyed by `productType` string (`B/pricing.js:19-23`; `garments.priceOf`, `B/garments.js:173`). No style, no per-colour/per-part/per-extra price. A second, divergent price table exists: `GARMENT_PRICES` (`B/validate.js:13`) used by `ai.js` (`B/ai.js:4, 11`), versus `DEFAULT_GARMENTS.basePrice` (`garments.js:5-8`) and CMS. Three sources.
- Designs: `designs.js` resolves `body.garment` via `garments.resolve` (id, productType or label) and stores the product type string, not the garment id or style (`B/routes/designs.js:57-59, 81`). `layers.js` stores `garmentId`, `garment` label and `style` on the job (`B/layers.js:162`), so jobs captured style but designs do not.
- Print sheet: `printSheet` renders only front and back previews (`B/print.js:50-52, 66`), plus a list of text/fonts/colours from `designJson.elements`, plus `baseColor` as a single colour (`print.js:48-49, 62`). No sleeves, pockets, trim colours, style, or per-view print area. The contact sheet in `imaging/sheet.js:16` maps four views to placements.
- AI prompt: the design JSON contract lists only `baseColor`, `elements` (type text|sticker|shape) and `productType` from `{{GARMENTS}}`; no style, collar, trim colours, side or print-area. `B/design_prompt.txt:12-31, 78`. Positioning guide is "centre-chest of the shirt", x in -130..130, y -100..200 (lines 21-22, 35-39) and is style-agnostic. `parseDesignEdit` only validates `elements`, `size`, `fit` and `productType` (`B/ai.js:78-101`). Per the audit, the assistant's returned design resets unlisted options (see prior report); `CustomDesign.fromJson(edit)` is applied wholesale (`D/services/ai/ai_agent_service.dart:118-122`).
- Order sync: `order_sync.js` has no mention of garment, style or design geometry (grep found none), so it carries whatever the order line holds.

### Inferences
- The cheapest unification point is the backend `normaliseGarment` shape, which is already half of the target schema. The Flutter side should consume `/v1/garments` rather than invent its own.
- Because `designJson` is opaque and `fromJson` is default-tolerant, additive fields cost no migration of stored data.
- `mockup.js` print areas, the Flutter painter constants, `PRINT_AREAS`, and `garments.js placements` are four unlinked geometries; unifying them is the real work.

### Gaps
- Not verified: how SethuCMS rows for `garments` are actually populated in production (no CMS schema in repo read); whether the 4 photos are available for styles other than crew.
- Did not inspect `order_sync.js` beyond a grep for garment/style (no hits) or the Flutter order/checkout path.

## 2. Proposed schema

### Takeaway
Introduce one versioned `GarmentStyle` definition (JSON, served by `/v1/garments`, bundled fallback) with `views`, `zones` (colour), `printAreas`, and `layers` (assets). Keep legacy `CustomDesign` string fields as a read/write facade over a new `partColors` map and a `styleId`, so old saves load unchanged.

### Cited Findings (design anchors)
- Backend placements already carry px bounds at 300 dpi, technique, bleed, safeInset (`B/garments.js:19-25`); we extend rather than replace.
- Backend `colors` list per garment exists (`garments.js:104-108`), so allowed colours per zone can reuse that format.
- `DesignSide` names are stored in saved JSON (`custom_design.dart:35, 41-48`), so side ids must stay stable: `front, back, left, right, leftPocket, rightPocket`; new views add new names, and unknown names currently degrade to `front` (`custom_design.dart:47`), which is the main forward-compat hazard.

### Inferences (the schema)

**JSON (one garment product, many styles)** served by `GET /v1/garments` (add `schemaVersion: 2`; v1 rows keep working through the existing normaliser):
```json
{
  "id": "tshirt", "label": "T-Shirt", "productType": "T-Shirt", "basePrice": 499,
  "schemaVersion": 2,
  "styles": [{
    "id": "crew", "label": "Crew neck", "priceDelta": 0,
    "legacyCollar": "crew", "mockupStyle": "crew",
    "views": [{
      "id": "front", "side": "front", "label": "Front",
      "canvas": {"w": 300, "h": 375},
      "layers": [
        {"role": "shade", "url": "…/crew_front_shade.png", "asset": "assets/garments/tshirt/crew/front_shade.png"},
        {"role": "mask", "zone": "body",   "url": "…/crew_front_body.png"},
        {"role": "mask", "zone": "collar", "url": "…/crew_front_collar.png"},
        {"role": "mask", "zone": "cuff",   "url": "…/crew_front_cuff.png"}
      ],
      "printAreas": ["front_chest"]
    }],
    "zones": [
      {"id": "body",   "label": "Body",   "default": "base", "colors": "garment"},
      {"id": "sleeve", "label": "Sleeves","default": "body"},
      {"id": "collar", "label": "Collar", "default": "body", "colors": "trim"},
      {"id": "cuff",   "label": "Cuffs",  "default": "body", "optional": true},
      {"id": "hem",    "label": "Hem",    "default": "body", "optional": true},
      {"id": "pocket", "label": "Pocket", "default": "body", "optional": true}
    ],
    "printAreas": [{
      "id": "front_chest", "view": "front", "placement": "front",
      "rect": {"x": 262, "y": 330, "w": 276, "h": 330},
      "cm": {"w": 30, "h": 40}, "dpi": 300, "px": {"w": 3600, "h": 4800},
      "technique": "dtg", "bleed": 0, "safeInset": 150, "provisional": false
    }]
  }]
}
```
Notes: `rect` is in the view's canvas px so the client can draw the print boundary and compute the cm readout (replaces the hard-coded strings at `design_canvas.dart:414-418`); `px/dpi` is the print-file size and reuses `placements` field names so `layers.js` and `normalisePlacements` keep working (`garments.js:32-64`). `mockupStyle` lets the server mock-up (`mockup.js:13`) keep its procedural fallback while photo layers are missing. A style may omit any zone/view; the UI shows only what exists (a tank has no sleeve zone and no sleeve views, matching `areasFor`, `mockup.js:114`).

**Dart (new file `D/models/garment_style.dart`, plain classes with `fromJson`/`toJson`, no code generation)**
```dart
class GarmentLayer { final String role; /* shade|mask|overlay */ final String? zone; final String? url, asset; }
class ColorZone    { final String id, label, defaultFrom; final bool optional; final String colorSet; }
class PrintArea    { final String id, view, placement; final Rect rect; final double cmW, cmH; final int dpi, pxW, pxH, bleed, safeInset; final String technique; final bool provisional; }
class GarmentView  { final String id; final DesignSide side; final String label; final Size canvas; final List<GarmentLayer> layers; final List<String> printAreaIds; }
class GarmentStyle { final String id, label, mockupStyle, legacyCollar; final double priceDelta; final List<GarmentView> views; final List<ColorZone> zones; final List<PrintArea> printAreas; }
```
`Garment` (existing, `garment_registry.dart:9`) gains `final List<GarmentStyle> styles` and a `style(id)` lookup; the old `frontAsset...` fields stay and are used to synthesise a single default `GarmentStyle` when `styles` is empty (`Garment.legacyStyle()`), so the bundled tshirt keeps working with zero asset changes. `updateFromBackend` (`garment_registry.dart:111`) is changed to copy `styles` through (otherwise they are dropped), and `GarmentService.loadGarments` is implemented to call `GET /v1/garments` (it is empty today, `garment_service.dart:6-9`).

**CustomDesign additions (all optional, defaulted)**
```json
{ "schemaVersion": 2, "garmentId": "tshirt", "styleId": "crew",
  "partColors": {"body":"0xFF111111","sleeve":"auto","collar":"0xFFC9A227","hem":"auto"} }
```
- `partColors` value `'auto'` = inherit the zone's `default` (body). Same convention as the existing `'auto'` for trim colours (`custom_design.dart:186-189`).
- Element gets one optional field: `layerGroup` is NOT needed; keep `side` and rely on view/print-area membership (see section 4). For pockets, `leftPocket/rightPocket` remain `DesignSide` values; the style's `views` decide whether they exist.

### Migration / back-compat plan
1. Reading: `fromJson` fills `styleId` from `collarStyle` when absent (`crew->crew`, `vneck->vneck`, `polo->polo`) and `garmentId` from `productType` (reuse alias logic, `garment_registry.dart:141-153`), `partColors` from legacy fields: `body=baseColor, collar=collarColor (else trimColor), pocket=pocketColor (else trimColor), cuff=cuffColor (else trimColor)`. All defaults already exist, so no stored design fails to load (`custom_design.dart:324-358`).
2. Writing: keep emitting `baseColor, collarStyle, pocketStyle, trimColor, collarColor, pocketColor, cuffColor, sleeveCuff, fabricFinish` for at least two releases (old app versions read the new designs; the server print sheet and AI also read them), and add the new keys beside them. `baseColor` stays the source of truth for `body`.
3. Accessors: make `collarColor`, `pocketColor`, `cuffColor` getters derived from `partColors` in a later step; in step 1 do nothing to them. Single writer helper `design.withPartColor(zoneId, hex)` writes both the map and the legacy mirror.
4. Server: `studioDesign` already accepts unknown keys (`validate.js:113-122`); add an optional soft check of `styleId` against the garment on save, never reject. `designs.js` should additionally store `garmentId`/`styleId` next to `garment` (`routes/designs.js:81`) with `null` for old rows.
5. Unknown styles/sides on read: fall back to the garment's default style and `DesignSide.front` behaviour but keep the raw string in `properties` so a re-save does not erase it (current `fromString` loses it, `custom_design.dart:41-48`). Add `DesignSide.unknown`-safe handling, or keep a `rawSide` string.
6. Tests: golden JSON fixtures of pre-change designs (`test/fixtures/designs/v1_*.json`) loaded and re-serialised.

### Gaps
- Colour-zone rendering approach (mask-per-zone vs. one multiply layer) needs asset production: the audit found the current photos are JPEG-baked/alpha-checkerboard problems and cutouts are new untracked PNGs (`git status` shows `assets/images/tshirt_*_cutout.png`, untracked). I did not inspect the pixels. Per-zone masks require the artist or a segmentation pass; no estimate found in the repo.
- Unknown whether SethuCMS can store nested JSON (the existing code accepts `placements` and `sizes` as JSON text, `garments.js:32-40, 85-90`, so storing `styles` as JSON text is plausible but unverified).

## 3. Flow through each subsystem

### Takeaway
One resolver (`styleFor(design)`) on each side; everything else reads zones, views and print areas from it.

### Cited Findings and Inferences (per component)
- **GarmentRegistry** (`garment_registry.dart:86-162`): add `static GarmentStyle styleOf(String garmentId, String? styleId)`; keep `byId` (line 155). Change `updateFromBackend` to carry `styles`. Fix: `Garment.withUrls` (56-73) also drops anything new, so add `styles` there.
- **DesignCanvas** (`design_canvas.dart`): replace the three-way hard-coded view branches (107-226) with a single `GarmentStack(view: style.view(side), colors: design.partColors)` widget: paint `shade` layer multiplied over a stack of `mask` layers, each tinted with its zone colour (`ColorFiltered` per mask, `BlendMode.srcIn`/modulate), then the overlay painter only for zones with no mask. The existing painters (`GarmentOverlayPainter`, `SleevePainter`, `PocketAreaPainter`) stay as the fallback when a view has no layers, which keeps today's behaviour. Print boundary and cm readout come from `PrintArea` (replaces `design_canvas.dart:414-418`), and the element coordinate origin is the area rect centre instead of fixed `elementCanvasOffset` (`design_studio_constants.dart:90-91`) (do this last, it changes saved coordinates; keep the old origin for `schemaVersion < 2`).
- **ColorPanel / GarmentOptions**: build the trim-area chips from `style.zones` instead of the literal list (`color_panel.dart:27-29, 544-565`); build the style chips (crew/V-neck/...) from `garment.styles` instead of the literal three (`garment_options.dart:27-46`). Pocket/cuff options show only if the style has that zone/view.
- **AI prompt / backend**: replace `{{GARMENTS}}` with a catalogue block listing each garment, its `styles[].id`, its zones and print-area px/cm (extend `garments.sizeGuide`-style helper, `garments.js:161-165`, and `designPrompt` replacements, `ai.js:155-160`). Add to `design_prompt.txt:12-31, 78` optional keys `styleId` and `partColors` (colours in `0xFFRRGGBB`), and a rule "keep styleId and partColors from Current Design State unless the user asks to change them" (this also addresses the reset behaviour flagged by the audit). Positioning guide (`design_prompt.txt:35-39`) should be expressed relative to the print area (fraction of area), with `parseDesignEdit` (`ai.js:78-101`) validating `styleId` against `garments.resolve(...).styles` and `partColors` keys against the style's zones, dropping bad ones as it does for `productType` (98-100). In the Flutter app, merge instead of replace: `CustomDesign.fromJson(edit)` at `ai_agent_service.dart:118` should become `current.mergeAiEdit(edit)` so unspecified styling fields persist. `routes/ai.js:95` already passes `garments`, add the catalogue there.
- **Pricing**: `priceOf(productType)` (`garments.js:173`, used at `pricing.js:22`) becomes `priceOf(productType, styleId, design)` = `basePrice + style.priceDelta + extras` (e.g. per extra print area beyond front, per non-body zone colour: only if the business wants it). Store price and style on the cart line server-side from the saved design (pricing already looks up the stored design, `pricing.js:11-24, 36-43`), never from the client. Also remove the duplicated `GARMENT_PRICES` (`validate.js:13`) as part of this, or `ai.js` and pricing will disagree.
- **Print sheet** (`print.js:47-69`): list style, each zone's colour, and every view that has elements (front/back/sleeves/pockets), using `design.partColors` and the print-area px/cm (`areas` block); today it shows only front/back and one colour (lines 49, 62, 66). The contact sheet (`imaging/sheet.js`) and `mockup.js` `renderView` should take `partColors` (a map of zone -> rgb) instead of one `color`.
- **Order sync** (`order_sync.js`): carry `garmentId`, `styleId`, `partColors` in the line snapshot so a later catalogue change does not alter an existing order; no code path currently mentions them (grep found none).

### Gaps
- Did not read `order_sync.js` fully or the supplier integration (`fulfilment.js`, `providers.js`) to see how style maps to a supplier SKU; likely needed for rollout of real styles.

## 4. Layers panel, per-side stacking, and the reorder bug

### Takeaway
Z-order is "order within the flat `elements` list, filtered by side". The reorder code mixes per-side indices with global indices, so Bring forward / Send back move the wrong element or do nothing visible when more than one side has elements. Fix by reordering by id within a side.

### Cited Findings
- `elementsForSide(side)` is `elements.where(e.side == side)`, so a side's z-order is the relative order in the global list. `custom_design.dart:366-368`. The canvas paints them in that order. `design_canvas.dart:269-296`.
- `_bringForwardSelected` and `_sendBackSelected` compute `idx` as the index within `elementsForSide(_side)` (per-side list) and then call `_reorderElements(idx, idx±1)`. `D/screens/studio/editor/screen/design_studio_screen_actions.dart:350-365`. `_reorderElements` calls `CustomDesign.reorderElements(oldIndex, newIndex)` which treats the numbers as indices in the global `elements` list. `design_studio_screen_actions.dart:166-167`; `custom_design.dart:392-397`.
- The same per-side index feeds the floating toolbar buttons. `D/screens/studio/editor/screen/design_studio_screen_layout.dart:606-609, 647-658`.
- Consequence: with elements on front and back interleaved (the AI inserts art layers first, `ai_agent_service.dart:118-122, 138-143`), a side-local index 1 may be a different element globally, so the swap exchanges the wrong pair (e.g. swaps a front element with a back element, with no visible change on the current side). Reported as "known per-side reorder bug" by the caller; I confirmed the index mismatch by reading, not by running.
- `LayersPanel` lists every element of the design regardless of side (`generateLayersData` iterates `design.elements`, `D/.../support/design_studio_utils.dart:114-142`; panel `layers_panel.dart:98-140`), does not show which side an element is on, and has no drag-reorder: `onReorderElements` is a constructor argument (`layers_panel.dart:15, 26`) but the visible code uses it nowhere (only `onTap` select, line 140ff; I did not find a `ReorderableListView`). The first two rows are fixed text rows "Tee colour" and "Print area" (lines 107-129), and the header text "INHERITED FROM ORIGINAL" is always shown (73-82).
- `generateLayersData` icon logic has only two icons (text vs emoji), regardless of type (`design_studio_utils.dart:137-139`).

### Inferences
**Fix (smallest)**: add `CustomDesign.moveElementWithinSide(String id, int delta)` that finds the element, finds the neighbour among `elementsForSide(el.side)` at +/-1, and swaps/moves by their global indices; make `_bringForwardSelected`, `_sendBackSelected` and the toolbar (layout 647-658) call it. For `LayersPanel` drag-reorder use `ReorderableListView` over the active side's list in reverse (top layer first) and translate old/new local indices to global via the same helper. Add a unit test: elements `[F1,B1,F2,B2]`, send `F2` back -> `[F2,B1,F1,B2]`, back elements unchanged.

**Panel model (per side, then per area)**: the panel shows (a) a "Garment" group: one row per colour zone of the style (with colour dot, tap to open ColorPanel on that zone) which replaces the two fixed rows (107-129), then (b) "Artwork - {view label}" with the active side's elements top-to-bottom, plus a collapsed section per other side that has elements (count badge, tap to switch side, mirrors the counts already shown in the side picker, `design_studio_screen_actions.dart:317`). Selecting an element on another side switches `_side`. Garment layers (shade/masks) are not reorderable and always sit below artwork, except an optional `overlay` role layer (e.g. collar ribs, buttons) that draws above artwork if the style says so (`"above": true`); this is needed so a print doesn't cover a button placket.

**Stacking contract**: bottom to top = shade photo + zone-tinted masks -> optional fabric finish -> artwork elements (in list order) -> `above` overlays (buttons, labels) -> UI handles. Clipping: artwork is clipped to the print area's `rect` plus bleed on print output only; in the editor it is allowed to overflow with a warning outline (safe-inset guide), since the current canvas does not clip (`design_canvas.dart:269-296`).

### Gaps
- Did not confirm whether `LayersPanel` has drag handles elsewhere in the file (lines 160-239 not fully read); search for `onReorderElements` found no use beyond the declaration in the panel file (`layers_panel.dart:15, 26`, and passing at `layout.dart:566`).

## 5. Incremental rollout, tests, risks

### Takeaway
Smallest valuable step: fix the reorder bug, then wire `/v1/garments` through to the app and let `style` (crew/V-neck/long sleeve/tank/...) appear as a selectable, priced option driven by data, still using the current procedural look. Photo layers and per-zone masks come after.

### Cited Findings (basis for the plan)
- The backend already serves styles and placements (`routes/catalog.js:66`, `garments.js:130`), and the server mock-up already draws nine styles (`mockup.js:13-32`), so steps 1-3 need little backend work.
- The Flutter side ignores that data (`garment_registry.dart:75-83`, `garment_service.dart:6-9`).
- Existing test files cover the AI and canvas areas: `test/ai_sides_test.dart`, `test/pocket_areas_test.dart`, `test/screens_test.dart`, `test/design_agent_test.dart` (listing of `test/`), so extending them keeps a small team's cost low. The working tree has uncommitted changes in these areas (git status at start), so land/commit those first.

### Inferences (plan)
**Step 0 (half a day)**: reorder bug fix + test (section 4). Independent of everything else.
**Step 1 (smallest value-delivering, ~2-3 days)**: data-driven style selection, no new art.
- Implement `GarmentService.loadGarments()` and call it at studio start; extend `Garment.fromJson` / `updateFromBackend` / `withUrls` to carry `style`, `colors`, `placements`, `basePrice`.
- Add `styleId` to `CustomDesign` (+ legacy `collarStyle` mapping both ways); replace the literal collar chips with the style list from the garment (`garment_options.dart:27-46`).
- Canvas: styles with no photo set use the existing procedural/photo path for crew and show the existing crew photo with the collar overlay for V-neck/polo (what the app does now); other styles show a "preview style" badge until art exists. Print-size readout from `placements` (`design_canvas.dart:414-418`).
- Backend: add `priceDelta` per style and return styles in `/v1/garments`; store `styleId` with the design (`routes/designs.js:81`); add style to the print sheet header (`print.js:61`).
**Step 2 (~3-4 days)**: `partColors` + zone-driven ColorPanel. Add `ColorZone` list per style (default zones: body, sleeve, collar, cuff, hem, pocket) and render colour per zone with procedural overlays first (collar/pocket/cuff already exist), extend `GarmentOverlayPainter` for hem and sleeve tint; print sheet lists zone colours; AI prompt gets `styleId/partColors` keys and merge-not-replace (`ai_agent_service.dart:118`).
**Step 3 (art-dependent)**: per-style photos and masks (shade + mask layers), `GarmentStack` widget, unify `PRINT_AREAS`/`placements`/painter constants (delete duplicated geometry `mockup.js:95-100, 312-324`). Hoodie/hood, placket, buttons zones arrive here because they need real masks.
**Step 4**: layers panel regroup (garment zones + per-side artwork), print areas drive element coordinates with `schemaVersion` gate, order snapshot of style/zones, supplier SKU mapping.

**Tests**
- Dart unit: JSON golden fixtures of v1 designs (all legacy fields) round-trip and map to `styleId/partColors`; `fromJson` of unknown side/style; `moveElementWithinSide`; `GarmentStyle.fromJson` for v1 and v2 payloads; `updateFromBackend` keeps `styles`.
- Dart widget: canvas renders each style's zones with a fake registry (no network) and the print readout matches `PrintArea` (extend `test/screens_test.dart`, `test/pocket_areas_test.dart`).
- Backend (node:test style used in the repo; verify runner): `normaliseGarment` with v1 and v2 rows, `parseDesignEdit` rejects unknown `styleId`/zone keys, `priceOf` with style delta, print sheet includes style and zone colours, and that old stored designs without `styleId` still price at base.
- Contract test: a shared JSON sample garment checked by both Dart and JS tests so the two parsers cannot drift.
- Visual: golden image per style/view for the Flutter canvas, server `renderView` snapshots per style (already procedural, cheap).

**Risks**
- Asset production (masks per style/view) is the long pole and the only real blocker for step 3; procedural drawing keeps steps 1-2 shippable without it. Audit found current cutouts have quality issues (see prior report).
- Coordinate-origin change (print-area-relative) would break saved element positions; gate behind `schemaVersion` and keep the legacy origin for old designs (`design_studio_constants.dart:85-91`).
- Dual geometry (client painters vs server mock-up vs placements) will drift; mitigate by making one JSON the source and removing constants gradually, and by the shared contract test.
- Price drift: three price tables (`garments.js:5-8`, `validate.js:13`, CMS) exist today; consolidate before adding style deltas.
- AI: more fields in the prompt raises the chance of invalid colours or styles; the existing validator pattern (`ai.js:98-100`) must cover them, and the merge-not-replace fix is required or AI edits will keep resetting styling.
- Old app versions reading new designs: keep legacy fields written for two releases. Unknown `DesignSide` strings fall back to front (`custom_design.dart:47`), so do not introduce new side names until clients are updated (use existing six for now).
- Orders in flight: snapshot style/zones into the order line (step 4) so editing the CMS does not alter a placed order.
- The working tree has many uncommitted changes in exactly these files (git status), so branch from a committed baseline to avoid conflicts.

### Gaps
- No time estimates are sourced from the repo; the day figures above are my judgement.
- Supplier/fulfilment mapping for style SKUs (`B/fulfilment.js`, `B/providers.js`) not read.
- I did not execute tests, the app, or the backend; the reorder bug diagnosis and line numbers come from static reading of the working tree.
