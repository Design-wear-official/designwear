# Licensed and open mock-up generation APIs/services for realistic T-shirt mock-ups

All prices and facts "seen" on 2026-11-08 via WebSearch/WebFetch. Web tools worked, but several primary pages (Printful and Printify terms, Dynamic Mockups API reference) were truncated, returned 404, or did not state the relevant terms. Anything not verified is in the Gaps lists. Nothing was filled from memory.

## Which services have a public API that renders a customer's design onto a T-shirt?

### Takeaway
Only a few have a real, documented, self-serve mock-up API: Dynamic Mockups (generic PSD/smart-object renderer, free key, about $0.05-0.09 per render), Printful (catalog-bound, tied to their products), and Mediamodifier (pricey tier). Placeit has no public API. Smartmockups, Mockey, Gelato, Prodigi, Gooten, Pacdora and Canva could not be confirmed to have a usable mock-up-rendering API from what I found.

### Cited Findings
- Dynamic Mockups: render API is `POST https://app.dynamicmockups.com/api/v1/renders`, JSON, `x-api-key` header; the body takes `mockup_uuid` and a `smart_objects` array of `{uuid, asset.url}` (your design URL); the Mockup Library has "1000s" of mockups; samples in cURL/Node/Python/JS/PHP — [Dynamic Mockups docs](https://docs.dynamicmockups.com/)
- Dynamic Mockups claims "Our engine renders 750 mockups in about 60 seconds" and supports custom PSDs. This is a vendor marketing claim, unverified — [Dynamic Mockups blog](https://dynamicmockups.com/?p=58401)
- Placeit: "Placeit does not have a public API" (per competitor Dynamic Mockups, citing Placeit's help centre; the source has a commercial stake). Placeit reportedly hinted at a future API, none documented — [Dynamic Mockups on Placeit](https://dynamicmockups.com/?p=58401)
- Printful Mockup Generator API: asynchronous flow ("create a mockup generation task", then poll the task result). Endpoints listed: create mockup generation task, retrieve product variant printfiles, mockup task result, layout templates — [Printful API docs](https://developers.printful.com/docs/), [community SDK docs](https://printful-sdk-js.netlify.app/docs/store-level-client/mockup-generator)
- Printify: the developer docs (first 100k chars read) show no dedicated mock-up generation endpoint. Mock-up images appear as read-only `images` on products, which Printify generates. A third-party Swedish review site claims a REST "mockup generator API" exists, which I could not confirm — [Printify API docs](https://developers.printify.com/), [Printify mockup generator (dashboard tool)](https://printify.com/mockup-generator/)
- Gelato: "Mockup Studio" is a dashboard tool within Gelato+ / Gelato+ Gold plans; first template free. No mock-up-rendering API found. Gelato's API is for ordering/product connection — [Gelato Mockup Studio](https://gelato.com/mockup-generator)
- Prodigi: AI mock-up generator in the dashboard; Prodigi Pro unlimited, core accounts 15 free mock-ups for 2025. No mock-up API found — [Prodigi blog](https://www.prodigi.com/blog/ai-mockup-generator)
- Gooten: nothing found on mock-ups or an API in my searches (see Gaps).
- Smartmockups: help-centre page "Do you have API integration?" exists, but its text did not answer. Directs to hello@smartmockups.com — [Smartmockups help](https://smartmockups.helpscoutdocs.com/article/49-api)
- Mockey: nothing found either way.
- Pacdora: sources conflict. GetApp says no API; TechJockey lists an SDK/API to embed packaging and 3D mock-ups in websites. Pacdora's 3D t-shirt generator is free in the browser with PNG download (premium features paid) — [Pacdora 3D t-shirt tool](https://pacdora.com/tools/3d-t-shirt-mockup-generator), [TechJockey](https://www.techjockey.com/detail/pacdora)
- Canva Connect API: REST endpoints for Assets, Autofill, Brand templates, Designs, Exports, Folders, Merges, Resizes, Webhooks. Integrations public, or private on Canva Enterprise. It is a design/template API, not a photoreal garment mock-up renderer; a Canva help page says API access depends on subscription tier — [Canva Connect docs](https://canva.dev/docs/connect/), [Canva help](https://www.canva.com/es_419/help/canva-api/)
- Other mock-up APIs surfaced (via vendor/affiliate blogs, treat as unverified): MockupsJar (free for 100 API tasks, from EUR 45/mo above that), SudoMock ($0.002/render, directory listing), Mediamodifier — [Placeit-alternatives roundup](https://theapplaunchpad.com/blog/placeit-alternatives/), [Dynamic Mockups on Placeit alternatives](https://dynamicmockups.com/tools/placeit-alternatives/)

### Inferences
- For a "customer design -> photoreal tee on many colours" use case with no fulfilment tie-in, Dynamic Mockups (and secondarily Mediamodifier/MockupsJar/SudoMock) is the only category of true API found. Everything else is dashboard tools or fulfilment-bound.
- None of the API findings show native 3D/rotatable output. Rotation would be a set of pre-rendered angles (front/back/sleeve templates), not a live 3D view.

### Gaps
- Whether Dynamic Mockups has apparel templates covering front/back/sleeve with recolourable garments: docs page did not say.
- Gelato / Prodigi / Gooten API docs were not fetched directly; absence of a mock-up API is "not found," not "confirmed absent."
- Mockey and Smartmockups API status unconfirmed.
- Pacdora API existence unresolved.

## Pricing, free tiers and rate limits

### Takeaway
Dynamic Mockups: free plan (50 one-time credits, watermarked API renders), Pro $15/mo annual or $19/mo monthly with 3,600+ credits/year and top-ups at $0.051 per credit; 1 credit per API image. Printful and Printify mock-up APIs are free to call but rate limited and tied to their catalogs.

### Cited Findings
- Dynamic Mockups plans (seen 2026-11-08): Free $0, 50 one-time starter credits, 3 saved templates, limited integrations; Pro $15/mo billed annually or $19 monthly, 3,600 credits/year (tiers up to 12,000, 30,000, 60,000/yr), extra credits $0.051 each; Enterprise custom, from 5,000+ credits/month, white-label Product Customizer, SLA — [Dynamic Mockups pricing](https://dynamicmockups.com/pricing/)
- API credit use: "API render: 1 credit per image returned." Free API renders are watermarked; Pro gets clean exports. Pro credits expire at end of billing cycle. Rate limits not stated on the pricing page — [Dynamic Mockups pricing](https://dynamicmockups.com/pricing/)
- Conflicting/older Dynamic Mockups figures: a snapshot lists $49/month at $0.089/image with API; an xpay audit (May 2026) says no public paid pricing — [pricing snapshot](https://dynamicmockups.com/?p=3752), [xpay](https://www.xpay.sh/agent-ready-index/dynamic-mockups/). The pricing page itself is the more current source.
- Printful rate limits: general 120 requests/minute (30 unauthenticated); resource-intensive endpoints lower, mock-up task creation "2-10" per minute per the rate-limit table; read `X-RateLimit-*` headers; some accounts have higher agreed limits — [Printful API docs](https://developers.printful.com/docs/)
- Printify rate limits: 600 requests/minute global; Catalog endpoints 100/min per integration; product publishing 200 per 30 minutes; error responses must not exceed 5% of requests — [Printify API docs](https://developers.printify.com/)
- Mediamodifier mock-up API: one listing says $299/month for up to 5,000 renders, $0.06 per extra; another listing on the same site shows $499/month for the same allowance (dates unclear) — [Mediamodifier API](https://mockup-api.mediamodifier.com/) (via search snippet; direct fetch failed with "Socket is closed")
- Zakeke (customizer, not a pure mock-up API): conflicting prices — Shopify listing shows Starter $79.90 / Grow $149.90 / Scale $299.90 per month in one version and $19.90 / $59.90 / $149.90 in another; extra 1.7-1.9% transaction fee reported; Starter limited to 10 published products; 2D/3D/AR — [Shopify app](https://apps.shopify.com/zakeke-interactive-product-designer), [Digismoothie](https://www.digismoothie.com/cs/app/zakeke)
- Customily (personalisation, Shopify-centric): $49/month plus $0.10-$1 per order item on Shopify; per-product plans have a 12-product minimum ($96 Preview, $192 Preview + Print File); G2 says pricing not published — [Customily pricing](https://www.customily.com/pricing-other), [G2](https://www.g2.com/products/customily/pricing)
- Pacdora: third-party listings suggest roughly $29/month or $199/year, with another listing "from $9/mo"; unverified against Pacdora's own pricing page — [SourceForge listing via search](https://www.sourceforge.net/software/product/Pacdora)

### Inferences
- At hundreds to low thousands of renders/month, Dynamic Mockups Pro is the cheapest credible route: 3,600 credits/year is only ~300/month on the smallest tier, so ~1,000-2,000/month implies the 12,000 or 30,000 credits/year tiers or top-ups at $0.051 each (about $51 per 1,000 renders). Exact tier prices above $15/mo were not shown.
- Per-render cost multiplies quickly if each customer edit regenerates front + back + sleeves in many colours; caching or client-side compositing for colour changes is advisable.
- Printful's low mock-up task creation limit (2-10/min) makes it poor for interactive per-keystroke previews.

### Gaps
- Dynamic Mockups' real API rate limit (not on pricing or docs pages read; a separate FAQ is referenced).
- Exact prices of Pro tiers above the entry tier.
- Pacdora, Smartmockups, Mockey, Gooten, Prodigi API pricing: not found.
- Canva Connect pricing/tier requirements: not found.

## Image licence / usage terms and who owns the output

### Takeaway
I could not verify clear, favourable output-licence language for any service. The only terms page I read (Dynamic Mockups) is silent on generated mock-ups and contains a restrictive "personal, non-commercial use or internal business purpose" clause for its Content, so written confirmation is needed before embedding in a product.

### Cited Findings
- Dynamic Mockups ToS: Content is provided "for your personal, non-commercial use or internal business purpose only"; no part of Services or Content may be "exploited for any commercial purpose whatsoever, without our express prior written permission"; users retain "full ownership of all of your Contributions"; prohibits access "through automated or non-human means, whether through a bot, script or otherwise." The ToS does not mention the Render API, generated mock-ups, watermarks or embedding — [Dynamic Mockups ToS](https://dynamicmockups.com/terms-of-service/)
- Printify: "All integrations must comply with the Printify Terms and Printify API Terms"; the user-generated-content use case says you can place images on products, "offer them for purchase, and fulfill," but no explicit fulfilment requirement was visible — [Printify API docs](https://developers.printify.com/)
- Printful API terms: the two URLs I tried returned 404; the docs excerpt I read did not address mock-up image terms or fulfilment requirements — [Printful API docs](https://developers.printful.com/docs/)

### Inferences
- Printful and Printify mock-up APIs are designed around products you would sell via them, so using them as a pure renderer for another fulfiller is likely contrary to intent (not verified in terms text).
- Dynamic Mockups' licensing for API output is probably covered by separate API/commercial terms, but this needs a written answer from support@dynamicmockups.com (the address in the ToS).

### Gaps
- Printful API terms and mock-up image licence text; Printify API Terms text; Gelato/Prodigi/Gooten terms; Placeit licence (consumer licence, no API anyway); Pacdora, Zakeke, Customily output licensing. Not retrieved.

## Fulfilment dependency and lock-in

### Takeaway
Printful/Printify/Gelato/Prodigi mock-ups are products of their catalogs and print service; standalone renderers (Dynamic Mockups, Mediamodifier) have no fulfilment requirement visible, and open-source three.js avoids vendor lock-in entirely.

### Cited Findings
- Printful's mock-up API operates on catalog products and "product variant printfiles" (endpoint list), i.e. Printful's own garments/print areas — [Printful API docs](https://developers.printful.com/docs/)
- Gelato Mockup Studio is bundled with the paid Gelato+ subscription and covers Gelato's catalog; Teeinblue notes Gelato's mock-up images are taken from Gelato's website and you may need to upload your own — [Gelato Mockup Studio](https://gelato.com/mockup-generator), [Teeinblue](https://support.teeinblue.com/en/article/oexdrq/)
- Dynamic Mockups works from user-supplied PSD/smart-object templates or its library, without any print service — [Dynamic Mockups blog](https://dynamicmockups.com/?p=58401)
- Open source: R3F lists a T-shirt configurator example using @react-three/fiber and drei; the drei `Decal` component is the forum-recommended way to place designs on shirt meshes; 3DShirty (React Three Fiber, DALL-E art) is MIT-licensed; afilahkle/3D-Clothing-Configurator (Vite, React, R3F, logo placement) licence not confirmed — [R3F examples](https://docs.pmnd.rs/react-three-fiber/getting-started/examples), [three.js forum](https://discourse.threejs.org/t/best-way-to-render-images-text-on-model-textures-decals-etc/48608), [3DShirty](https://github.com/mahmudhmh/3DShirty-threejs-DALL.E), [afilahkle repo](https://github.com/afilahkle/3D-Clothing-Configurator)
- A three.js forum thread discusses how Redbubble-style mock-ups make the design follow fabric folds (displacement/normal map approach) — [three.js forum](https://discourse.threejs.org/t/how-does-redbubble-do-their-tshirt-mockups-the-design-follows-the-folds-of-the-tshirt/54859.md)

### Inferences
- Three.js/R3F (or Fabric.js/Konva with displacement/multiply shading on photographed blanks) is the only option that gives genuinely rotatable 3D and zero per-render cost, at the price of building/sourcing a licensed shirt model and shading. Fabric.js/Konva displacement-map approaches were not researched in this pass (see Gaps).
- A pragmatic hybrid: client-side compositing for live colour/design edits, plus an API (Dynamic Mockups) for final photoreal listing/share images, caching the outputs.

### Gaps
- Fabric.js/Konva displacement-map T-shirt examples and their licences: not searched.
- Licences of the 3D shirt models in the open-source repos; commercial usability of those models.
- Zakeke/Customily/Pacdora lock-in details (e.g. embedding SDK or white-label requirements): only Dynamic Mockups Enterprise mentions white-label Product Customizer; others unverified.

## Fit for a small startup (hundreds to thousands of renders/month)

### Takeaway
Viable on a startup budget: Dynamic Mockups (free to prototype, about $15-19/month entry, about $0.05/extra render), MockupsJar/SudoMock (unverified cheaper options), and self-built three.js/canvas. Not viable as a pure mock-up engine: Placeit (no API), Printful/Printify (tied to their catalogs, strict mock-up rate limits), Zakeke/Customily (full storefront customiser products with per-order fees), Mediamodifier at $299+/month.

### Cited Findings
- See pricing figures above (Dynamic Mockups pricing page; Mediamodifier; Zakeke; Customily).
- SudoMock "$0.002 per render" and MockupsJar "free for 100 API tasks, from EUR 45/month" are from vendor/affiliate roundups only — [Placeit-alternatives roundup](https://theapplaunchpad.com/blog/placeit-alternatives/)

### Inferences
- Recommended shortlist to verify next: (1) Dynamic Mockups via written confirmation of API-output commercial licence and rate limits; (2) self-built three.js/R3F rotatable preview for the in-app experience; (3) one backup API (MockupsJar or SudoMock) if licence terms for (1) disappoint.

### Gaps
- No hands-on test of render quality, apparel template coverage, or latency was done.
- Late-2026 comparison articles beyond vendor-authored ones were not found; most sources are competitor/affiliate blogs.
