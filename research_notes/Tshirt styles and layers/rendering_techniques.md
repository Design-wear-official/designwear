# Rendering recolourable, layered garment mockups with user artwork (2D, optional 3D) in Flutter

Scope note: ~10 searches/fetches. Many search results were secondary (vendor blogs, help centres). Items marked "[unsourced / from general graphics knowledge]" are NOT backed by a fetched source and should be verified before the report states them as fact.

## 1. Mask-based recolouring: assets, blend modes, white vs dark garments

### Takeaway
Standard approach is: one shading/texture layer (greyscale or photo) plus one alpha-mask per recolourable part, tinted per part and multiplied over the shading. Multiply-based tinting only darkens, so black/dark garments need a different recipe (separate highlight/shadow layers, screen/overlay for highlights, or a luminosity-preserving blend); I found no primary-source doc of exactly what commercial tools do.

### Cited Findings
- Flutter's `BlendMode.modulate` multiplies colour components only and "can only produce the same or darker colors"; it does not multiply alpha (use `multiply` for that). `multiply` includes alpha, so a transparent pixel in either image gives transparent output. — [Flutter BlendMode API](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- `srcATop` composites source over destination only where they overlap and keeps destination alpha; `srcIn` uses the destination only as a mask (its colours ignored). These are the natural building blocks for "paint colour X inside this part's mask". — [Flutter BlendMode API](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- `overlay` (favours destination), `hardLight` (favours source), `softLight` (gentler overlay) and `color` (source hue+saturation, destination luminosity) exist as Flutter blend modes; `color` is the one that keeps the shading of the destination while swapping hue. — [Flutter BlendMode API](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- Skia documents Modulate as a mashup of SrcATop and Multiply. — [Skia SkBlendMode overview (mirror)](https://os.unplugged.com/werunplugged/unplugged-vendor/raw/branch/main/external/skqp/docs/SkBlendMode_Overview.bmh)
- Photoshop mockup tutorials: use Multiply or Overlay (or Soft Light) for the design layer to integrate it with fabric texture; Multiply only darkens, so a white print will not read on black fabric; one source suggests keeping a separate white-underbase layer for dark garments, another suggests Multiply for darks and Screen for highlights. Sources are low-quality blog/SEO pages — treat as indicative only. — [Photoshop Roadmap](https://www.photoshoproadmap.com/how-to-create-realistic-design-mockups-in-photoshop/), [Vocal](https://vocal.media/art/how-to-create-realistic-t-shirt-mockups-in-photoshop), [Adobe displacement map page](https://www.adobe.com/products/photoshop/displacement-map.html)
- Fabric.js ships `BlendColor` (modes incl. multiply, add, screen, overlay, tint, etc.; default multiply) and `BlendImage` (modes multiply and mask), i.e. a JS reference implementation of colour-tint and image-mask recolour. — [Fabric.js BlendColor](https://fabricjs.com/api/fabric/namespaces/filters/classes/blendcolor), [BlendImage](https://fabricjs.com/api/fabric/namespaces/filters/classes/blendimage/)
- Konva has no image-based clip; clipping is path-based. Image masks are done with a custom Shape using `source-in`. Group-level blend modes need `isolated: true` (Konva >= 10.7.0 per a translated docs copy). — [Konva Isolated Groups](https://konvajs.org/docs/groups_and_layers/Isolated_Groups.html), [Konva Blend mode](https://konvajs.org/docs/styling/Blend_Mode.html)

### Inferences
- Recommended asset pack per garment view (front/back/left/right): (a) `shading.png` greyscale luminance with folds (white-ish base, neutral grey midpoint), (b) `mask_<part>.png` per part (body, sleeves, collar, pocket, cuffs...) as alpha-only or white-on-transparent PNG, non-overlapping and slightly feathered, (c) optional `highlight.png`/`specular.png` for screen blending, (d) optional `displacement.png` and `print_area.json` (rect/path in image pixels + physical size in cm). Export from layered PSD with a script rather than hand-drawn vector overlays. [Recipe is my synthesis; Zakeke/Printful use analogous per-area definitions but I did not see their raster pipelines documented.]
- Per-part recolour in Flutter, one saveLayer-free approach: pre-bake each mask into a coloured layer at load time (draw mask with `srcIn` fill colour into a `ui.Image` via `PictureRecorder`), cache it per (garment, part, colour), then composite: base shading `multiply` over the stack of coloured parts. Re-bake only the part whose colour changed.
- Dark garments: pure multiply of colour x white-based shading gives dark shades that lose fold detail. Likely strategy: for target luminance below a threshold, compose as `colour fill` then add shading through `overlay`/`softLight` (or a luminosity-preserving blend) and a `screen` highlight layer; or ship a dedicated dark-base shading asset. Prefer a custom fragment shader (section 3) that remaps shading `s` as `mix(colour*s*2, 1-(1-colour)*(1-(2s-1)), step(0.5,s))` (i.e. overlay-style) so folds remain on black. [unsourced / from general graphics knowledge]

### Gaps
- No primary source found for how Customily, Zakeke, Printful or Placeit handle black garments internally (asset format, blend recipe).
- No authoritative doc on PSD-to-mask export automation or normal-map use in 2D mockups found.

## 2. Artwork warping / displacement, preserving shading

### Takeaway
The cheap realistic method is: derive a height map from the mockup luminance, offset artwork sample positions by `(height-0.5)*strength`, then multiply a shade map so folds darken the print. It runs ~80 ms in-browser in one published example, but must be recomputed when the design changes.

### Cited Findings
- A Fabric.js write-up builds a greyscale height map from mockup brightness (BT.601 luma, stretched to 0-255, transparent = neutral grey), blurs it (20 px), offsets each design pixel by `(disp-0.5)*strength` rotated by design angle with bilinear sampling, and multiplies a shade map `1-(1-shade)*blendFactor` (0.6 => dark folds to 40% brightness). ~80 ms, recomputed on `object:modified` not during drag, disabled <768 px wide. Code snippets in the article are incomplete (undefined variables, missing shade-map generation). — [DEV: Realistic fabric wrinkles in real time](https://dev.to/javedblch/realistic-fabric-wrinkles-in-real-time-building-displacement-maps-with-fabricjs-nch)
- Photoshop workflow: duplicate shirt, greyscale, blur if jagged, use as displacement map via Filter > Distort > Displace; then Multiply/Overlay/Soft Light the design. — [Adobe displacement map page](https://www.adobe.com/products/photoshop/displacement-map.html)

### Inferences
- In Flutter this maps to a `FragmentProgram` with two samplers (artwork, displacement) and a print-area uniform; or CPU-side per-pixel pass in an isolate for export. Real-time per-frame is only practical in a shader. [Design inference]
- To keep shading without hurting print output: apply displacement and multiply only in the *preview* pipeline; export the unmodified artwork at print resolution.
- Light-colour garments: multiply artwork by shading. Dark garments: artwork over shading with `softLight`/low-opacity multiply so the print doesn't go muddy. [unsourced]

### Gaps
- No Flutter-specific displacement example found. Normal-map-based approaches in 2D not covered by any source found.

## 3. Flutter specifics: blend/ColorFilter, shaders, saveLayer cost, capture, sharpness

### Takeaway
Use `Image(color:, colorBlendMode:)` or pre-baked layers for simple tints, a FragmentProgram for mask+shading+displacement in one pass, and avoid layers that force `saveLayer` (Opacity, ColorFiltered, ShaderMask) in large counts. Capture with `RenderRepaintBoundary.toImage(pixelRatio:)` and size the pixelRatio to the print target, not the screen.

### Cited Findings
- `saveLayer()` is expensive (offscreen buffer, render-target switch); Opacity is singled out as costly; `ColorFilter`, `ShaderMask` and some others can trigger saveLayer. Detect with `checkerboardOffscreenLayers`. — [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices), [testing/best-practices](https://docs.flutter.dev/testing/best-practices)
- A third-party article recommends `Image.color`/`blendMode` instead of wrapping in `ColorFiltered` to avoid an extra composited layer (secondary source). — [Medium: composited layers](https://medium.com/@pomis172/understanding-composited-layers-to-improve-the-performance-of-flutter-apps-7b91079b4dd1)
- `Canvas.saveLayer`'s paint blend mode is applied at `restore()`, which is how you blend a group of layers (e.g. coloured parts) as a unit. — [Flutter BlendMode API](https://api.flutter.dev/flutter/dart-ui/BlendMode.html)
- Fragment shaders: declared under `flutter: shaders:` in pubspec, loaded with `FragmentProgram.fromAsset`; `sampler2D` uniforms set with `setImageSampler`; uniform indices follow declaration order; only `sampler2D` and the 2-arg `texture(sampler, uv)` are supported; shader used via `Paint.shader` or `ImageFilter`. — [Flutter fragment shaders docs](https://docs.flutter.dev/ui/design/graphics/fragment-shaders), [FragmentShader API](https://api.flutter.dev/flutter/dart-ui/FragmentShader-class.html)
- `RenderRepaintBoundary.toImage(pixelRatio)`: output size = render size x pixelRatio, independent of device pixel ratio; asserts the object has painted (debug `debugNeedsPaint`); returns Future; need `toByteData` for PNG. Docs state no size limit (practical GPU texture limits not documented there). — [RenderRepaintBoundary.toImage](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)

### Inferences
- Layer cost: with N parts x 4 views, don't build N `ColorFiltered` widgets. Bake to a single `ui.Image` per view/colour state (or one shader pass with a packed mask: R/G/B/A channels = 4 parts per mask texture, so ~2 mask textures cover 8 parts). Packing channels is a common trick [unsourced]; it removes most layers.
- Shader gotcha to test: sampler-based shaders in Impeller vs Skia and on web (CanvasKit/HTML renderer) have had differences; verify on target platforms. [Flagged uncertainty; not verified here]
- `FilterQuality.high` (or `medium` with mipmaps) on downscaled artwork reduces shimmer; default `low` is bilinear without mipmaps. [Flutter API knowledge; not fetched this session — verify at https://api.flutter.dev/flutter/dart-ui/FilterQuality.html]
- Export: render a *separate* high-res pass (pixelRatio = printPx / logicalWidth) of artwork only, rather than screenshotting the mockup canvas.

### Gaps
- No Flutter issue-tracker evidence gathered on shader/saveLayer regressions or max texture size for toImage.
- No benchmark numbers for many-layer compositing in Flutter.

## 4. Sharpness of user images/stickers; DPI check; vector vs raster

### Takeaway
Decode at displayed size x devicePixelRatio (via cacheWidth/cacheHeight / ResizeImage) for the editor, but keep the original bytes for print export; compute effective DPI = image pixels / physical print size and warn below 150 (error ~below 100), target 300.

### Cited Findings
- `cacheWidth`/`cacheHeight` make the engine decode at that size; layout constraints still decide the painted size; primary aim is reducing ImageCache memory. `Image.memory` wraps in `ResizeImage.resizeIfNeeded`. Recommended: widget width x devicePixelRatio; `debugInvertOversizedImages` finds oversized decodes. A 750x421 display image decoded at 3840x2160 wasted ~41 MB. — [Image.memory API](https://api.flutter.dev/flutter/widgets/Image/Image.memory.html), [Medium article](https://medium.com/make-android/save-your-memory-usage-by-optimizing-network-image-in-flutter-cbc9f8af47cd)
- Print thresholds: Printful says most products need >= 150 DPI (phone cases/stickers 300); Printify recommends 300 (some 120-150); Redbubble warns below ~150 DPI at print size (3600x4800 px for t-shirts). Effective DPI = pixels / print inches (metadata is irrelevant); 12x16 in needs 1800x2400 px at 150 DPI, 3600x4800 at 300. A mockup preview can hide low-res art. Tiers example: pass >=300, warn 150-299, fail <150. These are vendor/blog sources. — [Printful printfile guide](https://www.printful.com/blog/everything-you-need-to-know-to-prepare-the-perfect-printfile/a/dodropshipping), [LetsEnhance resolution reference](https://letsenhance.io/blog/all/image-resolution-print-quality/), [PitchPrint DPI check](https://coming.pitchprint.com/features/capabilities/dpi-check), [WildAndFree DPI guide](https://wildandfreetools.com/blog/dpi-for-tshirt-print-150-300-explained/)
- Zakeke generates design textures at 1024 px (desktop/Android) and 512 px (iPhone) by default, configurable per customizable area. — [Zakeke: Design texture resolution](https://zakeke.zendesk.com/hc/en-us/articles/12635040982940-Design-texture-resolution)

### Inferences
- Implementation: store `originalBytes`, `pixelWidth/Height`; on each transform compute `dpi = pixelWidth / (elementWidthInPx / printAreaPxPerInch)`; badge the element when <150. Decode a preview-size version for editing and re-decode the original only at export.
- Stickers: ship as SVG (e.g. via `flutter_svg`) or high-res PNG; vector stays sharp at any print size, so rasterise at export pixelRatio. [flutter_svg not verified this session]
- Memory caution: Zakeke's 512/1024 texture caps show 3D/preview textures are intentionally low-res vs. print files.

### Gaps
- No source on Flutter-side ImageCache limits (`maxSizeBytes`) tuning for a designer; no doc check on flutter_svg export fidelity.

## 5. 3D preview options and UV mapping

### Takeaway
Workable path: a GLB garment with a UV layout whose texture = the flattened 2D design (per-area canvases), rendered via model-viewer-based Flutter packages; the 2D design must be rendered into UV space, which requires per-garment UV templates.

### Cited Findings
- `flutter_3d_controller` is built on Google's model-viewer for GLB/GLTF/OBJ; has `setTexture(textureName)` and `getAvailableTextures()` for switching *named, pre-existing* model textures; web needs CORS headers. Version info on search pages was inconsistent (1.3.0 vs 1.3.1 vs 2.3.0) — check pub.dev. — [flutter_3d_controller on pub.dev](https://pub.dev/packages/flutter_3d_controller), [docs](https://pub.dev/documentation/flutter_3d_controller/latest/)
- `model_viewer_plus` is a GLB/glTF widget forked from a discontinued package, adds web support, maintainers warn it may lag model-viewer; no texture-swap API found. — [model_viewer_plus.dart](https://github.com/Slowline/model_viewer_plus.dart)
- Zakeke 3D: a "customizable area" is defined by a name, a mesh object, a size, camera position and a UV map channel; its Design Mapping tool adjusts UVs so the area lines up between the 3D model and its 2D representation, and requires a properly structured UV map (fix in Blender otherwise). — [Zakeke Mesh Unwrap for Design Mapping](https://zakeke.zendesk.com/hc/en-us/articles/18461110395804-Mesh-Unwrap-for-Design-Mapping) (page returned 403 to direct fetch; content from search snippet), [Zakeke pre-designed templates](https://zakeke.zendesk.com/hc/en-us/articles/10734802189340-Pre-designed-templates-for-Configurable-products)

### Inferences
- Whether `flutter_3d_controller`/`model_viewer_plus` can set an arbitrary runtime-generated texture (PNG bytes) is unconfirmed; with model-viewer's web API this is possible via JS (`createTexture`/`baseColorTexture.setTexture`) [unsourced; verify], which would need a WebView JS channel on mobile. Alternative: `three_dart`/`flutter_gl` or `flutter_scene` — not researched.
- Pipeline: render each garment area's artwork to a square texture at 1024-2048 px, upload as base-colour texture on the garment material; part colours go in as additional layers painted into the same texture (bake colour + shading into one UV texture).

### Gaps
- No verified runtime-texture-injection API for Flutter 3D packages; no evaluation of `flutter_scene`, `flutter_cube`, three.js-in-WebView performance.

## 6. Open-source / commercial references (architecture)

### Takeaway
Configurators converge on: a canvas editor (Fabric/Konva/Polotno) for artwork, per-product "print area" definitions, a mockup compositor for previews, and server-side print-file generation at full resolution.

### Cited Findings
- Printful: Mockup Generator API (`POST /mockup-generator/create-task/{id}` returns a task key to poll; `GET /mockup-generator/printfiles/{id}` returns print areas with pixel size and DPI); Embedded Design Maker is an iframe. Endpoint paths are from a third-party connector listing — verify at Printful's developer docs. — [Printful printfiles (glama)](https://glama.ai/mcp/connectors/io.usefulapi/printful/tools/printful_get_printfiles), [create mockup task](https://glama.ai/mcp/connectors/io.usefulapi/printful/tools/printful_create_mockup_task), [Polotno-Printful](https://polotno.com/sdk/product/integrations/printful)
- Polotno vendor page: Printful integration in closed beta since April 2026 (vendor claim). — same Polotno link
- Zakeke: see section 5 (customizable areas, UV channel, texture resolution).
- Konva: isolated groups + blend modes; Fabric.js: BlendColor/BlendImage filters (section 1).

### Inferences
- Reusable pattern for DesignWear: garment JSON = {views[], shading asset, parts[{id, mask asset, defaultColour}], printAreas[{rect, physicalSizeCm}], optional displacement/UV}. Adding a style then needs assets + JSON only, no new Dart code.

### Gaps
- Customily's architecture and Printful's own developer docs were not retrieved; no Fabric.js/Konva/Polotno doc on garment recolouring beyond the filter APIs.
