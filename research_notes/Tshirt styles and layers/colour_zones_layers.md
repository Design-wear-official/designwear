# Multi-zone / multi-layer garment colouring and construction (colour-blocking) in apparel customization tools

Legend: **[FETCHED]** = read directly from the page; **[SEARCH-SUMMARY]** = only seen in a web-search summary (not verified on the page); **[3P]** = third-party/non-official source. Researched Nov 2026 with limited tool access (several official pages returned 403/404 or were truncated).

## 1. Which products support per-part colouring, and how is the UI laid out?

### Takeaway
Mainstream print-on-demand (POD) tools I could verify mostly treat contrast parts as a *pre-made colourway SKU* (ringer, contrast raglan) rather than free per-part colouring; true per-part pickers appear in team-kit tools (Adidas miTeam), footwear (Nike By You), generic configurator plugins, and in cut-and-sew AOP where each panel is simply painted. I could not confirm per-part pickers for Custom Ink, Zazzle, Spreadshirt, Bonfire, Teemill, Teespring, Vistaprint, Gelato or Spring.

### Cited Findings
- Custom Ink Design Lab has a single "Product Colors" button that changes the colour of the current product; there is a separate "Change Product" link — [Custom Ink help: Navigate the lab](https://www.customink.com/help_center/navigate-the-lab) [SEARCH-SUMMARY]
- Custom Ink Canvas Ringer T is described as a "solid jersey body with contrast neck trim"; the page offers a note field for colour coordination requests; no separate sleeve/trim picker found — [Custom Ink Canvas Ringer T](https://www.customink.com/products/styles/canvas-ringer-t/124400) [SEARCH-SUMMARY]
- Custom Ink Augusta ringer: "contrast color sleeves and neckline"; HYP raglan: contrast V-notch, contrast sleeve stitching, contrast hem (all fixed in the listing) — [Augusta ringer](https://www.customink.com/products/t-shirts/short-sleeve-t-shirts/augusta-ringer-t-shirt/7100), [HYP raglan](https://www.customink.com/products/styles/hyp-short-sleeve-raglan/113700) [SEARCH-SUMMARY]
- Another vendor lists one ringer tee in 25 colour combinations, i.e. trim chosen as a combination, not independently — [search result, Augusta ringer listing](https://www.customink.com/products/t-shirts/short-sleeve-t-shirts/augusta-ringer-t-shirt/7100) [SEARCH-SUMMARY; the "25 combinations" attribution was not tied to a specific URL in the summary — treat as weak]
- Nike By You: customer picks a model, then assigns colour per part (upper, overlay, tongue, laces, lining, midsole, outsole etc.); available colours vary per model — [Nike By You](https://www.nike.com/Nike-by-you) (existence of flow) and 3P reviews e.g. [Dappered review](https://dappered.com/2023/01/in-review-nike-by-you-custom-blazer-mid-77-sneakers/) [SEARCH-SUMMARY, 3P]
- Adidas miTeam: take existing patterns and plug in team colours; reportedly body/sleeves/accents colours chosen; no source confirms independent collar/trim colours (collar and three-stripes appear fixed by template) — [Footy Headlines on mi Team 19 template](https://www.footyheadlines.com/2019/02/adidas-mi-team-19-football-kit-template.html), [Squad Locker](https://www.squadlocker.com/squad-blog/bid/348941/custom-adidas-and-under-armour-uniform-options) [SEARCH-SUMMARY, 3P, older]
- Zazzle: creator can allow/disallow buyer customisation at listing time (irreversible); design tool has "design areas" (Front/Back) switchable via a Layers panel; no per-garment-part colour picker found; "white" is ignored on classic print styles — [Zazzle help: Design Tool 101](https://help.zazzle.com/hc/en-us/articles/28090961110679-Zazzle-Design-Tool-101-Mobile-and-App-Version), [Product customisation explained](https://www.zazzle.ca/hc/article/product_customisation_on_zazzle_explained-219543148) [SEARCH-SUMMARY]
- Printful Design Maker: technique chosen per product (DTG, embroidery, cut & sew…); "thread colour" documented only for embroidery artwork, not for cut-and-sew sewing thread — [Printful help: How does the Design Maker work](https://help.printful.com/hc/en-us/articles/360014067779-How-does-the-Design-Maker-work) [SEARCH-SUMMARY]
- Printful AOP: PNG with transparent background lets the user "choose the print area color in the Design Maker"; i.e. per-panel background colour is a feature of AOP print areas — [Printful: Creating AOP file](https://www.printful.com/creating-aop-file) [FETCHED]
- Society6 template guide: to change sleeve/collar colour, fill that panel with a solid colour layer in the template — [Society6 blog](https://blog.society6.com/?p=34948) [SEARCH-SUMMARY, 3P]
- Art of Where (another POD) offers thread colour and zipper colour as seller-set product options — [Art of Where help](https://artofwhere.com/help/general-account/thread-zipper-color) [SEARCH-SUMMARY]
- A Fancy Product Designer pre-sale question asks whether customers can colour each sleeve, hood, pocket and chest individually, showing demand for a per-zone plugin feature (answer not retrieved; page 404 on fetch) — [FPD support thread](https://support.fancyproductdesigner.com/support/discussions/topics/13000023117) [SEARCH-SUMMARY]
- Bonfire: template feature changes artwork colours/fonts, not garment part colours; product pages list collar styles only — [Bonfire template blog](https://blog.bonfire.com/?p=16376) [SEARCH-SUMMARY]

### Inferences
- Pattern A "colourway SKU": ringer/contrast raglan = one variant per approved body+trim pair; UI exposes a colour swatch row whose swatches are pairs. (Inferred from Custom Ink listings having fixed trims.)
- Pattern B "part picker": list/tabs of parts (body, sleeves, collar…) -> swatch row for the selected part -> live preview; seen in Nike By You (verified at flow level) and probably miTeam.
- Pattern C "paint the panel": cut-and-sew AOP / Society6 where each template panel is just a coloured fill in the artwork file.
- Spreadshirt, Teemill, Teespring, Vistaprint, Gelato, Spring: nothing usable found.

### Gaps
- No direct fetch of Custom Ink designer UI, Spreadshirt, Teemill, Teespring/Spring, Vistaprint, Gelato help pages (search results gave no relevant content).
- Adidas miTeam current (2026) designer behaviour not confirmed; sources are 2019-era third-party.
- Nike By You official part list not verified from nike.com.

## 2. How is "layer" used (mockup layers, design layers, print-area layers); best-practice order and blend modes?

### Takeaway
Three distinct meanings: (1) mockup render stack — photo/base + colour + design + shading-on-top (Multiply ~50%); (2) design/artwork layers within a print area (z-order of user elements); (3) print-area/placeholder objects keyed by position (front/back/sleeve) in POD APIs. Shading should be kept as a neutral grayscale layer separate from colour so one asset recolours to any swatch.

### Cited Findings
- Customer's Canvas garment mockup: `Background` (product photo, white tee) -> smart-object `Design` placeholder sized to the print area -> `Texture` (copy of tee, blend **Multiply**, opacity **50%**) at top of stack; colour variants are a group `Color` containing one image per option value (White, Dark Red, Black), same size and print-area coordinates; mockup 1000x1000 px, 72 dpi RGB — [Customer's Canvas docs](http://customerscanvas.com/docs/hub/designers-manual/mockups/ps-mockups/preview-mockups/garment/) [FETCHED]
- Photoshop recolour recipe: colour layer clipped over tee set to Colour or Multiply, plus a tee copy at Multiply for shading; a GIMP tutorial uses Darken Only for the design (works on white, not black shirts); Recraft mockups offer Luminosity — [Adobe community thread](https://community.adobe.com/t5/photoshop-ecosystem-discussions/create-transparant-tshirt-image/m-p/12934922), [Logos By Nick](https://logosbynick.com/create-t-shirt-mockups-gimp/), [Recraft docs](https://www.recraft.ai/docs/recraft-studio/mockups/applying-your-design-to-a-mockup.md) [SEARCH-SUMMARY, 3P]
- Multiply results depend on what lies beneath, so a flattened transparent PNG can look different from the composite — [Adobe community](https://community.adobe.com/t5/photoshop/removing-all-color-from-an-image-besides-shadows/td-p/11089092?page=1) [SEARCH-SUMMARY]
- Printify create-product: `print_areas[]` each with `variant_ids[]` and `placeholders[]`; a placeholder has `position` (e.g. "front", "back"), `decoration_method` (e.g. "dtg") and `images[]`; product `images[]` are read-only mock-ups per variant+position — [Printify API docs](https://developers.printify.com/) [FETCHED, truncated; image position fields and `layers` not seen]
- Printify image placement uses normalised x, y, scale, angle (centre = 0.5, 0.5, scale 1) — [Polotno Printify guide](https://polotno.com/sdk/product/integrations/printify), [PrintiPy](https://pypi.org/project/printipy/0.0.3/) [SEARCH-SUMMARY, 3P]
- Printful API: printfile object has `printfile_id, width, height, dpi, fill_mode, can_rotate`; file position uses `area_width, area_height, width, height, top, left, limit_to_print_area`, origin top-left of print area; `limit_to_print_area=true` rejects out-of-area with 400; Mockup Generator endpoints: create task (POST), get printfiles, get task result, get layout templates; rate limit 2-10 req/min — [Printful developer docs](https://developers.printful.com/docs/) [FETCHED, first 100k of 590k chars only; "layers" not found]
- Printful embroidery is a separate placement family (`embroidery_front` etc.) with thread-colour options (manual/automatic/unlimited `full_color`), `embroidery_type` flat/3d/both — [Printful developer docs](https://developers.printful.com/docs/) [FETCHED]
- Zazzle: "design areas" (Front/Back) switched via a Layers panel — [Zazzle help](https://help.zazzle.com/hc/en-us/articles/28090961110679-Zazzle-Design-Tool-101-Mobile-and-App-Version) [SEARCH-SUMMARY]
- 3D approach: each garment part as its own mesh makes per-part recolour easy; Three.js DecalGeometry distorts on curved parts; common hybrid is Fabric.js 2D canvas used as a texture on a 3D model; UV mapping is the hard part — [three.js forum: 3D clothes configurator](https://discourse.threejs.org/t/3d-clothes-configurator/60156.md), [DEV: 3D T-shirt configurator](https://dev.to/apcliff/3d-tshirt-configurator-with-threejs-and-fabricjs-31j9), [three.js forum: sportswear configurator](https://discourse.threejs.org/t/sportswear-design-configurator/8792) [SEARCH-SUMMARY]

### Inferences
- Recommended 2D stack, bottom to top: (1) base/lining shadow (optional) -> (2) per-zone flat colour fills, each clipped to a zone alpha mask -> (3) seam/stitch lines and trims (cuffs, collar rib, buttons) as their own masks -> (4) user artwork clipped to the print area -> (5) shading/highlight/fabric texture layer set to Multiply (~50% per Customer's Canvas) on top; optional Screen/soft-light highlight layer. Basis: Customer's Canvas order + clipping-mask recolour threads; the exact ordering/zone-mask scheme is my synthesis, not documented by any POD vendor.
- Dark-garment problem: Multiply shading on a black fill collapses; use per-colour baked variants (Customer's Canvas "Color" group) or a luminosity-preserving blend for very dark colours.
- Data model implied by APIs: Garment -> Zones[] (id, mask, default colour, allowed palette) ; PrintAreas[] keyed by position -> Layers[] (artwork z-order) ; Variants map to zone colour assignments.

### Gaps
- Printful mockup generator "layers"/option_groups fields not confirmed from official docs (the "layers" array seen belongs to a different provider, Merchrocket).
- No vendor document specifying a canonical blend-mode order for colour-mask stacks beyond Customer's Canvas.
- CSS `mix-blend-mode` approach for web configurators not verified against a source.

## 3. Rules for disallowed combinations (sleeve colour on pocket tees, buttons tied to blank, etc.)

### Takeaway
I found no vendor documentation stating explicit combination rules. Evidence only shows that options are limited by product/blank: availability varies per model, trims are tied to blank SKUs, and customisation can be disabled.

### Cited Findings
- Nike By You colour choices vary by shoe model — [Nike By You](https://www.nike.com/Nike-by-you), [myshoesreview](https://myshoesreview.com/?p=4512) [SEARCH-SUMMARY, 3P]
- Ringer/raglan contrast parts are fixed per listed colourway — [Custom Ink Augusta ringer](https://www.customink.com/products/t-shirts/short-sleeve-t-shirts/augusta-ringer-t-shirt/7100) [SEARCH-SUMMARY]
- Custom Ink: different ink colours need at least six shirts per ink change — [Custom Ink help](https://customink.com:443/help_center/different-ink-color-on-some-shirts) [SEARCH-SUMMARY]
- Zazzle: creator-level toggle to disallow customisation, fixed at posting — [Zazzle help](https://www.zazzle.ca/hc/article/product_customisation_on_zazzle_explained-219543148) [SEARCH-SUMMARY]
- Printful AOP: sublimation works on light-coloured polyester/polymer-coated fabric (white is best) — [Printful AOP](https://www.printful.com/creating-aop-file) [FETCHED]
- Printful printfile `can_rotate`, `fill_mode`, and `limit_to_print_area` act as API-level placement constraints — [Printful docs](https://developers.printful.com/docs/) [FETCHED]

### Inferences
- A sensible rule engine (my design, not vendor-documented): zone existence is a property of the garment style (pocket zone exists only on pocket styles; sleeve-cuff zone only on long-sleeve; hood/placket only where the style has them); buttons/zip/drawcord are either "tied to blank" (a fixed option set per blank colour) or a small palette; disallow zone colours outside a per-zone palette; warn on low-contrast pairs (e.g. artwork vs. zone); raglan has no shoulder seam so "yoke/shoulder" zones are N/A; set-in sleeve vs. raglan changes the sleeve mask shape, not just colour.
- Pocket tees: a pocket zone should inherit body colour by default and be independent only if the vendor sews it from a separate panel.

### Gaps
- No documentation found on sleeve-on-pocket-tee or button-colour/blank constraints from any named platform.

## 4. How are cut-and-sew AOP panel templates specified (format, DPI, bleed)?

### Takeaway
Printful supplies per-product downloadable templates with guide layers and a safe area; artwork submitted as PNG/JPEG; exact DPI/bleed are given on each product's "File guidelines" tab (not on the generic page I could read). Third parties suggest 150 DPI minimum / 300 max and ~0.25-0.5 in extra bleed.

### Cited Findings
- Fabric is cut into "front, back, sleeves, and other relevant parts" and sewn in-house; prints go on sublimation paper heat-pressed to fabric; PNG or JPEG; use full-bleed art to cover the template; keep key artwork inside the safe print area away from seams; DPI is not given on the page (see File guidelines tab) — [Printful: Creating AOP file](https://www.printful.com/creating-aop-file) [FETCHED]
- Printful blog: print files at least 150 DPI, nothing gained above 300; templates have guide layers to remove before export; each product/print area has its own dimensions and DPI — [Printful blog: prepare print file](https://www.printful.com/blog/everything-you-need-to-know-to-prepare-the-perfect-printfile), [Printful help](https://help.printful.com/hc/en-us/articles/28491464259740-How-should-I-prepare-my-print-file-for-the-best-results) [SEARCH-SUMMARY; help page returned 403 on fetch]
- Printful recommends JPEG for full-coverage AOP, PNG when transparency is wanted — [Printful help](https://help.printful.com/hc/en-us/articles/28491464259740-How-should-I-prepare-my-print-file-for-the-best-results) [SEARCH-SUMMARY]
- Bleed = artwork extending beyond trim line to avoid unprinted edges (Printify); third party suggests 0.25-0.5 in beyond template edges — [Printify bleed guide](https://printify.com/knowledge-hub/file-prep-blueprint-for-bleeds/), [MerchTitans AOP guide](https://merchtitans.com/blog/all-over-print-t-shirts-guide) [SEARCH-SUMMARY, 3P]
- Third party claims AOP tee template ~6000x7200 px at 150 DPI, 200 MB limit — [topbubbleindex](https://www.topbubbleindex.com/blog/?p=4662) [SEARCH-SUMMARY, 3P, unverified]
- "Combo" template (all sizes in one file) mentioned for AOP — [SEARCH-SUMMARY only, source unclear]; provider templates differ (Printful vs. Gooten) — [MerchTitans](https://merchtitans.com/blog/all-over-print-t-shirts-guide) [SEARCH-SUMMARY, 3P]

### Inferences
- Treat a panel template as: named panels (front, back, left/right sleeve, collar, optionally pocket/hood) in one canvas with pixel dims at a stated DPI, guide layers (cut line, seam allowance/safe area, bleed) that are hidden at export. Implement as panel records {id, w_px, h_px, dpi, bleed_px, safe_inset_px, mask path} plus per-panel fill colour fallback (Printful's transparent-PNG -> Design Maker print-area colour behaviour supports this).
- Pocket and collar panels are typically small; mirror/rotation (`can_rotate`) must be respected when placing art across seams.

### Gaps
- Printful's official per-product AOP tee template spec (panel list, px sizes, DPI, bleed) not retrieved; official Printify/Gelato/Spring AOP specs not retrieved; collar/pocket panel presence in templates unconfirmed.
