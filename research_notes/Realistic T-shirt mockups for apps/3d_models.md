# 3D T-shirt models for a custom-apparel app (free and cheap, commercially usable)

Method note: web tools worked, but WebFetch is a summariser and some pages returned 403 or partial text (Free3D 403; CGTrader free-model page returned nothing). I could not see UV layouts or renders directly, so no model below is verified as "realistic with print-ready front/back/sleeve UVs". Everything marked "unverified" must be opened in Blender before adoption. Researched 2026-11-08.

## Which free (CC0 / CC-BY) 3D T-shirt models exist that look genuinely realistic?

### Takeaway
There is no CC0 T-shirt on Sketchfab that I could find; the CC0 filter returned none for "t-shirt", "tshirt mockup" and only a Smithsonian historic "shirtwaist" (not a modern tee). Realistic free options are CC-BY (commercial use allowed with credit), mostly Marvelous Designer sims of 30k to 370k faces. Poly Haven, Quaternius, Kenney and Khronos were not confirmed to hold any T-shirt (see Gaps).

### Cited Findings
Sketchfab API queries (downloadable=true), licence read from the API model records:
- CC0 + "t-shirt": single hit, an unrelated aircraft "Short Tucano T.1" — [Sketchfab API](https://api.sketchfab.com/v3/search?type=models&q=t-shirt&downloadable=true&license=cc0&count=24)
- CC0 + "shirt": single hit, "shirtwaist" by Smithsonian Institution, 99,999 faces, CC0, 38 likes (historic garment, not a tee) — [Sketchfab API](https://api.sketchfab.com/v3/search?type=models&q=shirt&downloadable=true&license=cc0&count=24)
- CC0 + "tshirt mockup": zero results — [Sketchfab API](https://api.sketchfab.com/v3/search?type=models&q=tshirt+mockup&downloadable=true&license=cc0&count=24)
- CC-BY + "tshirt": 24+ results, listed in [this search](https://api.sketchfab.com/v3/search?type=models&q=tshirt&downloadable=true&license=by&count=24). Candidates whose record I read individually (all CC BY 4.0, downloadable):
  - "Tshirt" by Tabbuso, 373,280 faces, published 2020-09-28, tags marvelousdesigner/blender; author says "not perfect or optimized" — [model](https://sketchfab.com/3d-models/tshirt-5a21282b2e454d1696547148f617d3d0) ([API](https://api.sketchfab.com/v3/models/5a21282b2e454d1696547148f617d3d0)). 366 likes, the most popular in the list.
  - "TShirt Basic Marvelous" by NairoDraw, 30,088 faces, 2022-06-14, Marvelous Designer/CLO3D tags — [model](https://sketchfab.com/3d-models/tshirt-basic-marvelous-61ac2653467c4ac688a4a05af7844a55) ([API](https://api.sketchfab.com/v3/models/61ac2653467c4ac688a4a05af7844a55)). Best size/quality balance for a web viewer, but crew neck / UV not verified.
  - "Tshirt" by ajith98adithya, 46,313 faces, "Half Sleeve Men's Tshirt", 2018 — [model](https://sketchfab.com/3d-models/tshirt-8c838d3ea1e8494396438b5f5dc78ad8) ([API](https://api.sketchfab.com/v3/models/8c838d3ea1e8494396438b5f5dc78ad8)). 114 likes.
  - "Male Tshirt and Shorts - Plain Texture" by kanesk06, 332,334 faces, "high-poly mockup asset" (includes shorts, would need separating) — [model](https://sketchfab.com/3d-models/male-tshirt-and-shorts-plain-texture-06b9009696a64e1f87b5400ddbab1cdd).
  - "Women's Long Sleeve - Mockup Asset" by kanesk06, 18,450 faces / 9,503 vertices, 5 textures, 2 materials, blank texture with fabric pattern; long sleeve, so not a crew-neck short-sleeve tee — [model](https://sketchfab.com/3d-models/womens-long-sleeve-mockup-asset-98ffbaaebae14d00a9917fe9cb277b18).
  - Others in the list (not read individually, only face counts from search): ahmadriazi "tshirt" 75,269 faces (two copies), salman_ali 88,757, tshirt by aliabbas.827 21,983, 123muse "Tshirt model" 10,872 — see search link above. Several brand-named ones (Givenchy, Diesel, Gucci X North Face) should be avoided for trademark reasons.
- Sketchfab's CC0 "Yacine Brinis T-Shirt 3D Model Volume 01" is 4.9M triangles; licence, price and downloadability were NOT shown on the page — [model](https://sketchfab.com/3d-models/t-shirt-3d-model-volume-01-e22df292ca584df8aa18946375df6fdd). Far too heavy for web use anyway.
- CGTrader free listing "basic t shirt marvelous designer project file" is described in search results as free, with .zprj/OBJ/FBX; I could not read its licence page — [listing](https://cgtrader.com/free-3d-models/character/clothing/basic-t-shirt-marvelous-designer-project-file). Unverified.
- Poly Haven API model list: the first 100k characters (A to part of C) showed no clothing; assets are labelled "Free (CC0)". Rest unread — [API](https://api.polyhaven.com/assets?t=models&s=shirt).

### Inferences
- The "realistic cotton tee with folds, seams and collar rib" look is almost always a Marvelous Designer/CLO3D sim, which is why the CC-BY candidates are 30k to 370k faces with irregular topology. Folds baked into geometry fit a hanging/flat mock-up render but make projecting a print on clean UVs harder than on a purpose-built mock-up mesh.
- NairoDraw (30k faces) is the most practical free starting point for GLB delivery; Tabbuso (373k) would need decimation and normal-map baking.

### Gaps
- No CC0 realistic tee found. Free3D (403), Blend Swap, BlenderKit, Quaternius, Kenney, 3dassets.dev and Khronos glTF samples were not individually checked and I have no evidence either way.
- UV island layout (front/back/sleeves) not verified for any model; requires opening files.
- Sketchfab downloads need a free Sketchfab login; formats (glTF/USDZ source format) not verified per model.

## Which paid models (under about 50 USD) are good, and do their licences allow a commercial web/mobile app and mock-up renders?

### Takeaway
Cheap options exist ($3.70 to $4.79 found) but licence wording is the deciding factor. RenderHub's "Extended Use" explicitly allows commercial use; CGTrader's Royalty Free licence allows apps only if the model is an "Incorporated Product" that users cannot extract, which a raw GLB served to a browser arguably violates. The Sketchfab store is closed, so Sketchfab "Standard licence" models can no longer be bought.

### Cited Findings
- Sketchfab Store has closed; models can no longer be bought or sold; free downloads remain — [Sketchfab help](https://help.sketchfab.com/en/articles/16152225-store-license-usage-faq)
- RenderHub "T-Shirt Print 3D Model" (clothing-axis): $4.79 (was $7.99), 260,000 polygons / 210,000 vertices, formats .blend .dxf .fbx .glb .obj .zpac .zprj, UV mapped, 2048x2048 textures "non-overlapping and cleanly unwrapped", PBR materials. Licence: "Extended Use Licensing" meaning you "may use the model for both non-commercial and commercial purposes", with a separate 3D Content Licensing Agreement for full terms (not read). "Print Ready" is marked with a dash; the page offers no print-decal setup — [RenderHub](https://www.renderhub.com/clothing-axis/t-shirt-print)
- Same publisher's "T-Shirt with Print" and "T Shirt Print V2" exist (not read) — [one](https://www.renderhub.com/clothing-axis/t-shirt-with-print), [two](https://www.renderhub.com/clothing-axis/t-shirt-print-v2)
- Superhive (ex Blender Market) "T-Shirt Full Sleeve": page shows $3.70 "Commercial License" variant but structured data says $1.00; description says "licensed for non-commercial use"; the commercial variant text refers to a "Sleek Water Bottle 3D Model" (apparent copy-paste). Formats .blend, FBX, OBJ; polygon count unstated ("low-poly"). Licence contradictory, do not rely on it — [Superhive](https://superhivemarket.com/products/tshirt-full-sleeve-realistic-3d-clothing/docs)
- CGTrader Royalty Free licence, from its T&Cs (summarised by the fetch tool, short quotes verified): Incorporated Product is a "Product that cannot be extracted from an application or other product" and "used as a stand-alone object without the use of reverse engineering tools or techniques". Permitted: "as rendered still images or moving images"; "as Product published within a book, poster, t-shirt or other item"; "if the Product is contained inside a proprietary format and displays inside the game during play"; embedding in virtual worlds or platforms if users cannot download them in original form. Prohibited: "Products may not be sold, given, or assigned to another person or entity in the form it is downloaded"; "Any use or republication, including sale or distribution of Product that is not Incorporated Product"; software uses must take reasonable steps (proprietary formats, encryption) to stop end users accessing the Product — [CGTrader T&Cs](https://www.cgtrader.com/terms-and-conditions)
- CGTrader forum: a staff reply (undated, "a few years ago") says renders are permitted; one user answer on mock-up software only says "you should be ok" and quotes no wording — [forum thread](https://www.cgtrader.com/forum/general-discussions/does-royalty-free-license-allow-using-the-model-in-mockup-software)
- CGTrader listings seen (licence "Royalty Free", prices not read): [crew neck t shirt worn for men](https://www.cgtrader.com/3d-models/character/clothing/crew-neck-t-shirt-worn-for-men), [crew neck loose fit](https://www.cgtrader.com/3d-models/character/clothing/crew-neck-t-shirt-loose-fit), [classic emerald green blank t shirt mockup](https://www.cgtrader.com/3d-models/character/clothing/classic-emerald-green-blank-t-shirt-mockup). Not opened.
- Other listings found but unread: RenderHub [Oversized T Shirt](https://www.renderhub.com/urban-spacee/oversized-t-shirt), [Crew-Neck Color Block](https://www.renderhub.com/clothing-axis/men-crewneck-color-block-t-shirt), [Worn White T-Shirt](https://www.renderhub.com/khaloui/worn-white-t-shirt-realistic-game-ready-male-outfit), Gumroad [excelsioruniforms](https://excelsioruniforms.gumroad.com/l/tcdlsx) (search snippet: premium mock-ups from $29).

### Inferences
- A browser app serving a .glb is by nature extractable. Under CGTrader Royalty Free that is a likely breach unless encrypted/proprietary-packed; under RenderHub's Extended Use the full agreement (unread) must be checked for the same "no redistribution of the model file" clause. Server-side rendered mock-up images (model never shipped to the client) are the lowest-risk use under all of these licences.
- Rendering mock-up images is explicitly allowed under CGTrader ("rendered still images") and plausible elsewhere.

### Gaps
- RenderHub 3D Content Licensing Agreement and Extended Use text not read. Superhive's actual licence unclear. TurboSquid and Fab not checked. No CGTrader price or polygon count read.
- Sketchfab Standard licence wording not obtained (store closed).

## Do any have front/back/sleeve UV islands and a print/decal setup?

### Takeaway
No listing I read documents a decal or print setup. Several claim clean non-overlapping UVs, which is necessary but not sufficient.

### Cited Findings
- RenderHub T-Shirt Print: UV mapped, "non-overlapping and cleanly unwrapped" 2048 px UVs; "Print Ready" marked with a dash; no decal info — [RenderHub](https://www.renderhub.com/clothing-axis/t-shirt-print)
- Search snippets for a Free3D tee and a CGTrader basic tee claim non-overlapping UVs, one "UV unwrapped exactly according to paper cut pattern" (unpurchased, unread pages) — [Free3D t-shirt-9121](https://free3d.com/3d-model/t-shirt-9121.html), [CGTrader](https://www.cgtrader.com/3d-models/character/clothing/classic-emerald-green-blank-t-shirt-mockup)
- Marvelous Designer/CLO3D-sourced models (NairoDraw, Tabbuso) typically unwrap by pattern piece (front, back, sleeves, collar), which would give separate islands — this is an inference, not verified in the files.

### Inferences
- A pattern-piece UV (separate front/back/sleeve islands) suits per-side print layers directly. For arbitrary meshes, plan to re-unwrap in Blender or project decals via a second UV channel.

### Gaps
- No model verified to have separable front/back/sleeve islands; need to open in Blender.

## What attribution applies to CC-BY models?

### Takeaway
CC BY 4.0 allows commercial use if you give credit, link the licence, and flag changes. Mock-up images made from the model are likely adaptations, so credit should travel with them (e.g., in the app credits page).

### Cited Findings
- CC BY 4.0 attribution elements: creator name (and any other attribution parties supplied), copyright notice, licence notice, disclaimer notice, link to the material, link to the licence, and an indication if you modified the material. The credit may not suggest the licensor endorses you — [Creative Commons](https://creativecommons.org/licenses/by/4.0/)
- Sketchfab API describes each of the above models as CC BY 4.0 with "author must be credited, commercial use is allowed" (e.g., [Tabbuso model record](https://api.sketchfab.com/v3/models/5a21282b2e454d1696547148f617d3d0))

### Inferences
- Example credit: "T-shirt model 'TShirt Basic Marvelous' by NairoDraw, CC BY 4.0, https://sketchfab.com/3d-models/tshirt-basic-marvelous-61ac2653467c4ac688a4a05af7844a55, modified (retopologised, re-unwrapped)."

### Gaps
- Whether rendered mock-up images count as "Adapted Material" needing in-image credit was not researched; seek legal advice.
- Whether to credit in-app versus in image exports was not resolved.
