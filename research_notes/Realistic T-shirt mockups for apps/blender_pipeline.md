# Scriptable Blender pipeline for realistic, colourable T-shirt mock-ups (headless, Blender 5.2)

Method note: web search/fetch worked this time, but results were thin in places (the Blender manual pages were too large for the fetch tool to summarise, and some searches returned no primary sources). Anything not sourced is placed under Inferences or Gaps. Two measurements were taken locally on the target machine (Blender 5.2.2 LTS snap, 12 CPU threads, 14 GB RAM, no GPU assumed) and are labelled "local test".

## Garment modelling and simulation: sewing-pattern tools, licences, workflow

### Takeaway
There is no free, mature "pattern pieces -> sew -> simulate" Blender add-on that is also scriptable out of the box. The credible options are: (a) a cheap GPL add-on (Easy Cloth, $19, has a pre-sewn shirt template), (b) a paid add-on (Garment Tool, Gumroad, $54+), or (c) skip pattern-sewing and model/sculpt the tee once by hand and drape it with Blender's built-in cloth. GarmentCode (MIT) generates parametric patterns programmatically but I found no Blender integration. Because the tee shape is modelled once and reused for every colour and print, a one-off manual or semi-manual step is fine.

### Cited Findings
- Easy Cloth (Superhive): licence GPL, $19, Blender 3.3 to 5.2, works with Cycles and EEVEE. Sidebar workflow is template -> sew -> pin -> collision -> simulate -> freeze. Shirt and dress templates come pre-sewn between front and back panels, but are starting points that still need fitting to the model. Sewing for custom patterns: select two edge chains, "Create Sewing", with a Max Force slider. — [Easy Cloth](https://superhivemarket.com/products/easy-cloth)
- Garment Tool: Blender 4.5+ add-on for designing garments from 2D Bezier-curve patterns, sewn then triangulated into a simulation-ready mesh. Sold on Gumroad for $54+ (not open source). Has a built-in Shirt preset plus Sleeve preset; "Edit Bend" wraps sleeves around arms; for clipping, set cloth Quality Steps above 15 and collision distance about 0.002 m. — [Garment Tool quick start](https://joseconseco.github.io/GarmentToolDocs/quick_guide); price/version via search result [Gumroad listing](https://bartoszstyperek.gumroad.com/l/GarmentTool?ref=311)
- Simply Cloth Studio: commercial, from $36, sewing system plus paid library of 200+ patterns; I saw no sign its source is open. — [Simply Cloth](https://superhivemarket.com/products/simply-cloth)
- GarmentCode (maria-korosteleva/GarmentCode): MIT licence, "Copyright (c) 2024 Maria Korosteleva", no extra restrictions beyond standard MIT. Python package `pygarment`. Repo page mentions JSON pattern classes and a warp-based data-generation guide plus an older Maya+Qualoth path; it does not mention Blender. — [LICENSE](https://github.com/maria-korosteleva/GarmentCode/blob/main/LICENSE), [repo](https://github.com/maria-korosteleva/GarmentCode)
- GarmentCode body-model caveat: due to SMPL licence restrictions only the average male/female SMPL bases are shared; other body-shape 3D models cannot be. Authors ask research use to cite the SIGGRAPH Asia 2023 paper. — [PyPI/search summary](https://pypi.org/project/pygarment/1.0.0.post1); [paper](https://arxiv.org/html/2306.03642v2)
- Seamly2D (Valentina fork): GPLv3+; project statements say users may use, sell, share and distribute patterns they make; trademarks of pattern systems still apply. Current export formats not confirmed (only a 2014 Valentina deck listing pdf/ps/eps/svg/png). — [Seamly FAQ](https://wiki.seamly.io/wiki/FAQ), [Seamly2D repo](https://github.com/FashionFreedom/Seamly2D)
- Marvelous Designer / CLO: exports OBJ/FBX usable in Blender. I found no primary statement of whether a garment you author and export may be used commercially; marketplace garment files carry the seller's own licence tiers. — [Versluis export guide](https://www.versluis.com/2015/03/how-to-export-a-garment-from-marvelous-designer/), [ArtStation listing](https://www.artstation.com/marketplace/p/P3ae9/dress-04-marvelous-designer-clo-project)
- Blender's own cloth Python API has what a script needs: `use_pin_cloth` with a pin vertex group, `use_sewing_springs` and `sewing_force_max`, `quality` (steps/frame), stiffness vertex groups, shrink factor (can be negative since 2019, with a vertex group), `use_pressure` with a pressure vertex group (inflates a closed mesh). Property names changed across versions; check 5.2. — [ClothSettings 5.2 API](https://docs.blender.org/api/5.2/bpy.types.ClothSettings.html), [pressure/shrink commit](https://projects.blender.org/archive/blender-archive/commit/541d0fdba61a9c99612f7532207d5ce704f10b43)
- Pin the shoulders/neck/arms with a weight-painted group so the shirt does not fall off the mannequin during simulation. — [Creative Bloq tutorial](https://www.creativebloq.com/3d/how-to-make-a-t-shirt-in-blender)
- Sculpt-and-drape alternative: fit a tee mesh over a mannequin with Elastic Deform, Inflate and Cloth sculpt brushes. — [Roblox docs](https://create.roblox.com/docs/art/accessories/creating/sculpting.md)
- Fitting caveat: draping a pattern onto a figure can distort the cut; Blender has no built-in way to hold edge lengths constant during fitting. — [Blender Artists thread](https://blenderartists.org/t/blender-for-garment-design/455992)
- Blender's licence covers the software and bpy scripts, not what you create: "What you create with Blender is your sole property"; scripts using the Python API must be GPL-compatible if published. — [blender.org licence](https://www.blender.org/about/license/)

### Inferences
- Recommended build: model a mannequin-fitted tee (front/back/sleeves with a neck hole and open hem/sleeve ends) once; run the cloth sim once (pin shoulders, collision with a mannequin torso), apply shape, add a little pressure/shrink for a "worn" or ghost-mannequin look; freeze the result as a static mesh. Rendering never needs to re-simulate, so the sim is a one-off authoring task, not a pipeline step. The simulation does not need to be scripted.
- Easy Cloth ($19, GPL) is the cheapest route to a pre-sewn shirt; as a Blender add-on it is GPL, which does not restrict the renders produced. A purchased add-on's licence terms for redistribution of generated meshes were not checked; confirm on the listing before shipping a mesh derived from template geometry.
- GarmentCode is attractive for parametric sizes (S-XXL) but needs a pattern -> 3D step outside Blender (warp sim or Qualoth), and its dependency on SMPL bodies adds a licence question for any non-average body. Treat as optional/stretch.
- For a lone tee shape, hand-modelling plus one sim is likely less total work than integrating a pattern generator.

### Gaps
- Marvelous Designer/CLO end-user licence on commercial use of exported garments: not found in a primary source.
- Seamly2D's current export formats (DXF?) not confirmed.
- GarmentCode's output formats and hardware requirements for the warp simulation not confirmed (docs page not read); no Blender import path found.
- Easy Cloth source repository and whether the add-on is scriptable from `blender -b` not verified.
- Licence status of the SMPL body for derivative garments not checked.

## Fabric shaders, textures, lighting

### Takeaway
Use Principled BSDF with Sheen Weight for the jersey fuzz, a CC0 jersey normal/roughness/AO set from Poly Haven, and a plain 3-light or HDRI studio setup with a soft backdrop. Poly Haven and ambientCG are both CC0 with commercial use and no attribution required.

### Cited Findings
- Poly Haven: all assets (HDRIs, textures, models) are CC0; commercial use, redistribution and bundling in sold products allowed; attribution not required. Only assets are CC0; site logos/user content/renders are not, and web scraping is prohibited without permission, so use the public API. — [Poly Haven licence](https://polyhaven.com/license)
- ambientCG: all assets CC0 1.0, commercial use allowed, raw files may be included in products, attribution optional. — [ambientCG licence](https://docs.ambientcg.com/license/)
- Poly Haven API (queried locally): the "stretchy" category lists Bi Stretch, Cotton Jersey (`cotton_jersey`), Jersey Melange (`jersey_melange`), Jogging Melange, Stretch Poplin, Terlenka; "cotton" lists Cotton Jersey, Waffle Pique Cotton, Rough Linen, Gingham Check and others. 43 assets in "fabric". — `https://api.polyhaven.com/assets?type=textures&c=stretchy` and `...&c=cotton` (local API queries on 2026-11-08)
- ambientCG API search for "knit" and "jersey" returned nothing; "fabric" returned Fabric018 ... Fabric086 style IDs (no jersey-specific confirmation). — local query of `https://ambientcg.com/api/v2/full_json`
- Blender glTF export: sheen is exported via KHR_materials_sheen since Blender 3.3, but Blender's Principled sheen model is "not compatible with the model used by glTF"; the documented workaround attaches a Velvet BSDF to the Principled BSDF (Color for sheen colour, Sigma for roughness), noted as temporary until Principled v2. — [Khronos blog](https://www.khronos.org/blog/blender-gltf-i-o-support-for-gltf-pbr-material-extensions)
- three.js MeshPhysicalMaterial has sheen, sheenRoughness, sheenColor (since r133). An old forum thread claims sheen response to environment light was incomplete; likely dated. — [search result summary](https://discourse.threejs.org/t/meshphysicalmaterial-s-sheen/31901)

### Inferences
- Jersey look = Cotton Jersey (or Jersey Melange) normal + roughness + AO tiled at real-world scale (knit loops are tiny: tile ~3-5x denser than the UV default), Sheen Weight about 0.3-0.6 with low Tint, roughness about 0.8-0.9, subtle Fuzz via a thin sheen layer. These numeric values are my suggestions, not sourced; tune by eye.
- Lighting: large soft key + fill + rim, or one neutral studio HDRI (Poly Haven) with a shadow-catcher or white cyclorama. Use Filmic/AgX ("Standard" view transform keeps colours predictable for a colour-accuracy-critical product) — choose Standard so a requested hex colour comes out near that hex.

### Gaps
- Blender 5.2 manual pages for Sheen BSDF/Principled BSDF could not be summarised (the fetch tool returned only navigation), so exact node inputs in 5.2 are unverified from docs. The local benchmark did set `Sheen Weight` successfully on the 5.2.2 Principled BSDF.
- Exact ambientCG jersey/knit asset not found; Poly Haven Cotton Jersey is the confirmed candidate.
- No source on the best fuzz/micro-fibre technique (e.g. hair particles/curves) for tees; likely unnecessary at web resolution.

## Colourable base and print projection; headless batch renders; CPU vs GPU timing

### Takeaway
Drive colour and print with node inputs set from Python per render (base-colour RGB node, print as an image texture on the garment's UV with alpha), so the print follows folds exactly. On this 12-thread no-GPU machine a 800x800 Cycles CPU render with denoising was ~8 s (simple scene); EEVEE also ran headless here at ~8.6 s. A full garment will be slower.

### Cited Findings
- Local test (Blender 5.2.2 snap, `blender -b -P`, 12 threads, no GPU): 800x800 UV sphere (128x64 segments), Principled with Sheen, one area light: Cycles CPU, 64 samples + denoising: 8.3 s wall for the render call; EEVEE (`BLENDER_EEVEE`): 8.6 s, worked without a display. This was a trivial scene, not a garment benchmark. — local test script, 2026-11-08
- EEVEE has historically needed OpenGL; headless setups use Xvfb with Mesa software GL, which can be slow; one user reported 50 s vs 2 s. A (vendor-blog) claim says EEVEE-Next is stricter about display contexts; unverified. — [devtalk thread](https://devtalk.blender.org/t/blender-2-8-unable-to-open-a-display-by-the-rendering-on-the-background-eevee/1436), [iRender blog](https://irendering.net/eevee-next-headless-dilemma-cloud-render-farm-guide/)
- Cycles denoising needs an OpenImageDenoise-enabled build; a low-sample denoised render usually beats high samples for cost (vendor claim). — [nixpkgs commit](https://git.uninsane.org/colin/nixpkgs/commit/0c101e7a04f04ee97aa273f59a67284322d6f535), [Renderjuice](https://www.development.renderjuice.com/blog/how-to-render-faster-in-blender)
- Multiply tint approach: white/grey albedo times a colour keeps texture light/dark detail; clamp inputs, since values above 1 make Multiply brighten. — [Blender bug #89386](https://developer.blender.org/T89386), [Blender Artists](https://blenderartists.org/t/cycles-combining-bright-dark-color-values-in-a-material/694950)

### Inferences
- Node graph: `Mix(Multiply)` of a (near-white, luminance-only) cotton albedo with an RGB colour node drives Principled Base Color; print = second Mix with print RGBA (factor = print alpha) using a UV-mapped Image Texture. Python sets `colour_node.outputs[0].default_value` and `image.filepath` per request, so the print follows folds because it sits in the shader on the deformed mesh. For print, use a dedicated non-overlapping garment UV layout (front, back, sleeves each with their own island) and a decal-free texture approach; Poly Haven-style tiling for fabric uses a second UV map or Generated/Object coordinates.
- Colour accuracy: render a white garment under neutral light, check how a requested sRGB hex maps (Standard view transform), and correct with a per-colour gain if needed.
- Cycles CPU, 800-1200 px, 32-128 samples + OIDN is plausible at roughly 5-60 s per view for a garment (extrapolated from the sphere test, unverified). Four views x N colours x M prints becomes minutes per request; this is the argument for hybrid compositing below.
- CPU-only means Cycles is the safe engine; EEVEE worked in the local test but with software GL it is not clearly faster, and Cycles gives better cloth sheen/AO/soft shadow.

### Gaps
- No primary benchmarks for garment-scene render times; only the simple local test.
- Decal/projection add-ons not researched; UV-based print is sufficient for flat front/back placement.
- Whether EEVEE keeps working headless on other servers (no Xvfb) not tested beyond this machine.

## Effort estimate and hybrid compositing

### Takeaway
No source gives effort figures; estimates are my judgment. Hybrid compositing (render neutral shading/AO/displacement passes once, tint and print per request in Node/sharp) is much cheaper per request but cannot fully match shader-driven results (sheen, print on folds follows only via the displacement/UV pass).

### Cited Findings
- sharp supports composite blend modes including `multiply`, `screen`, `overlay`, `darken`, `lighten`, `over`, per layer; layers must be same size or smaller. `tint` is a separate whole-image recolour with no blend mode. — [sharp types/composite listing](https://tessl.io/registry/tessl/npm-sharp/0.34.0/files)

### Inferences
- Estimated effort (my judgment, unsourced): competent Blender artist, 2-4 days for mannequin tee + cloth sim + UV for print + materials + lighting + four-camera script + CLI; beginner, 2-4 weeks. A pre-sewn add-on shortens modelling, not UVs/lighting/QA.
- Hybrid recipe: from Blender render once per view (a) a grayscale shaded beauty of a white garment, (b) a flat ID/alpha mask, (c) a UV or normal pass to warp the print. Then sharp: `multiply` the colour onto (a), composite print warped by the UV pass (warp needs custom per-pixel remapping; sharp has no built-in UV displacement, so a small Node or WASM remap or a precomputed displacement map is needed). Caveat: multiply on a white garment fails for black/saturated colours (shading is lost on very dark colours) and sheen/specular colour does not tint correctly; fix by also storing a separate spec/sheen pass added with `screen`/`add`. Direct render per colour (Cycles) gives the best look but cost grows linearly with colours x prints x views.
- A pragmatic mix: pre-render a fixed palette of colours directly in Blender (4 views each, offline), and use the hybrid composite only for custom print and any colour outside the palette. Choice depends on how many colours the product offers, which was not given.
- Print-on-fold fidelity is the main quality risk in the hybrid; solving it with a UV pass render at 16-bit/float EXR and sampling the print through it is feasible in Node (e.g. with a per-pixel loop), a small custom piece of work.

### Gaps
- No sources on effort, on quality comparison of hybrid versus full renders, or on existing open-source UV-remap compositing in Node/sharp.

## Export for web 3D viewers (glTF)

### Takeaway
glTF export from Blender is straightforward for a single static tee with baked textures, but the sheen path needs the Velvet-BSDF workaround and viewer sheen support has to be tested; expect flatter fabric than Cycles renders. For this product, pre-rendered images are likely higher quality than a live 3D viewer.

### Cited Findings
- Blender glTF I/O supports KHR_materials_sheen, emissive_strength, transmission, ior, volume, specular, variants (since 3.3), with sheen mapped via a Velvet BSDF workaround. — [Khronos blog](https://www.khronos.org/blog/blender-gltf-i-o-support-for-gltf-pbr-material-extensions)
- glTF Transform lists KHR_materials_sheen (colour factor etc.) as an extension attachable to any material; viewer support not documented there. — [glTF Transform](https://gltf-transform.dev/modules/extensions/classes/KHRMaterialsSheen)
- model-viewer 4.2.0 source has a KHR_materials_sheen section (sheenColorFactor getter reading the three.js material); the full state of sheen rendering in model-viewer is not confirmed. A Khronos sample asset SheenTestGrid exists for checking. — [model-viewer material.js](https://app.unpkg.com/@google/model-viewer@4.2.0/files/lib/features/scene-graph/material.js), [SheenTestGrid](https://asset-explorer.needle.tools/SheenTestGrid)
- three.js MeshPhysicalMaterial supports sheen, sheenRoughness, sheenColor. — [three.js forum summary](https://discourse.threejs.org/t/meshphysicalmaterial-s-sheen/31901)

### Inferences
- Bake: use Cycles bake to produce base-colour (print composited, or print as a separate texture), normal, roughness/AO; keep texture in a layout with one print island. For recolouring in-browser, change `baseColorFactor` on a white albedo (glTF multiplies factor by texture), which is a cheap live colour switch; print can be a second UV set texture swapped at runtime in model-viewer/three.js.
- Quality limits: no Cycles soft-shadow/AO inter-reflection unless baked into AO/lightmap; sheen is approximated; cloth folds are baked into the mesh (fine). Mesh size 20-60k tris keeps load small. Flutter packages (e.g. `model_viewer_plus`, which wraps model-viewer in a WebView) were not researched.

### Gaps
- No research done on Flutter 3D packages (`model_viewer_plus`, `flutter_3d_controller`, etc.) or their sheen/texture-swap support.
- Current model-viewer sheen rendering correctness and KHR_texture_transform/second-UV swapping not verified.
- File-size and load-time numbers not found.
