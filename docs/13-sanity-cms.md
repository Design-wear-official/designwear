# 13 · Sanity CMS

Sanity is DesignWear's content backbone. It stores the product catalog and the
home-screen content (banners, deals, quick-links, design templates), and is the
**always-available** read source the app falls back to when the Web API is off
or empty (see [Architecture](03-architecture.md)).

There are **two** places Sanity appears:

| Location | Role |
|----------|------|
| [`designwear-backend/sanity/`](../designwear-backend/sanity) | The full Studio + schemas (deployed with the backend at `/designwear-studio`) |
| [`sanity/schemas/`](../sanity) (repo root) | Standalone schema definitions for the Flutter-facing content types |
| [`packages/flutter_sanity/`](../packages/flutter_sanity) | The Dart client the app uses to query Sanity |

> **Public project id:** `jh7llku7`, dataset `production` (defaults in
> `SanityConfig` and `.env.local.example`). The project id is public by design.

---

## Schema types

Registered in
[`sanity/schemaTypes/index.ts`](../designwear-backend/sanity/schemaTypes/index.ts):

| Group | Type | Used by |
|-------|------|---------|
| **Catalog** | `product` | `Product` model, home/search/product screens |
| | `category` | `Category` model |
| **Transactions** | `order` | Order→Sanity sync after payment |
| | `customer` | Created/updated during order sync |
| | `inventoryMovement` | Stock tracking (ops) |
| **Operations** | `supplier` | Supplier records |
| | `systemLog` | System logging |
| | `notificationTemplate` | Push/notification templates |
| **Content (Flutter home)** | `homeBanner` | `HomeBanner` model |
| | `deal` | `Deal` model |
| | `designTemplate` | `DesignTemplate` (Design Studio) |
| | `categoryQuickLink` | `CategoryQuickLink` model |

### `product` schema (field groups)
[`product.ts`](../designwear-backend/sanity/schemaTypes/product.ts) organizes
fields into groups: **Basic Info** (`name`, `slug`, `description`, `category`
ref, `tags`, `sku`), **Pricing & Stock**, **Media & Variants** (images, sizes,
colors), **Design Studio** (`garmentType`, etc.), **Community & Lineage**
(`creatorName`, `creatorHandle`, `garmentBaseColor`, `artText`,
`remixedFrom*`, `likeCount`, `remixCount`, `lineage[]`), and **Metadata**.

> **Schema ↔ model mapping:** the Sanity schema uses **`name`** while the Flutter
> `Product` uses **`title`**. `SanityService._productProjection` bridges this with
> `coalesce(title, name)`, `slug.current`, `garmentType → productType`, and asset
> URL resolution. See [Services & State](07-services-and-state.md).

---

## How the app queries Sanity

[`SanityService`](../lib/services/sanity_service.dart) uses the local
`flutter_sanity` `SanityClient` (`useCdn: true`) and a shared GROQ projection.
Example:

```groq
*[_type == "product"] | order(_updatedAt desc) {
  _id,
  "title": coalesce(title, name),
  "slug": slug.current,
  description, price, featured, tags,
  "imageUrl": coalesce(image.asset->url, images[0].asset->url),
  "images": images[].asset->url,
  category, stock,
  "availableSizes": sizes,
  "availableColors": colors,
  "productType": garmentType,
  creatorName, creatorHandle, creatorFollowers,
  garmentBaseColor, artText, remixedFromHandle, remixedFromVersion,
  likeCount, remixCount,
  "lineage": lineage[]{handle, version, baseColor, artText}
}
```

Methods: `fetchProducts`, `fetchFeaturedProducts` (falls back to first 6),
`fetchProductsByCategory`, `fetchCategories`, `fetchTaxRate`, `fetchBanners`,
`fetchDeals`, `fetchCategoryQuickLinks`, `fetchDesignTemplates`.

---

## The `flutter_sanity` package

[`packages/flutter_sanity/`](../packages/flutter_sanity) — a small Dart client:

```
lib/
├── flutter_sanity.dart      # public: SanityClient
└── src/
    ├── sanity_client.dart   # fetch(query) → decoded JSON
    ├── http_client.dart     # HTTP transport
    └── exception.dart       # SanityException
```

`SanityClient(projectId, dataset, useCdn)` exposes `fetch(groqQuery)`. Wired as a
path dependency in the root `pubspec.yaml`.

---

## Studio (content editing)

The Sanity Studio is embedded in the backend at
[`app/designwear-studio/[[...tool]]/page.tsx`](../designwear-backend/app/designwear-studio/[[...tool]]/page.tsx)
and configured by
[`sanity.config.ts`](../designwear-backend/sanity.config.ts). It includes custom
**actions** (`PublishAndSync`, `ForceDelete`), **components**
(`PriceWithTaxInput`, `StudioLogo`), and dashboard **widgets** (database status,
performance metrics, recent operations, sync status).

Run it locally with the backend (`npm run dev` → `/designwear-studio`).

---

## Order → Sanity sync

After a verified payment, `/payments/razorpay/verify`:
1. `createIfNotExists` a `customer` document (aggregates `totalOrders`,
   `totalSpent`),
2. creates an `order` document with mapped items (weak product references),
   shipping address, and `status: processing` / `paymentStatus: paid`.

This requires `SANITY_API_TOKEN` on the backend; if it's missing the sync is
skipped (the payment still succeeds). See
[Backend & API Reference](12-backend-and-api.md).

---

## Working with Sanity content

- **Add/edit catalog & content:** use the Studio at `/designwear-studio`.
- **Publish a remix from the app:** Design Studio → Publish → `/publish-remix`
  writes a `product` doc and syncs to Firebase.
- **Home content fallbacks:** if banners/deals/quick-links aren't published yet,
  the app renders hard-coded fallbacks (`HomeBanner.fallbacks`, `Deal.fallbacks`)
  so the home screen is never empty. See [Data Models](06-data-models.md).
