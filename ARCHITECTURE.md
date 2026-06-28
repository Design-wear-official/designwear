# DesignWear — Architecture & Development Guide

The single reference for how DesignWear is built, how data flows, and how to run,
extend, and deploy it. Covers **both** the Flutter app and the Next.js backend.

> Companion docs: [`designwear-backend/docs/architecture.md`](designwear-backend/docs/architecture.md)
> (backend deep-dive) and [`designwear-backend/docs/inventory-sync.md`](designwear-backend/docs/inventory-sync.md)
> (inventory pipeline).

---

## 1. What DesignWear is

DesignWear is a **design-and-remix garment commerce platform**. Users browse and buy
garments, but they can also open a **Design Studio**, customize a garment (front + back),
and **publish** their creation as a community product others can buy or remix.

It is two deployables that talk over a REST API:

| Layer | Tech | Hosting | URL |
|---|---|---|---|
| **Frontend** | Flutter (web, Android, iOS, desktop) | Firebase Hosting (web) | the app |
| **Backend** | Next.js 16 (App Router) | Vercel | `https://designwear-backend.vishwamai.com` |
| **CMS** | Sanity Studio | Sanity-hosted | project `jh7llku7` / `production` |
| **Runtime DB** | Cloud Firestore | Firebase | project `designwear-731c9` |

```
 ┌──────────────┐     REST /api      ┌──────────────────┐   Admin SDK   ┌────────────┐
 │  Flutter app │ ─────────────────► │  Next.js backend │ ────────────► │  Firestore │
 │ (web/mobile) │ ◄───────────────── │   (Vercel)       │ ◄──────────── │  (runtime) │
 └──────────────┘     JSON            └──────────────────┘               └────────────┘
        │                                    ▲   │
        │ (some reads direct)                │   │ webhook on publish
        ▼                                    │   ▼
   ┌──────────────────────────────────────────────────┐
   │            Sanity CMS  (catalog source of truth)  │
   └──────────────────────────────────────────────────┘
```

**Two sources of data, on purpose:**
- **Sanity** = source of truth for the *catalog* (products, categories, garment templates). Admins edit here.
- **Firestore** = runtime store the app reads/writes at speed (products mirror, orders, carts, inventory, customers). Kept in sync from Sanity via webhook.

---

## 2. Frontend — Flutter app

### 2.1 Layered (clean) architecture

```
lib/
├── config/        app_config, flavor_config, app_routes, app_constants  (env + flavors)
├── models/        Product, Category, Order, Deal, …  (plain data classes)
├── data/          repositories/  → ProductRepository (+ Impl wrapping ApiService)
├── domain/        usecases/      → GetProducts, GetFeaturedProducts, GetCategories, …
├── services/      ApiService, SanityService, Garment/Cart/Auth/Order/Razorpay/AI, …
├── presentation/  styles (theme, colors), shared widgets
└── screens/       home/, design_studio/, design_detail, cart, checkout, virtual_tryon, …
```

- **State management:** `provider`. Repositories and use-cases are injected via `MultiProvider` in [`lib/main.dart`](lib/main.dart); `ChangeNotifier`s for `CartService`, `AuthService`, `ThemeProvider`.
- **Responsive:** `flutter_screenutil` + a `ResponsiveUtils`/`ResponsiveSizes` helper; max content width capped at 1440px.
- **Fonts/UI:** `google_fonts` (Archivo / Inter / Outfit), custom `AppColors` + `AppTheme` (light/dark).

### 2.2 Data access — two modes

`ApiService` ([`lib/services/api_service.dart`](lib/services/api_service.dart)) has two constructors:
- `ApiService.webApi(baseUrl)` — talks to the Next.js REST API (production default).
- `ApiService.sanity()` — talks to Sanity directly (used for some content reads).

Which one is active is decided by `WebApiConfig` in [`lib/config/app_config.dart`](lib/config/app_config.dart):
`USE_WEB_API=true` + `WEB_API_BASE_URL=https://designwear-backend.vishwamai.com/api`.
`ProductRepositoryImpl` wraps whichever `ApiService` is built and feeds the use-cases.

### 2.3 Key features / screens

| Area | Screens / files | Notes |
|---|---|---|
| Home feed | `screens/home/`, `home_sections.dart` | Featured row + product grid from live backend. Designed garments show a **remixable** chip + their canvas preview. |
| Design Studio | `screens/design_studio/` | Canvas customization (text, stickers, images, color), front/back sides, garment picker (from categories), templates, AI generate. Publishes via `publish-remix`. |
| Product detail | `screens/design_detail_screen.dart` | Shows the design preview, lineage, remixes; "Remix this design" CTA → Studio. |
| Cart / Checkout | `cart_service.dart`, checkout screens | Razorpay payment (web + mobile). |
| Virtual try-on | `virtual_tryon_service.dart`, `ai/try-on` | AI garment try-on. |

### 2.4 Firebase on the client
`firebase_core`, `firebase_crashlytics`, `firebase_messaging` (FCM). Web/desktop get
config from `firebase_options.dart` / env; mobile uses `google-services.json` /
`GoogleService-Info.plist`. See [`lib/main.dart`](lib/main.dart) for the platform-gated init.

---

## 3. Backend — Next.js (App Router)

All endpoints live under `designwear-backend/app/api/**/route.ts`.

| Group | Routes | Purpose |
|---|---|---|
| **Auth** | `auth/login`, `register`, `google`, `guest`, `token`(+`/revoke`,`/tokens`), `update` | JWT/session auth, guest sessions. |
| **Products** | `products`, `products/[id]` | Catalog read (from Firestore), create. |
| **Categories** | `categories`, `categories/[id]/products` | Category lists + per-category products. |
| **Garments** | `garments` | Garment **template** list for the Design Studio (CMS-driven, with fallback). |
| **Design** | `publish-remix` | Publishes a Studio design → Sanity + Firestore product (with preview images). |
| **Cart** | `cart`, `cart/items` | Server cart. |
| **Orders** | `orders`, `orders/[id]`, `orders/[id]/status` | Order lifecycle. |
| **Payments** | `payments/razorpay/order`, `payments/razorpay/verify` | Razorpay order creation + signature verification. |
| **Inventory** | `inventory/[action]` | `summary` / `list` / `backfill` / `adjust` — see §5.3. |
| **Sync** | `sync/[action]` | `webhook` / `trigger` / `status` — Sanity → Firestore. |
| **AI** | `ai/agent`, `ai/generate-design`, `ai/try-on` | Google GenAI features. |
| **Ops** | `health`, `metrics/database`, `metrics/performance`, `operations/recent`, `settings/tax-rate` | Health, metrics, config. |

**Server libs:** `lib/config/database.ts` (Firebase Admin init via `FIREBASE_SERVICE_ACCOUNT_KEY`),
`lib/services/syncService.ts` (Sanity→Firestore sync + inventory mirror), `lib/utils/logger.ts` (winston).

---

## 4. Content model (Sanity)

Schema types in `designwear-backend/sanity/schemaTypes/`:

| Type | Role |
|---|---|
| `product` | Catalog **and** community designs (studio fields: garmentType, garmentBaseColor, artText, creatorHandle, lineage, preview/backPreview images). |
| `category` | Shop categories; also drives the Studio garment picker. |
| `garmentTemplate` | **Blank** garment artwork (front/back) the Studio draws on — *not* a product. |
| `designTemplate` | Starter designs for the Studio. |
| `order`, `customer`, `supplier` | Commerce + people. |
| `inventoryMovement` | Stock-change audit type (also mirrored to Firestore — see §5.3). |
| `deal`, `homeBanner`, `categoryQuickLink` | Merchandising / home surfaces. |
| `notificationTemplate`, `systemLog` | Ops. |

Studio navigation is defined in `sanity/structure.ts`; publish flow uses `sanity/actions/PublishAndSync.ts`.

---

## 5. Data flow & key workflows

### 5.1 Catalog sync (Sanity → Firestore)
```
Admin publishes product in Sanity
        │  webhook
        ▼
POST /api/sync/webhook → syncProductToDatabase(id)
        ├─ upsert products/{id}            (catalog mirror: stock, images, price…)
        └─ upsert inventory/{id} + movement (stocked items only — §5.3)
```
`GET /api/sync/status` reports pending/failed/lastSync.
> **Requires** a Sanity webhook pointing at the deployed `/api/sync/webhook`.

### 5.2 Design publish (Studio → product)
```
Design Studio "Publish"
        │  POST /api/publish-remix  (front+back canvas PNGs, design JSON, creator)
        ▼
Sanity product (draft→published)  +  Firestore products/{id}
        └─ preview images uploaded to Sanity CDN; URLs stored for the app feed
```

### 5.3 Inventory (stock mirror + audit)
Two collections beyond `products`:
- `inventory/{productId}` — `stock`, `lowStockThreshold`, `status` (`inStock`/`lowStock`/`outOfStock`).
- `inventoryMovements/*` — append-only audit (`in`/`out`, qty, prev/new, reason, source).

Populated automatically on catalog sync (§5.1) and reconcilable via `POST /api/inventory/backfill`.
`POST /api/inventory/adjust` does a transactional stock change + movement (for sales/corrections).
**Only stocked catalog products are tracked** — community/print-on-demand designs (those with a
`creatorHandle`) are skipped. Full detail: [`inventory-sync.md`](designwear-backend/docs/inventory-sync.md).

### 5.4 Checkout
`payments/razorpay/order` creates a Razorpay order → client pays → `payments/razorpay/verify`
checks the signature → order persisted in Firestore `orders`. (Stripe references also exist in
historical orders.) **Not yet wired:** paid order → inventory decrement.

### 5.5 The two kinds of "product"
| | Catalog product | Designed garment |
|---|---|---|
| Created by | admin (Sanity) / `POST /products` | Design Studio → `publish-remix` |
| Signal | no `creatorHandle` | has `creatorHandle` (required) |
| Stock | tracked in inventory | print-on-demand, not stocked |

---

## 6. Firestore collections (runtime)

| Collection | Written by | Notes |
|---|---|---|
| `products` | sync + publish-remix | Catalog + community designs mirror. |
| `inventory` | inventory sync/backfill/adjust | Stocked catalog only. |
| `inventoryMovements` | inventory sync/adjust | Audit log. |
| `orders` | checkout | Razorpay/Stripe orders. |
| `carts` | cart API | Server carts. |
| `customers` | auth / customer sync | Profiles (mirrored to Sanity). |
| `operationLogs` | syncService | Sync op audit. |

---

## 7. AI assistant access (MCP)

[`.mcp.json`](.mcp.json) wires Claude to the backend stack for ops/automation:
- **sanity** — hosted remote MCP (`mcp.sanity.io`, OAuth) for CMS content.
- **firebase** — local `firebase experimental:mcp` (uses `firebase login` + `.firebaserc` project `designwear-731c9`) for Firestore.

This is the **on-demand ops console** (backfills, audits, "show low-stock"). It is *not* the
runtime automation path — always-on sync is the backend webhook (§5.1).

---

## 8. Development guide

### 8.1 Prerequisites
- Flutter SDK (stable), Dart
- Node.js 20+ and npm
- Firebase CLI (`firebase`), logged in
- Access to Sanity project `jh7llku7` and Firebase project `designwear-731c9`

### 8.2 Frontend (Flutter)
```bash
flutter pub get
# Web config is read from config/env.web.json (USE_WEB_API, WEB_API_BASE_URL, Firebase keys).
flutter run -d chrome                 # web dev
flutter run                           # mobile (device/emulator)
flutter analyze                       # lint
flutter build web --release           # production web bundle → build/web
```
Mobile/desktop read `.env` / `.env.local` (git-ignored); web reads `config/env.web.json`.

### 8.3 Backend (Next.js)
```bash
cd designwear-backend
npm ci --legacy-peer-deps             # MUST match package-lock (see §9 gotcha)
npm run dev                           # http://localhost:3000
npm run build                         # production build (what Vercel runs)
npm run lint
```
Required env (`.env.local`, never committed): `SANITY_API_TOKEN`,
`NEXT_PUBLIC_SANITY_PROJECT_ID`, `NEXT_PUBLIC_SANITY_DATASET`,
`FIREBASE_SERVICE_ACCOUNT_KEY` (full service-account JSON), payment keys.

### 8.4 Deployment
| Target | How | Notes |
|---|---|---|
| Backend | push to `master` → **Vercel** auto-deploy | Install = `npm ci --legacy-peer-deps`; build = `next build`. Env in Vercel + `vercel.json`. |
| Web app | `flutter build web` → **Firebase Hosting** (`firebase deploy`) | Serve `main.dart.js` with **no-cache** headers (see §9). |
| Sanity Studio | `npx sanity deploy` | Studio hosting. |

---

## 9. Gotchas / operational notes

- **`npm ci` lock sync (caused a multi-deploy outage):** changing `package.json`
  (e.g. removing an `overrides` entry) **requires** regenerating `package-lock.json`
  (`npm install`) and committing it. Vercel uses `npm ci`, which hard-fails on any
  mismatch (`Missing: undici@… from lock file`). Verify with
  `npm ci --legacy-peer-deps --dry-run` before pushing.
- **Web caching:** Firebase Hosting must serve the Flutter bundle with `no-cache`,
  or a long-cached `main.dart.js` makes deploys appear stale for a long time.
- **Navigation:** the app uses `MaterialPageRoute` (no named-route table) — push routes directly.
- **Garment templates need publishing:** the Studio falls back to a bundled blank
  until `garmentTemplate` docs are **published** with front/back images.
- **Sync webhook:** Sanity → Firestore auto-sync only runs if the Sanity webhook is
  configured to hit `/api/sync/webhook`.
- **Known open items:** paid order → inventory decrement is not wired (§5.4);
  `GET /api/sync/status` can 500 if the `operationLogs` composite index is missing;
  some historical orders reference deleted products and use inconsistent status values.

---

*Keep this file current when adding API routes, schema types, collections, or changing
the sync/deploy flow.*
