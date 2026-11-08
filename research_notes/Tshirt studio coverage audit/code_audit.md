# T-shirt studio coverage audit (code)

Scope: Flutter app `/home/kasinadhsarma/designwear-platform/designwear` (paths below are relative to it, `lib/...`), plus the sibling backend `../designwear-backend` (paths prefixed `BE:`). Read-only audit; nothing was run (no `flutter test`/`analyze`). Everything below is from reading source; items marked (computed) are derived arithmetically from code constants and the asset images, not from a rendered screenshot. "Source" for each finding is file:line instead of a URL. Working tree note: the pocket/sleeve/per-area-colour work is UNCOMMITTED (git status: modified custom_design.dart, design_canvas.dart, design_canvas_painters.dart, garment_registry.dart, color_panel.dart, ai_agent_service.dart; untracked 4 `*_cutout.png` assets and test/pocket_areas_test.dart).

---

## Q1. Which areas are colourable, and how? Is there a polo button colour?

### Takeaway
Exactly four colour channels exist: body/"tee" colour (`baseColor`), plus collar, pocket and cuff colours that each default to a shared `trimColor` accent. There is NO sleeve colour, NO button colour, NO hem/neck-label/placket colour. The polo buttons are painted with a colour derived from the collar colour, with no user control.

### Cited Findings
- Model fields: `baseColor` (lib/models/custom_design.dart:165), `trimColor` (:185, 'auto' or hex), per-area `collarColor`/`pocketColor`/`cuffColor` (:187-189, 'auto' or hex). All serialised in toJson (:291, :311-314) and fromJson (:324, :352-355). No button/sleeve/hem/label colour field exists in the model.
- Body colour UI: 40-swatch `fabrics` list (lib/screens/studio/editor/panels/color_panel.dart:35-83), custom hex dialog (:196-327, `+` button :430-456), recents (:460-484), quick palettes (:486-492, :98-139). Applied via `_applyBase` (:156-162). Header label "TEE COLOUR" (:385).
- Trim UI: 8 fixed swatches `trimSwatches` (color_panel.dart:86-95) + "Auto" pill (:616-660). Area chips All/Collar/Pockets/Cuffs (:567-605; state `_trimArea` :29). `_setTrim` (:551-565): per-area chip writes only that area's field; "All" writes `trimColor` AND resets all three per-area overrides to 'auto'. Trim swatches have NO custom hex picker (only the 8 swatches) — the hex dialog (:196) only writes baseColor.
- Painter fall-back chain: `_collarTrim = collarColor ?? trimColor`, same for pocket/cuff (lib/screens/studio/editor/canvas/design_canvas_painters.dart:128-130); when both null a shade derived from the tee colour is used via `_adjust` (:146-148, :206, :246-248).
- Canvas maps 'auto' -> null with `_areaColor` (lib/screens/studio/editor/canvas/design_canvas.dart:58-59) and passes the four colours to `GarmentOverlayPainter` (:227-237).
- Polo buttons: drawn at design_canvas_painters.dart:189-196 with `_adjust(_collarTrim ?? tshirtColor, 0.42)` — a lightened/darkened derivative of the collar colour; radius 3.5, two buttons; the placket line colour is the collar border colour (:180-188). There is no `buttonColor` in the model, no chip in `_buildTrimAreaChips` (color_panel.dart:568-573 lists only all/collar/pocket/cuff), and nothing in GarmentOptions. So buttons are NOT separately colourable.
- Sleeves: the sleeve body is simply `baseColor` (colour-filtered photo, design_canvas.dart:137-141, or SleevePainter `color`, :166-172). The sleeve hem band in SleevePainter is a fixed 10% black overlay (design_canvas_painters.dart:449-456), not colourable. Cuff colour only affects the front-view overlay stripes (painters :243-297), not the sleeve views.
- Pocket close-up uses `pocketColor ?? trimColor` (design_canvas.dart:116-118) else a 10% shade of fabric (painters :550-553). Pocket stitching/border are derived (:559-577).
- Fabric finish (solid/heather/vintage) is a texture, not a colour (garment_options.dart real lines 87-98; painters :301-352).
- Garment-form options (not colours) live under the "Shapes" tool: collar crew/vneck/polo (lib/screens/studio/editor/panels/garment_options.dart:30-44), pocket none/left/right/both (:54-64), sleeve cuff none/banded/rolled (:70-81), fabric finish (:87-98). (garment_options.dart line numbers: the audit's first `cat` printed it after garment_registry.dart, so these are file-relative = printed - 162.) Mounted at design_studio_screen_layout.dart:800.

### Inferences
- Adding a polo button colour needs: a model field (e.g. `buttonColor`), a chip in color_panel.dart:568-573, a `Color? buttonColor` on GarmentOverlayPainter and use at painters :189-194, and the same for shouldRepaint (:383-392).
- "All" trim chip silently erasing per-area overrides (color_panel.dart:558-563) is a UX gotcha (order dependent), not a bug.

### Gaps
- No hem, neck-label, sleeve, button, placket, stitching, or inner-neck colour options exist; not present anywhere in lib/.

---

## Q2. Which print areas exist and what is missing?

### Takeaway
Six print sides exist: front, back, left sleeve, right sleeve, left pocket, right pocket. Missing: nape/back neck, hem, inside/neck label, side seam, collar/placket, cuff band. The backend knows a `neck_label` placement the app cannot reach, and has no pocket placement.

### Cited Findings
- `DesignSide` enum: front, back, left, right, leftPocket, rightPocket (lib/models/custom_design.dart:19-33); `isSleeve` :36, `isPocket` :37, `isSmallArea` :40; parse :41-48. Every element carries a `side` (:76, default front :91; serialised :140, parsed :158).
- Canvas side toggles: two rows — Front/Back/Left/Right and L Pocket/R Pocket (design_canvas.dart:361-372). Drawn view per side: pocket -> `PocketAreaPainter` (:107-122), sleeve with asset -> mirrored photo (:125-160), sleeve without asset -> `SleevePainter` (:161-174), body -> photo or placeholder (:176-218).
- Elements drawn only for the active side (`design.elementsForSide(side)`, design_canvas.dart:261-262; model :367-368).
- Readout text is hard-coded per class: pocket "PRINT 8 x 8 cm", sleeve "PRINT 8 x 10 cm", else "PRINT 30 x 40 cm" (design_canvas.dart:405-409). Not enforced anywhere (see Q5 clamps).
- Print placement control ("Centre chest"/"Left chest") sets `printLocation` (lib/screens/studio/editor/panels/placement_panel.dart:19-20, :35-49); its only reader is a label in the layers list (lib/screens/studio/editor/panels/layers_panel.dart:125). It moves nothing: grep shows no other consumer of `printLocation` in lib/. So "Left chest" placement is cosmetic; real left-chest printing is the left-pocket side instead.
- Backend placements: front, back, sleeve_left, sleeve_right, neck_label (BE:src/garments.js:17-24); `SIDE_OF.neck_label = null` (BE:src/garments.js:17) means the app has no side for it. Backend sleeve placement = 1200x1200 px @300 dpi (~10.2 cm square, BE:src/garments.js:22-23, provisional: true) vs the app's "8 x 10 cm" label. No pocket placement in the backend.
- Nothing for: nape/back neck, hem, side, inside label, collar print, cuff print — no enum value, no UI (grep of lib/ for these terms finds only the SleevePainter "Hem band" decoration at design_canvas_painters.dart:449-456).

### Inferences
- Back view has no overlay at all (see Q4/Q6) so back-neck/nape work would need both a new `DesignSide` and a back overlay.

### Gaps
- Real print-size limits per side for the pocket (8x8 cm) are only a label; no source of truth in the backend for pockets.

---

## Q3. Are options only for the T-shirt? What about hoodie/polo/cap/tote?

### Takeaway
Yes, effectively T-shirt only. The registry lists hoodie/polo/cap/tote with no images (placeholder) and the UI hides them. Collar/pocket/cuff/finish/sleeve/pocket views are gated by a single `supportsCollarPocketOverlay` flag that only the T-shirt sets, and the options panel is not gated at all.

### Cited Findings
- Registry defaults: tshirt has front/back/left/right asset paths + `supportsCollarPocketOverlay: true` (lib/screens/studio/editor/canvas/garment_registry.dart:91-99); hoodie, polo, cap, totebag have only id+label (:100-103), so `hasAsset` is false (:54) and the canvas shows the "Coming Soon" placeholder (design_canvas.dart:217-218, :457-492).
- UI selector lists only T-Shirt (lib/screens/studio/editor/design_studio_screen.dart:77-83; comment says live categories would replace it via `_loadCategories()` — that method does not exist, grep finds only the comment at :79). Selector built at design_studio_screen_layout.dart:887-934.
- Backend garment data never reaches the studio: `GarmentService.loadGarments()` is an empty method (lib/services/studio/garment_service.dart:7) and `GarmentRegistry.updateFromBackend` has no callers (grep over lib/ and test/ finds only its definition garment_registry.dart:111 and a doc comment). The `frontImageUrl/backImageUrl/leftImageUrl/rightImageUrl` fields in `Garment.fromJson` (:75-83) are therefore dead on the studio side.
- Overlay gate: `_hasFaceAsset && side == DesignSide.front && _garment.supportsCollarPocketOverlay` (design_canvas.dart:221-223).
- Un-gated pieces: `PocketAreaPainter` view renders for any garment (design_canvas.dart:107, no garment check); `GarmentOptions` is always shown in the Shapes pane (design_studio_screen_layout.dart:800) with no garment check, so on a garment without the overlay the chips would change the model but nothing would render.
- `collarStyle == 'polo'` is a T-shirt collar variant, not the 'polo' garment (garment_options.dart:36-40; registry :101).
- Backend lists garment "styles" `crew, vneck, scoop, henley, polo, raglan, longsleeve, tank, oversized` (BE:src/garments.js:67-68) used for mock-ups, taken from the garment record (BE:src/layers.js:162), not from the design's `collarStyle`. Backend product types: T-Shirt/Hoodie/Sweatshirt/Tank Top (BE:src/validate.js GARMENT_ALIASES at line ~109 `const GARMENT_ALIASES`; AI prompt design_prompt.txt:78).
- The `_selectedGarmentType` is sent on publish as `garment` (design_studio_screen_actions.dart:390) but is not stored inside `CustomDesign.productType` (always 'T-Shirt' default, custom_design.dart:209).

### Inferences
- Selecting another garment (if the selector were un-hidden) would show a placeholder and the Colour/Garment panels would be meaningless.

### Gaps
- Not checked: whether any Sanity/CMS fields feed `supportsCollarPocket` at runtime — no runtime path calls `updateFromBackend`.

---

## Q4. Are the new options carried through saving, publishing, thumbnails, 3D, pricing/order, AI, templates? Where are pocket/sleeve sides or per-area colours dropped?

### Takeaway
The data (JSON) survives save/publish/remix/order storage. What is dropped: any image/preview (front/back only, and likely unpainted), pricing, the print sheet, the AI assistant (resets everything it does not echo), templates, and the DesignWear/community fallback preview.

### Cited Findings — persistence (OK)
- Local save: `SavedDesign.toJson` embeds `design.toJson()` (lib/services/studio/design_storage_service.dart:45); autosave uses same service (design_studio_screen.dart:150-156). Save dialog stores a thumbnail from `captureCallback` (lib/screens/studio/editor/widgets/dialogs/save_design_dialog.dart:56-63).
- Publish: `_design.toJson()` sent as `designJson` (design_studio_screen_actions.dart:391 -> lib/services/community/community_service.dart:46-69). Backend stores designJson as-is after a size/shape check (BE:src/validate.js `studioDesign` ~113-122: <=400 KB, <=60 elements) and keeps it (BE:src/routes/designs.js:87).
- Remix: `CommunityDesign.toStudioDesign` -> `CustomDesign.fromJson` (lib/models/design.dart:81-85) preserves all new fields.
- Order: the order line carries only `designId` (lib/services/shop/cart_service.dart:85); the backend copies the whole `designJson` into the print job (BE:src/routes/orders.js:63-73).

### Cited Findings — where things are dropped / ignored
1. Thumbnails / published previews are front and back only. Publish captures `_frontCaptureKey` and `_backCaptureKey` (design_studio_screen_actions.dart:385-386), the only two offstage canvases (design_studio_screen_layout.dart:326-374 desktop, :431-479 mobile). No sleeve or pocket capture. Backend schema also has only `previewImage`/`backPreviewImage` (BE:src/routes/designs.js:88-91, BE:src/presenters.js:34-35).
2. Elements on sleeve/pocket sides are not composited into any front/back image: canvas draws `elementsForSide(side)` only (design_canvas.dart:261-262). So published/ordered previews never show sleeve/pocket art.
3. Offstage captures are probably blank/null: they are wrapped in `Offstage` (layout :328, :352, :433, :457) which lays out but does not paint its child; `RenderRepaintBoundary.toImage` on an unpainted boundary throws and `_captureCanvasPng` swallows it and returns null (actions :340-356). I did not run it, so this is unverified, but the code path is the documented behaviour of Offstage. Also the offstage canvases are NOT `bare` (the `bare` param, design_canvas.dart:34, is passed by nobody — grep for `bare` in lib/ finds only design_canvas.dart), so if they did paint, the previews would include the dotted grid, the view-toggle pill, the "PRINT 30x40" readout, and the dashed guides (design_canvas.dart:98-104, :347-388, :391-418; SleevePainter/PocketAreaPainter `showGuide: !bare`).
4. Save-dialog thumbnail and Try-On capture the live canvas, i.e. whichever side is on screen (`_captureCanvasPng()` default key `_canvasKey`, actions :343; try-on :552-562): if the user is on a pocket/sleeve view the thumbnail/try-on garment is a pocket close-up or a sleeve, with UI chrome included (not bare). Save dialog calls `captureCallback: _captureCanvasPng` at layout :137, :180.
5. 3D preview is a stub: SnackBar "3D preview is not available yet." (actions :537-541); buttons at layout :142-150, :183-184, :209-211. `bare` was meant for "clean texture for 3D preview" (design_canvas.dart:32-34). Therefore no 3D carries sleeves/pockets.
6. Pricing/order: price is `garments.priceOf(design.garment)` per line (BE:src/pricing.js:19-25, :173 garments.js) — independent of any option (no pocket/cuff/sleeve-print surcharge). The line `imageUrl: null` (BE:src/pricing.js:21) so cart shows no design image (lib/screens/cart/cart_screen.dart:58 uses `line.imageUrl`).
7. Print sheet for fulfilment shows only `previewImage`/`backPreviewImage`, base colour, size, qty and a bullet list of elements as `type: content, font, colour` — no side, no collar/pocket/cuff/finish/trim/per-area colours (BE:src/print.js:35-44 elementLines; :47-69 printSheet; picture() only front/back at :50-53,:66). A print operator would not see which sleeve/pocket an element belongs to nor the trim colours, unless they read raw designJson.
8. AI assistant (design agent) overwrites garment options and element sides:
   - The prompt only documents `baseColor`, `elements` (no `side`), and example JSON without collar/pocket/trim/cuff/finish (BE:src/design_prompt.txt:12-14, :16-31, :75) and tells the model "ALWAYS include ALL elements you want on the shirt — elements not listed will be removed" (:63).
   - Server only validates/clamps the reply (BE:src/ai.js:77-102) and the app builds `CustomDesign.fromJson(edit)` (lib/services/ai/ai_agent_service.dart:120) then replaces the whole design (`_onAiDesignUpdate` -> `_updateDesign(incoming)`, design_studio_screen_actions.dart:334; from agent_chat_widget.dart:98-99). Any key the model omits falls back to defaults in fromJson (custom_design.dart:350-357 -> crew/none/auto/solid, element side :158 -> front). The current design JSON IS sent to the model (ai_agent_service.dart:95) so it may echo these keys, but nothing instructs or forces that — resets are likely (inferred, unverified at runtime). Existing back/sleeve/pocket elements not re-listed are deleted per prompt rule :63.
   - Artwork: app asks for `DesignSide.values` (includes pockets) (ai_agent_service.dart:48) but backend `/v1/ai/design-sides` only accepts front/back/left/right (BE:src/routes/ai.js:129-130) and only has briefs for those four (BE:src/ai.js:6-11) and the app doc says 'front'|'back'|'left'|'right' (lib/services/ai/ai_service.dart:~93-96). So AI never draws pocket art. The app side placement already treats pockets as small areas (`side.isSmallArea`, ai_agent_service.dart:28-32, uncommitted change) but that code path is unreachable.
   - Server clamps all AI elements to the FRONT print area -130..130/-100..200 irrespective of side (BE:src/ai.js:53-60).
   - Picture-only/auto-generate helper replaces the entire design with `CustomDesign(name: theme)` (actions :63), wiping colours/collar/pocket/etc., and puts the image on the active side `_side` (:61) even if that is a pocket.
9. Templates: `_applyTemplate` copies only `template.design.elements` (actions :69-70) — template baseColor/collar/pocket/trim are ignored; starter designs are front-only with default options (lib/services/studio/design_template_service.dart getStarterDesigns ~ lines 160-230, e.g. baseColor 0xFFE65100, no side/collar). Starter picker `_updateDesign(s)` (actions :472-475) replaces the entire design with the starter, resetting garment options. Saving custom templates keeps design JSON (design_template_service.dart:116-131) but nothing in the studio calls `saveCustomTemplate` (grep: only the service definition).
10. Community / fallback preview: detail screen toggles front/back only (lib/screens/studio/community/design_detail_screen.dart:78-82); feed/challenge cards use front `previewImage` only (community_screen.dart:151, challenge_screen.dart:210). The no-preview fallback `DesignPreview` draws the old `tshirt_white.png` tinted with baseColor only — no collar/pocket/cuff/trim (lib/screens/studio/shared/design_preview.dart:47-59).
11. Backend legacy `front`/`back` element validator reduces to text/sticker, 40-char content, normalised 0..1 coords (BE:src/validate.js `elements` ~41-58) — the studio does not send it; irrelevant for pockets but shows the "official" schema has no sides beyond front/back.
12. Backend "layers" pipeline (BE:src/layers.js, placements front/back/sleeve_left/sleeve_right/neck_label) is not called by the Flutter app (grep for `/v1/layers` in lib/ finds nothing), and its mock-up style comes from the garment (`style: garment.style`, BE:src/layers.js:162), so it ignores the design's collar/pocket/cuff/colour options.

### Inferences
- The only end-to-end carrier of pocket/sleeve/per-area-colour data is `designJson`; every downstream consumer other than re-opening in the studio uses images or a front/back-only schema, so a fulfilment operator cannot see pocket/sleeve art (items 1, 2, 7).

### Gaps
- Did not verify the actual runtime behaviour of the Gemini model re: echoing collar/pocket keys (item 8) nor whether offstage capture works on a real device (item 3).
- Did not inspect SethuCMS / order_sync mapping (BE:src/order_sync.js) for design option fields.

---

## Q5. Real bugs / inconsistencies

### Takeaway
Most serious: the new "cutout" assets are JPEGs with a baked-in fake checkerboard background, left and right sleeve files are byte-identical, overlay coordinates were calibrated for the old 1080x1440 photo, and at least one existing widget test now contradicts the code.

### Cited Findings
1. Cutout assets are not cutouts. `assets/images/tshirt_cutout.png`, `tshirt_back_cutout.png`, `tshirt_left_cutout.png`, `tshirt_right_cutout.png` are all 1024x1024 JPEG (JFIF) files with a .png extension (output of `file`), and viewing them shows a baked grey/white checkerboard "transparency" background. The canvas applies `ColorFiltered(... BlendMode.modulate)` to the image (design_canvas.dart:138-141, :177-181), so the checkerboard is shown and tinted with the garment colour. Registered at garment_registry.dart:94-97. (Previous asset was `tshirt_white.png`, 1080x1440 PNG.)
2. Left and right sleeve assets are byte-identical (md5 09d82cfd792de1793dce742e0b6aa72c for both). The canvas ALSO flips the right view horizontally (design_canvas.dart:127-136, comment ":Right sleeve is the left photo flipped"), while `Garment.imageUrl(right)` returns `rightAsset` (garment_registry.dart:41). A true right-sleeve image supplied later would be double-mirrored; today the right asset is redundant. Backend CMS `rightImageUrl` (garment_registry.dart:80) also flows through the flip.
3. Overlay is front only: `side == DesignSide.front` (design_canvas.dart:222). Back view gets no collar/back-neck, no cuffs, no fabric finish; sleeve views (photo or painter) get no cuff style/colour, no finish (SleevePainter ignores `sleeveCuff`/`cuffColor`, painters :399-509); pocket close-up ignores `pocketStyle` (renders a patch even when `pocketStyle=='none'`, design_canvas.dart:107-122; PocketAreaPainter has no pocketStyle param, painters :515-526). A user can add artwork to "L Pocket" while the shirt has no left pocket; that artwork never appears on the front view.
4. Overlay coordinates are stale vs the new front asset. Painter comment: "Coordinates calibrated for tshirt_white.png at 300px in a 332x407 canvas" (painters :83). The new front image is square: at 300 px it is 300x300 centred in the 332x407 stack, i.e. offset (16, 53.5) and scale 0.293 image-px->canvas-px (computed). Consequences (computed from constants, not rendered):
   - Pocket centres 108 and 224 (painters :119-120) map to image x~314 and ~710; the shirt body at chest height spans only ~290-735 and a 44 px pocket is ~150 image px wide, so each pocket overhangs the armhole/sleeve edge by ~50 image px.
   - V-neck tip at y=126 (:114) maps to image y~247 while the photo's crew neckline bottom is ~160; polo placket (80..122) similarly extends below the neckline.
   - Fabric-finish clip `Rect.fromLTRB(72,110,260,360)` (painters :305) maps to image x 191..833, y up to ~1046: it spills ~100 image px past each side of the torso into the sleeve/background and ~23 canvas px below the hem (hem is at canvas y~337).
   - Cuff endpoints (52,188)-(96,174) and (280,188)-(236,174) (:123-126) were set for the old photo.
5. Element clamps ignore the area size. Drag clamp `printAreaMin/MaxX/Y` = -130..130, -100..200 (lib/screens/studio/editor/support/design_studio_constants.dart:109-112) used by drag (lib/screens/studio/editor/widgets/elements/transformable_element_widget.dart:97-104) and keyboard nudge (design_studio_screen_actions.dart:175-192) regardless of side; max element size 220 (constants :116). The pocket guide in element space is only ~120 x 142 px at x -44..76, y 8..151 (computed from PocketAreaPainter guide `Rect(0.30,0.30,0.40,0.38)` at painters :581 on a 300x375 box offset by 16 px in the 332x407 stack), the sleeve guide ~102 x 150 px (painters :479). Elements can be placed or sized far outside the 8x8 cm / 8x10 cm labelled area and are not clipped to it (no clipping in design_canvas.dart:261-287).
6. Default/new element position vs pocket guide. New text/stickers/shapes/images are added at x=0,y=0 (actions :77-78, :100-101, :117-118, :132-133) -> top-left at stack (150,120), which is above the pocket guide top (~128.5) and left of its centre; the AI small-area placement (-40,-25, 90x90) (ai_agent_service.dart:31) puts the box at stack x 110..200, y 95..185, i.e. ~33 px above the pocket guide and ending ~86 px before its bottom (computed). The sleeve photo view has no guide at all (guide only exists in SleevePainter, painters :477-501).
7. Layer reorder bug: bring-forward/send-back compute indices within `elementsForSide(_side)` (layout :585-588, keyboard actions :212-224) but pass them to `reorderElements(oldIndex,newIndex)` which acts on the full cross-side list (custom_design.dart:392-397) -> with elements on other sides (now common) the wrong element moves or nothing visible changes. Layout :629, :635; actions :215, :224.
8. Layers panel lists elements from all sides with no side badge (`generateLayersData`, lib/screens/studio/editor/support/design_studio_utils.dart:114-142; panel layers_panel.dart:~91-). Tapping a layer on another side selects it but the canvas (which draws only the active side) does not show it, while the action bar still appears (layout :576-583). Switching side does not clear the selection (layout :323, :428).
9. Existing widget test is now inconsistent with the code. test/screens_test.dart:225-265 expects a `SleevePainter` on LEFT/RIGHT (and `mirrored` flags), but `tshirt` now has `leftAsset`/`rightAsset` (garment_registry.dart:96-97), so the photo branch (design_canvas.dart:125) is taken and `SleevePainter` is never built. Inferred failure; tests were not run.
10. Test coverage gaps: only model-level tests for pockets/per-area colours (test/pocket_areas_test.dart:5-25). No tests for `PocketAreaPainter`, `GarmentOverlayPainter` colours, `ColorPanel` trim area chips, `GarmentOptions`, pocket toggles, element clamps, side-preserving AI/template flows. test/ai_sides_test.dart:90-117 asserts only front/back/left/right.
11. Print-size labels vs backend: app 8x10 cm sleeve (design_canvas.dart:407) vs backend 1200x1200 px@300dpi (BE:src/garments.js:22-23); app 30x40 cm front vs backend 3600x4800@300dpi = 30.5 x 40.6 cm (BE:src/garments.js:20) — consistent for body only.
12. Legacy fallback `designImageBase64` graphic is only rendered on the front at fixed rect (design_canvas.dart:243-258); `_onAiDesignUpdate` converts it to an image element on the *current* side (actions :317-332).
13. `Garment.fromJson` reads `supportsCollarPocket` (garment_registry.dart:82) but the BE garment record has no such flag (BE:src/garments.js:127-129 shows only image URLs and placements) — a CMS-driven garment would never enable overlays even if `updateFromBackend` were wired.

### Inferences
- Items 1, 4 mean the headline new feature (pockets/cuffs/collar on the new photos) is likely visibly misaligned today; a render check is the obvious next verification.

### Gaps
- No screenshots/golden tests were produced; geometry in items 4-6 is computed.

---

## Q6. Dead UI: buttons or controls that do nothing

### Takeaway
Three clear dead controls (3D preview, Placement panel, unused canvas `bare` flag) plus unused widgets.

### Cited Findings
- 3D Preview button (desktop app bar and mobile overflow menu) only shows "3D preview is not available yet." (layout :142-150, :183-184, :205-212; actions :537-541).
- Placement tool ("Centre chest"/"Left chest"): changes `printLocation` which only changes a label in the Layers list (placement_panel.dart:35-49; layers_panel.dart:125). Elements do not move; Pocket sides supersede it.
- `DesignCanvas.bare` is never set true (grep), so the "clean texture" mode is unused (design_canvas.dart:32-34, 36-52).
- Garment options on non-T-shirt garments (if exposed) would be silent no-ops (see Q3).
- Unused widgets (only exported from the barrel, never instantiated): `ColorsTab` (lib/screens/studio/editor/widgets/tabs/colors_tab.dart), `TemplatesTab` (widgets/tabs/templates_tab.dart), `DraggableElementWidget` (widgets/elements/draggable_element_widget.dart); barrel lists at widgets/widgets.dart (exports of colors_tab, draggable_element_widget, templates_tab). `ToolsPanel`'s 'color' tool uses `ColorPanel` instead (layout :548-549).
- `DesignStudioConstants.toolTabs` (design_studio_constants.dart:77-82, a different tab list — Colors/Text/Stickers/Templates) appears unused by the current ToolsPanel (tools list at tools_panel.dart:17-54); not exhaustively grepped.
- Custom templates can be saved by the service (design_template_service.dart:116-131) but the studio has no UI that calls it (grep).

### Inferences
- Dead-code candidates are safe to remove but not harmful.

### Gaps
- `DesignStudioConstants.toolTabs`/`tShirtColors` usage not verified.

---

## Appendix A — Complete inventory of customisable options (T-shirt)

| Option | Values | Model | UI | Rendered on |
|---|---|---|---|---|
| Body colour | 40 swatches, hex, recents, palettes | custom_design.dart:165 | color_panel.dart:35-83, 196-327 | front, back, sleeve photo/painter, pocket close-up (design_canvas.dart:127-141, :177-181, :113-115) |
| Collar style | crew / vneck / polo | :183 | garment_options.dart:30-44 | front only (design_canvas.dart:222; painters :143-198) |
| Collar colour | auto/hex (8 swatches) | :187 | color_panel.dart:567-605, 607-673 | front only |
| Trim (all) colour | auto/hex | :185 | same, chip "All" | collar/pocket/cuff when no per-area value |
| Pocket style | none / left / right / both | :184 | garment_options.dart:54-64 | front overlay only (painters :202-239; 'left' draws at the viewer's right) |
| Pocket colour | auto/hex | :188 | trim chip "Pockets" | front overlay + pocket close-up |
| Sleeve cuff | none / banded / rolled | :190 | garment_options.dart:70-81 | front overlay only (painters :243-297) |
| Cuff colour | auto/hex | :189 | trim chip "Cuffs" | front overlay only |
| Fabric finish | solid / heather / vintage | :191 | garment_options.dart:87-98 | front overlay only (painters :301-352) |
| Print sides | front, back, left, right, leftPocket, rightPocket | :19-33 | design_canvas.dart:361-372 | active-side view only |
| Print placement | centre_chest / left_chest | :179 | placement_panel.dart | label only |
| Elements | text, sticker, shape (rect/circle/triangle/line), image | :1-16 | layers/text/emoji/shapes tools | active side |
| Element controls | opacity, flipH/V, z-order, duplicate, delete, rotate/scale/move, centre snap | :58-77 | layout :576-740, transformable widget | all sides |

Not available: button colour, sleeve colour, hem/neck-label/nape/side/inside prints, collar/cuff prints, non-T-shirt garments, per-area pricing, 3D, sleeve/pocket in previews or print sheet.
