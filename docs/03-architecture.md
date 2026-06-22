# 03 · Architecture

DesignWear follows a **layered / clean architecture** on the Flutter side, with a
swappable data source (Next.js backend **or** Sanity CMS directly) behind a
repository abstraction.

---

## High-level system

```
            ┌────────────────────────────────────────────────┐
            │                  Flutter client                 │
            │                                                 │
  UI  ──────│  presentation/ (styles, widgets, utils)         │
            │        │                                        │
  Screens ──│  screens/ (StatefulWidgets, Consumer<...>)      │
            │        │ reads via Provider                     │
  State ────│  services/ (ChangeNotifier + singletons)        │
            │        │                                        │
  Domain ───│  domain/usecases/ (callable business rules)     │
            │        │                                        │
  Data ─────│  data/repositories/ (interface + impl)          │
            │        │                                        │
  IO ───────│  api_service ──┬── Web API (http)               │
            │                └── SanityService (flutter_sanity)│
            └────────────────┼───────────────┼───────────────┘
                             │               │
                   Next.js backend      Sanity CMS (CDN)
                   (Firestore, Razorpay, Gemini)
```

The **golden rule**: dependencies point inward. Screens depend on services and
use cases; use cases depend on repository *interfaces*; the repository *impl*
depends on `ApiService`. Nothing inner imports Flutter widgets — models are pure
Dart.

---

## Layers

### 1. `presentation/` — Design system & reusable UI
Pure visuals and helpers: colors, text styles, theme, dimensions, shadows,
responsive utilities, and shared widgets (e.g. `SafeNetworkImage`,
`GarmentTile`, `AgentChatWidget`). No business logic.
→ [Design System](09-design-system.md)

### 2. `screens/` — Feature screens
`StatefulWidget`/`StatelessWidget` screens that compose widgets and read state
via `Provider`. Larger screens (Home, Design Studio) are split into a folder with
a **barrel file** (`home.dart`, `design_studio.dart`).
→ [Screens & Navigation](08-screens-and-navigation.md)

### 3. `services/` — Stateful application logic
Two flavors:
- **`ChangeNotifier`** services registered with Provider (`CartService`,
  `AuthService`, `ThemeProvider`) — they `notifyListeners()` and rebuild widgets.
- **Plain/singleton** services instantiated where needed (`ApiService`,
  `AIAgentService`, `OrderService`, `RazorpayService`, `VirtualTryOnService`,
  `SanityService`, `DesignHistoryService`, `DesignStorageService`,
  `DesignTemplateService`, `LoggingService`).
→ [Services & State](07-services-and-state.md)

### 4. `domain/usecases/` — Business rules
Single-responsibility **callable classes** (`call()` operator) wrapping one
repository operation: `GetProductsUseCase`, `GetFeaturedProductsUseCase`,
`GetCategoriesUseCase`, `GetProductsByCategoryUseCase`, `GetProductByIdUseCase`,
`GetTaxRateUseCase`. They keep screens/services decoupled from the data layer.

### 5. `data/repositories/` — Data access
`ProductRepository` (abstract interface) + `ProductRepositoryImpl` (wraps
`ApiService`). This is the seam that lets the app switch between the Web API and
Sanity without touching the UI.

### 6. `models/` — Pure data
Immutable-ish data classes with `fromJson`/`toJson`, `fromMap`/`fromApiMap`, and
`copyWith`. No Flutter imports. → [Data Models](06-data-models.md)

### 7. `config/` — Configuration
Env loading (dart-define + dotenv), typed config classes, named routes,
app constants, flavor singleton. → [Configuration](04-configuration.md)

---

## Dependency injection (Provider)

All cross-cutting dependencies are wired once in
[`DesignWearApp.build`](../lib/main.dart) using a `MultiProvider`:

```dart
MultiProvider(
  providers: [
    // Data layer — picks Web API or Sanity based on config
    Provider<ProductRepository>(
      create: (_) => ProductRepositoryImpl(
        WebApiConfig.useWebApi
            ? ApiService.webApi(WebApiConfig.baseUrl)
            : ApiService.sanity(),
      ),
    ),
    // Use cases depend on the repository
    Provider<GetCategoriesUseCase>(create: (c) => GetCategoriesUseCase(c.read())),
    Provider<GetFeaturedProductsUseCase>(...),
    Provider<GetProductsUseCase>(...),
    Provider<GetProductsByCategoryUseCase>(...),
    Provider<GetProductByIdUseCase>(...),
    Provider<GetTaxRateUseCase>(...),
    // Stateful services
    ChangeNotifierProvider(create: (c) => CartService(c.read<GetTaxRateUseCase>())),
    ChangeNotifierProvider(create: (_) => AuthService()..init()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ],
  child: Consumer<ThemeProvider>(builder: ...MaterialApp...),
)
```

`ScreenUtilInit` wraps the whole tree (design size **390×844**) and a top-level
`builder` clamps content to **max width 1440px** and centers it on large screens.

---

## Data source strategy: Web API ↔ Sanity

`ApiService` is the IO hub. It has two factory constructors:

- `ApiService.sanity()` — talks to Sanity directly via `SanityService`.
- `ApiService.webApi(baseUrl)` — talks to the Next.js backend.

When `useWebApi` is true, **every product/category read tries the Web API first
and automatically falls back to Sanity** if the API returns nothing or errors:

```dart
Future<List<Product>> fetchProducts() async {
  if (useWebApi) {
    final results = await _fetchProductsFromWeb();
    if (results.isNotEmpty) return results;     // ← fallback on empty/failure
    return _fetchProductsFromSanity();
  }
  return _fetchProductsFromSanity();
}
```

Some data is **always** served from Sanity regardless of mode — banners, deals,
category quick-links, and design templates (`fetchBanners()`, `fetchDeals()`,
`fetchCategoryQuickLinks()`, `fetchDesignTemplates()`).

This makes the app resilient: a backend outage degrades to CMS content rather
than a blank screen.

---

## Request lifecycle examples

### Loading the home feed (read path)

```
HomeScreen
  └─ context.read<GetFeaturedProductsUseCase>()()
       └─ ProductRepositoryImpl.fetchFeaturedProducts()
            └─ ApiService.fetchFeaturedProducts()
                 └─ SanityService.fetchFeaturedProducts()   (GROQ query)
                      └─ flutter_sanity HTTP client → Sanity CDN
```

### Placing an order (write path, backend required)

```
CheckoutScreen
  └─ OrderService.createOrder(cart, address, notes)
       │   headers: fresh Firebase ID token (force refresh)
       └─ POST {WEB_API_BASE_URL}/orders            → returns order id
  └─ RazorpayService.makePayment(orderId, amount, name)
       ├─ POST /payments/razorpay/order             → razorpay_order_id, key_id, amount
       ├─ razorpay.open(options)                     → native checkout
       └─ on success → POST /payments/razorpay/verify (signature check)
```

### Designing with AI (DesignBot)

```
DesignStudioScreen → AgentChatWidget
  └─ AIAgentService.sendMessage(text, currentDesign, [images])
       │  loads assets/system_prompt.txt, injects {{CURRENT_STATE}} = design JSON
       ├─ POST /ai/agent      (Gemini chat — returns conversational text + ```json design```)
       └─ POST /ai/generate-design  (parallel — returns base64 PNG graphic)
  └─ parse fenced JSON → CustomDesign.fromJson → copyWith(designImageBase64)
```

See [AI & Virtual Try-On](11-ai-and-virtual-tryon.md) for the design JSON contract.

---

## Startup sequence (`mainCommon`)

[`lib/main.dart`](../lib/main.dart) → `mainCommon(Flavor)`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `ConfigLoader.init()` (no-op latch; reads dart-defines lazily)
3. Load `.env` then `.env.local` **(mobile/desktop only)** — web skips this
4. Gate Firebase init on credentials being present:
   - init `Firebase`, wire **Crashlytics** (skip web/Windows/Linux)
   - register **FCM background handler** (skip Windows/Linux)
   - swallow `duplicate-app` errors
5. `FlavorConfig.init(flavor)`
6. Fire-and-forget `LoggingService.init(...)` (non-blocking)
7. `runApp(DesignWearApp(flavor))`

---

## Cross-cutting concerns

| Concern | Mechanism |
|---------|-----------|
| **Logging** | `LoggingService` singleton; also a `routeObserver` attached to `MaterialApp.navigatorObservers` for screen tracking |
| **Crash reporting** | Crashlytics captures `FlutterError.onError` + `PlatformDispatcher.onError` (mobile only) |
| **Auth tokens** | Firebase ID tokens fetched **fresh (force-refresh)** for order/payment calls; cached token in `SharedPreferences` as fallback |
| **Offline-ish resilience** | Web-API → Sanity fallback; Demo Mode defaults |
| **Persistence** | `SharedPreferences` (session, theme, cart, designs) + `sqflite` |
| **Cart sync** | Debounced (2s) `PUT /cart/items` when backend enabled and user signed in |

---

## Backend architecture (summary)

The Next.js backend (`designwear-backend/`) uses the App Router. `app/api/*`
route handlers cover auth, products, categories, cart, orders, payments, AI,
sync, metrics, and health. It uses **Firebase Admin** (Firestore + token
verification), **Sanity** (content + studio), **Razorpay** (payments), and
**Gemini** (AI). Full catalog: [Backend & API Reference](12-backend-and-api.md).
