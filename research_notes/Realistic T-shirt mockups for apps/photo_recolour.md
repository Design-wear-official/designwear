# Photo-based realistic T-shirt mock-ups: recolouring (incl. dark colours) and printing designs on neutral product photos

Method note: web search and fetch worked this session (late 2026), but WebSearch returns short model-written summaries and some pages were unreachable (GIMP tutorial page returned 403). Claims marked "(inference)" are my own engineering reasoning from the cited primitives, not found in a source. Claims marked "(unverified)" could not be confirmed.

## Why plain multiply fails for dark colours, and what works instead

### Takeaway
Multiply (Cb x Cs) can only darken, and black is the absorbing value, so multiplying black/navy over a shirt photo wipes out all fold shading, and a black shirt photo cannot be recoloured by it at all. The workable approach is to keep the shading as a separate, range-normalised map taken from a light/mid-grey neutral shirt, and rebuild the colour as flat colour x shading (plus an optional additive highlight term for dark colours), masked to the garment.

### Cited Findings
- Multiply leaves black unchanged, white disappears, everything else gets darker; this is why a design multiplied onto an already-black shirt does nothing — [Browzwear help](https://help.browzwear.com/hc/en-us/articles/4921357133081) (via search summary; page not fetched).
- Colourising works best on mid-grey; it has little effect on full white or full black, so practitioners start from a light-grey shirt with folds and shadows and put a colour layer above it — [Adobe Community threads](https://community.adobe.com/t5/photoshop-ecosystem-discussions/create-transparant-tshirt-image/m-p/12936686/highlight/true) (via search summary; summary-level only).
- A forum expert notes saturated colours on a black shirt look muddy/brown unless there is a brighter underprint; real printing on black needs a white underbase — [Adobe Community](https://community.adobe.com/t5/photoshop-ecosystem-discussions/white-artwork-on-a-t-shirt/m-p/10031377) (search summary).
- Screen / Linear Light are suggested for highlights on dark mock-ups instead of Multiply — [Adobe Community](https://community.adobe.com/t5/photoshop-ecosystem-discussions/white-artwork-on-a-t-shirt/m-p/10031377) (search summary, low confidence).
- Another mock-up tool's users report designs look grey/flat on dark shirts — [Recraft feedback](https://feedback.recraft.ai/feature-requests/p/adjust-brightness-on-mockup-designs).
- W3C Compositing spec formulas (Cb = backdrop, Cs = source, 0..1):
  - Multiply: Cb x Cs. Screen: Cb + Cs - Cb x Cs.
  - Overlay = HardLight(Cs, Cb) (i.e. swap roles). Hard-light: Cs<=0.5 -> Multiply(Cb, 2Cs), else Screen(Cb, 2Cs-1).
  - Soft-light: Cs<=0.5 -> Cb - (1-2Cs)*Cb*(1-Cb); else Cb + (2Cs-1)*(D(Cb)-Cb), D(Cb)= ((16Cb-12)Cb+4)Cb if Cb<=0.25 else sqrt(Cb).
  - Lum(C)=0.3R+0.59G+0.11B; SetLum(C,l)=C+(l-Lum(C)) then ClipColor. Color: SetLum(Cs, Lum(Cb)); Luminosity: SetLum(Cb, Lum(Cs)).
  — [W3C Compositing and Blending Level 1](https://www.w3.org/TR/compositing-1/)
- sharp `tint()` keeps image luminance and applies a chroma from the tint colour; docs say it is a linear operation, so for sRGB input use `gamma()` with `greyscale()` for best results; alpha unchanged — [sharp colour docs](https://sharp.pixelplumbing.com/api-colour/) and [source mirror](https://docs.rs/crate/jjj/0.2.1/source/docs/node_modules/sharp/lib/colour.js). Note: my fetch of the official page returned only tint/pipelineColourspace/greyscale and did not cover modulate/recomb/linear/gamma, so those API details are unverified here.
- `pipelineColourspace('rgb16')` (or scrgb) makes all operations run in that space — [sharp colour docs](https://sharp.pixelplumbing.com/api-colour/).
- sharp `composite` supports blend: multiply, screen, overlay, darken, lighten, colour-dodge, colour-burn, hard-light, soft-light, difference, exclusion, plus Porter-Duff (over, in, out, atop, dest-in, add...); overlays must be same size or smaller than the base; options gravity/top/left/tile/premultiplied — [sharp composite docs](https://sharp.pixelplumbing.com/api-composite). No non-separable (hue/colour/luminosity) modes are listed, so Lab/HSL style recolour in sharp must be done with raw-pixel maths or `recomb`/`linear` (unverified), or in OpenCV/numpy.

### Inferences
Recommended pipeline (all my engineering reasoning from the formulas above):
1. Offline, once per view/garment style: from a neutral light-grey (not pure white, not clipped) photo make (a) a garment mask (alpha, hand-cut or segmented, include sleeve/neck edges), (b) a shading map S = clamp((L - L_lo)/(L_hi - L_lo)) where L is luminance of the neutral photo in linear light, normalised so the typical fabric flat area ~= 1.0 (so S is a pure gain, folds < 1, specular/highlights > 1 stored in a separate H map = max(L - 1, 0) if the photo has them). Store S in 16-bit PNG or 8-bit with gain scale to avoid banding.
2. Recolour in linear light: out_lin = C_lin * S (+ k * H * (1 - C_lin) for a soft highlight lift on dark colours), then convert to sRGB; mask with alpha. Doing this in linear light and not on sRGB bytes avoids the over-dark mid-tones from sRGB multiplication.
3. Dark colours: because C is near 0, C*S is nearly flat black and fold detail is lost. Fix by adding a lifted floor to the shading contribution, e.g. out = C*S + (1-C)*E where E is a small additive "sheen" term (E = e * (S-1) clipped >=0 plus H, e ~ 0.03-0.08 tuned), or equivalently blend with Screen/soft-light of a highlight layer. Real black cotton shows folds as lighter grey sheen, not as darker black, so the additive term is the physically sensible part.
4. Alternative: Lab/HSL recolour — take L from photo, set a,b from target (this is what `tint` does) — works for mid colours but gives wrong results for black/white targets because chroma becomes meaningless as L -> 0 or 100; use the gain+sheen model above for extremes.
5. Print layer on the garment: warp design (displacement or mesh warp from the same neutral photo), then out = lerp(out, design_colour * S_print, a * opacity) where S_print is S flattened toward 1 by a factor (ink sits on fabric, so shadows still apply but less contrast), optionally times a fabric-grain texture; on dark garments, light inks need an "underbase" i.e. render design opaque (not multiplied) so they stay bright — consistent with the black-shirt printing note above.

### Gaps
- No primary source gave an exact "dark colour" recolour formula; the sheen/gain model above is unvalidated and needs visual tuning.
- Official sharp pages for `modulate`, `recomb`, `linear`, `gamma` were not retrieved in this session.
- Could not retrieve the GIMP mock-up tutorial (logosbynick.com returned 403).

## How mock-up tools place designs (displacement, warp, shading, open-source examples)

### Takeaway
The standard recipe is: derive a displacement/height map from the (blurred, desaturated) garment photo, warp the artwork by it, then multiply/overlay the artwork with the shading layer and optionally add fabric texture and highlights. Open-source reference code exists but is thin; the one concrete GitHub project found only does placeholder detection, not fabric warping.

### Cited Findings
- Photoshop workflow: desaturate and blur the shirt layer, save as displacement map, apply Filter > Distort > Displace to the design; one guide suggests a 10-15 px blur and warns against heavy distortion — [Transfer Superstars guide](https://www.transfersuperstars.com/blogs/dtf-graphic-design/how-to-create-professional-t-shirt-mockups-in-photoshop-a-step-by-step-guide) (search summary).
- A browser/Fabric.js implementation: height map = luminance (BT.601 0.299/0.587/0.114) rescaled to 0-255 over opaque pixels, transparent pixels set to 128 (no displacement); offset = (h/255 - 0.5) x strength (example 45) on x and y, rotated by the design angle, source coords clamped, bilinear sampling; separate shade pass factor = 1 - (1 - shadeMap) x blendFactor (example 0.6) multiplied onto RGB, alpha kept; about 80 ms in modern browsers; disabled under 768 px width; recomputed on object:modified. The article's code has type mismatches and undefined variables as published — [DEV Community: Realistic fabric wrinkles in real time](https://dev.to/javedblch/realistic-fabric-wrinkles-in-real-time-building-displacement-maps-with-fabricjs-nch). Licence of that code: unverified (assume all rights reserved; use as a technique reference only).
- Open-source: CTDave001/automated_mockups is MIT licensed Python (Pillow, NumPy, scikit-image, OpenCV); it finds a solid-colour placeholder box in a template (position, size, rotation) and pastes designs there, batch-generating combinations; no fabric displacement described — [GitHub](https://github.com/CTDave001/automated_mockups).
- Mockover advertises automatic displacement-map generation (hosted product, not open source) — [Mockover blog](https://mockover.firebaseapp.com/blog/add-custom-designs-to-apparel) (search summary).
- Photoshop-community workflows apply displacement plus Screen/Linear Light for highlights on logos — [Adobe Community](https://community.adobe.com/t5/photoshop-ecosystem-discussions/white-artwork-on-a-t-shirt/m-p/10031377) (search summary).

### Inferences
- For Node: do displacement in OpenCV (`cv2.remap` with map_x = x + dx, map_y = y + dy from a blurred luminance map, INTER_LINEAR) or with raw-pixel loops after `sharp(...).raw()`; sharp has no displacement op in the docs fetched. For real time use a fragment shader (see Flutter section) sampling the design with uv + (h - 0.5) * strength * texelSize.
- Perspective/curvature (chest curve, sleeve, side views) is better handled by a per-view precomputed warp mesh or a UV map (R,G = u,v) stored as a PNG, which beats pure luminance displacement because luminance-based displacement moves the print only by fold brightness, not by body shape.

### Gaps
- Did not find a well-maintained open-source GitHub library implementing fabric-conforming mock-ups; Photopea/Krita specific tutorials with licences were not retrieved.
- No source on how Printful/Placeit/Printify internally render (they likely use PSD smart objects or 3D; unverified).

## Source assets: neutral base photos and licensing

### Takeaway
Unsplash/Pexels/Pixabay licences allow commercial use and modification, but each bars redistributing or selling photos unaltered / building a competing stock service; using the photos as bases inside an app that outputs heavily altered mock-ups is plausibly fine but borderline for serving the raw base images, and few stock tee photos are truly neutral. Paid mock-up PSD licences commonly forbid redistribution and are risky to embed in a SaaS; commission your own shoot/render or get written permission.

### Cited Findings
- Unsplash: free for commercial and non-commercial use, no permission, attribution appreciated; not allowed: selling images without significant modification, and compiling Unsplash images to replicate a similar or competing service. Trademark and people rights are not addressed on the page — [Unsplash License](https://unsplash.com/license). Third-party guides add that trademarks/logos/recognizable people are not cleared (unverified from primary) — [Pixsy guide](https://pixsy.com/image-licensing/unsplash-guide).
- Pexels: free, may edit, attribution not required; do not sell unaltered copies, do not redistribute on other stock/wallpaper sites, do not show identifiable people in a bad light, do not use as part of a trademark, do not imply endorsement — [Pexels License](https://www.pexels.com/license/).
- Pixabay: free use, modification allowed, attribution optional; cannot sell or distribute content standalone in substantially the same form; recognizable trademarks/logos cannot be used commercially on goods; no trademark use; AI/competing-service/API use not addressed in the summary, only the full terms are binding — [Pixabay Content License summary](https://pixabay.com/service/license-summary/).
- Mock-up PSD licences are vendor-specific. Common terms: no resale/sharing of the file; one vendor says including graphic resources in resalable web apps or software is distribution and prohibited; some tiers exclude app embedding — [search summary of Smartymockups FAQ and others](https://smartymockups.com/f-a-q/). Individual vendor terms were not fetched.

### Inferences
- Safest options: (1) own photo shoot of a plain grey/white tee on a mannequin or flat-lay with consistent lighting and a grey card, 4 views x each garment style; (2) render a neutral tee from a 3D model you own the licence to (Blender), which gives exact masks, UV/displacement and normal maps for free; (3) bought PSD packs only with written confirmation that SaaS/app embedding of derived images is allowed.
- Stock photos often have models, shadows on skin, labels or logos (trademark risk), and baked-in colour casts; neutral flat-lays are scarce, so budget for custom capture.
- Serving only the processed output (never the raw base file) reduces the "redistribution/standalone" risk, but that is a legal question to confirm with counsel.

### Gaps
- Did not retrieve the full Unsplash/Pixabay legal terms; specific SaaS-embedding clauses for Placeit, Smartmockups, Creative Market, etc. were not verified. Licence text can change; recheck at purchase.
- Not legal advice.

## Flutter specifics: BlendMode, FragmentProgram, web renderer caveats

### Takeaway
Flutter's BlendMode set covers multiply/overlay/softLight/hardLight/luminosity/color/modulate/srcATop/dstIn, enough to do mask x colour x shading with saveLayer, but only a fragment shader gives the gain+sheen dark-colour model and displacement in one pass. Web support for FragmentProgram could not be confirmed for skwasm and should be tested.

### Cited Findings
- modulate multiplies colour components only (alpha not multiplied; result same or darker); multiply multiplies colours and alpha (transparent in either input gives transparent); overlay favours the destination; hardLight favours the source; softLight is softer overlay; luminosity = source luminosity with destination hue/saturation; color = source hue/saturation with destination luminosity; srcATop draws source only where destination exists; dstIn uses source alpha as a mask — [Flutter BlendMode API](https://api.flutter.dev/flutter/dart-ui/BlendMode.html). The page gives no equations (see W3C formulas above).
- FragmentProgram: declare in pubspec `flutter: shaders:`; `FragmentProgram.fromAsset`, `program.fragmentShader()`; reuse the shader across frames; `setFloat`/`getUniformFloat` slots; `setImageSampler` for `sampler2D` (max one sampler type; clamp tile mode only); fragment shaders only, no vertex; use `FlutterFragCoord()`; output premultiplied RGBA; no UBO/SSBO, only `sampler2D`, only 2-argument `texture`; `ImageFilter.shader` Impeller-only; `drawImage` ignores `Paint.shader` (use `drawRect` with the shader) — [Flutter fragment shaders docs](https://docs.flutter.dev/ui/design/graphics/fragment-shaders).
- Web: the official shader page does not mention CanvasKit or skwasm. A 2026 third-party blog states that since Flutter 3.29 the HTML renderer is removed and dart2js output uses CanvasKit while dart2wasm uses skwasm — [startdebugging.net](https://startdebugging.net/de/2026/09/canvaskit-vs-skwasm-for-flutter-web-in-2026/) (secondary source, German). Old engine history: CanvasKit shader tests fixed Dec 2022 ([flutter/engine#37644](https://github.com/flutter/engine/pull/37644)); image shaders were once missing in CanvasKit ([flutter/flutter#84984](https://github.com/flutter/flutter/issues/84984)). Both are old.

### Inferences
- Without shaders (pure BlendMode) compositing plan: layer 1 garment-colour fill clipped by mask (dstIn / clipPath), layer 2 shading map drawn with BlendMode.multiply (shading stored as light-grey-to-white gain, not original photo), layer 3 highlight map with BlendMode.screen or plus for dark colours, layer 4 design drawn with srcATop/modulate against shading; wrap in saveLayer. BlendMode.modulate vs multiply: use modulate for opaque colour x shading where alpha must stay from the destination; multiply when you want transparent areas to stay transparent. This works on all renderers.
- Shader version: uniforms uColor (linear), uSheen; samplers uShade (S), uMask, uHighlight, uDesign; compute `out = C*S + (1-C)*E` in linear light (pow 2.2 approximation), warp design uv by shading-derived offset, mix with print opacity, output premultiplied. Keep to `sampler2D`, 2-arg texture.
- Fallback: server-side sharp/OpenCV rendering for the final export and for web builds where shader support fails; use BlendMode-only path as a live preview fallback.

### Gaps
- Current (2026) status of FragmentProgram on CanvasKit and especially skwasm was not confirmed from an official page; test on target browsers.
- Known per-backend differences in softLight/overlay on Skia vs Impeller were not found.

## Quality limits vs true 3D; four views, sizes, garment styles

### Takeaway
No source quantified this, so conclusions are engineering inferences: photo-based looks most real for a fixed pose per view, but cannot re-light, rotate, or re-fit to size/style; each (garment style x view x size) needs its own base photo plus mask/shading/displacement set, whereas 3D scales better.

### Cited Findings
- Displacement from luminance only approximates fold geometry; the Fabric.js author blurs the map to reduce noise and disables it on small screens — [DEV Community article](https://dev.to/javedblch/realistic-fabric-wrinkles-in-real-time-building-displacement-maps-with-fabricjs-nch).
- Mock-up tools show dark-garment vibrancy problems (see first section) — [Recraft feedback](https://feedback.recraft.ai/feature-requests/p/adjust-brightness-on-mockup-designs).

### Inferences
- Asset matrix: 4 views (front, back, left, right) x garment styles (crew, V, tank, long sleeve, hoodie...) x optionally sizes. Sizes: either reuse one base photo and scale the print area per size chart (cheap, slightly unreal), or shoot only S/M/L-representative bases. Each set = base photo, mask, S, H, optional UV/displacement. Store as WebP/PNG plus a JSON of print-area quad per view, so the business can add garments in the CMS like the existing garments API.
- Side views and sleeves need curved warps; a UV map or small mesh grid per view handles this better than luminance displacement.
- Colour accuracy: a mock-up is a simulation; record a per-garment tuning (gain, sheen) after comparing with physical samples.
- Limits vs 3D: fixed lighting, cannot spin, wrinkles are baked to one pose, text across seams/sleeves is approximate; 3D (Blender-rendered base passes: albedo-free shading, normal, UV) removes the photo-licence issue and gives all views from one model.

### Gaps
- No source comparing photo-based and 3D realism, nor cost data from print companies.
- Not found: how Printful, Printify, Placeit or Gelato implement their generators.
