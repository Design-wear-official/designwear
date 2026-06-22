# 05 · Project Structure

An annotated tour of the monorepo. Paths are relative to the repo root.

---

## Top level

```
designwear/
├── lib/                     # Flutter application source (see below)
├── designwear-backend/      # Next.js API + Sanity Studio (see below)
├── designwear-sdk/          # TypeScript SDK for the backend (git submodule)
├── packages/
│   └── flutter_sanity/      # Local Dart package: Sanity HTTP client
├── sanity/                  # Standalone Sanity schema definitions
│   └── schemas/             # categoryQuickLink, deal, designTemplate, homeBanner, index
├── assets/
│   ├── images/              # logo, tshirt mockups
│   └── system_prompt.txt    # DesignBot system prompt (loaded at runtime)
├── android/ ios/ web/       # Platform runners
├── windows/ macos/          # Desktop runners
├── docs/                    # ← this documentation
├── .github/                 # CI workflows
├── .env / .env.local / .env.example   # Environment config (gitignored secrets)
├── firebase.json / .firebaserc        # Firebase Hosting config
├── pubspec.yaml / pubspec.lock         # Flutter deps
├── analysis_options.yaml               # Lint rules
├── build_web.sh                        # Canonical web build script
├── README.md                           # Project README
└── LICENSE / SECURITY.md / CODE_OF_CONDUCT.md / CONTRIBUTING.md
```

---

## `lib/` — Flutter application

```
lib/
├── main.dart                # mainCommon(), Flavor enum, DesignWearApp (DI + MaterialApp)
├── main_internal.dart       # entry: mainCommon(Flavor.internal)
├── main_external.dart       # entry: mainCommon(Flavor.external)
├── firebase_options.dart    # FlutterFire-generated platform options
│
├── config/                  # Configuration (→ docs/04)
│   ├── config.dart          # barrel
│   ├── app_config.dart      # ConfigLoader + typed config classes
│   ├── app_constants.dart   # non-env constants
│   ├── app_routes.dart      # named route strings (AppRoutes)
│   └── flavor_config.dart   # active flavor singleton
│
├── models/                  # Pure data models (→ docs/06)
│   ├── models.dart          # barrel
│   ├── product.dart         # Product (+ community/remix fields)
│   ├── category.dart        # Category
│   ├── category_quick_link.dart
│   ├── cart.dart            # Cart, CartItem, Coupon
│   ├── custom_design.dart   # CustomDesign, DesignElement, DesignElementType
│   ├── order.dart           # Order, OrderItem, OrderStatus
│   ├── user.dart            # AppUser
│   ├── address.dart         # Address
│   ├── payment_method.dart  # PaymentMethod
│   ├── banner.dart          # HomeBanner
│   └── deal.dart            # Deal
│
├── domain/
│   └── usecases/
│       └── product_use_cases.dart   # Get{Products,Featured,Categories,ByCategory,ById,TaxRate}UseCase
│
├── data/
│   └── repositories/
│       ├── product_repository.dart       # abstract interface
│       └── product_repository_impl.dart  # wraps ApiService
│
├── services/                # Stateful logic (→ docs/07)
│   ├── services.dart        # barrel
│   ├── api_service.dart           # Web API ↔ Sanity hub, publishRemix()
│   ├── sanity_service.dart        # GROQ queries via flutter_sanity
│   ├── ai_agent_service.dart      # DesignBot + AI image generation
│   ├── virtual_tryon_service.dart # AI try-on
│   ├── auth_service.dart          # Firebase auth, Google, guest, FCM, profile
│   ├── cart_service.dart          # cart state + coupons + backend sync
│   ├── order_service.dart         # order create/list (backend)
│   ├── razorpay_service.dart      # payment + verification
│   ├── theme_provider.dart        # theme mode state
│   ├── logging_service.dart       # logging + route observer
│   ├── design_storage_service.dart    # persist saved designs
│   ├── design_history_service.dart    # undo/redo stack
│   ├── design_template_service.dart   # built-in & CMS templates
│   └── design_studio_demo_service.dart# demo responses
│
├── screens/                 # Feature screens (→ docs/08)
│   ├── home_screen.dart
│   ├── home/                # Home module (barrel: home.dart)
│   │   ├── home_app_bar.dart  home_sections.dart  home_feed_grid.dart
│   │   ├── home_challenge_banner.dart  home_settings_sheet.dart
│   │   └── home_constants.dart
│   ├── design_studio_screen.dart      # Studio host screen (remix-aware)
│   ├── design_studio/                 # Studio module (→ docs/10)
│   │   ├── design_studio.dart         # barrel
│   │   ├── design_canvas.dart  color_panel.dart  layers_panel.dart
│   │   ├── placement_panel.dart  templates_panel.dart  tools_panel.dart
│   │   ├── design_studio_constants.dart  design_studio_utils.dart
│   │   └── widgets/                   # tabs, editors, dialogs (barrel: widgets.dart)
│   ├── design_detail_screen.dart  saved_designs_screen.dart
│   ├── product_detail_screen.dart search_results_screen.dart
│   ├── cart_screen.dart  checkout_screen.dart
│   ├── my_orders_screen.dart
│   ├── virtual_tryon_screen.dart
│   ├── login_screen.dart  register_screen.dart  forgot_password_screen.dart
│   ├── profile_screen.dart  settings_screen.dart
│   └── shipping_addresses_screen.dart  payment_methods_screen.dart
│
└── presentation/            # Design system (→ docs/09)
    ├── styles/              # (barrel: styles.dart)
    │   ├── app_colors.dart  app_theme.dart  app_text_styles.dart
    │   ├── app_styles.dart  app_shadows.dart  app_dimensions.dart
    ├── widgets/             # (barrel: widgets.dart)
    │   ├── agent_chat_widget.dart  ai_image_attachment_widget.dart
    │   ├── garment_tile.dart  lineage_node.dart  safe_network_image.dart
    ├── patterns/
    │   └── responsive_typography_pattern.dart
    └── utils/
        └── responsive_utils.dart
```

### Barrel files
The project uses the **barrel pattern**: each module exposes one `*.dart` that
re-exports its files (`models.dart`, `services.dart`, `config.dart`,
`styles.dart`, `widgets.dart`, `home.dart`, `design_studio.dart`). Import the
barrel, not individual files. See
[flutter-barrel-imports.md](flutter-barrel-imports.md).

---

## `designwear-backend/` — Next.js + Sanity

```
designwear-backend/
├── app/
│   ├── api/                 # REST route handlers (→ docs/12)
│   │   ├── ai/{agent,generate-design,try-on}/route.ts
│   │   ├── auth/{login,register,google,guest,update,token,tokens,token/revoke}/route.ts
│   │   ├── products/route.ts        products/[id]/route.ts
│   │   ├── categories/route.ts      categories/[id]/products/route.ts
│   │   ├── cart/route.ts            cart/items/route.ts
│   │   ├── orders/route.ts          orders/[id]/route.ts  orders/[id]/status/route.ts
│   │   ├── payments/razorpay/{order,verify}/route.ts
│   │   ├── publish-remix/route.ts
│   │   ├── settings/tax-rate/route.ts
│   │   ├── sync/[action]/route.ts
│   │   ├── metrics/{database,performance}/route.ts
│   │   ├── operations/recent/route.ts
│   │   └── health/route.ts
│   ├── designwear-studio/[[...tool]]/page.tsx   # embedded Sanity Studio
│   ├── layout.tsx  page.tsx  global.css
│
├── sanity/
│   ├── schemaTypes/         # product, category, order, customer, deal,
│   │                        # designTemplate, homeBanner, categoryQuickLink,
│   │                        # supplier, inventoryMovement, systemLog,
│   │                        # notificationTemplate, index
│   ├── actions/{PublishAndSync.ts, ForceDelete.tsx}
│   ├── components/  widgets/  lib/  structure.ts  env.ts
│
├── lib/
│   ├── config/database.ts   # Firestore (Firebase Admin) client
│   ├── services/syncService.ts
│   ├── notifications.ts  utils/logger.ts  index.ts
│
├── shared/                  # workspace pkg: shared types (src/types.ts)
├── scripts/update_firebase_key.py
├── docs/{architecture.md, backend/backend_algorithms.md}
├── sanity.config.ts  sanity.cli.ts  next.config.ts  vercel.json
├── package.json  tsconfig.json  eslint.config.mjs
└── README.md  SECURITY.md
```

---

## `packages/flutter_sanity/`

A small local Dart package providing the Sanity client used by `SanityService`:

```
packages/flutter_sanity/
├── lib/
│   ├── flutter_sanity.dart      # public API
│   └── src/
│       ├── sanity_client.dart   # query client
│       ├── http_client.dart     # HTTP layer
│       └── exception.dart       # error types
└── pubspec.yaml
```

Wired as a **path dependency** in the root `pubspec.yaml`
(`flutter_sanity: { path: packages/flutter_sanity }`).

---

## Notable root files

| File | Purpose |
|------|---------|
| `build_web.sh` | Canonical web build (handles dart-defines / output dir) |
| `firebase.json`, `.firebaserc` | Firebase Hosting config |
| `analysis_options.yaml` | Lint rules (`flutter_lints`) |
| `.gitmodules` | Submodule definitions (`designwear-sdk`, vendored caches) |
| `designwear-731c9-firebase-adminsdk-*.json` | Firebase Admin service account (**gitignored / sensitive**) |
| `logs.txt`, `run_analyze.bat` | Dev convenience artifacts |
