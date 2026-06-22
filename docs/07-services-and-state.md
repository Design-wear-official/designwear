# 07 · Services & State

This page covers the three inner layers that move data and hold state: the
**repository** (data access seam), the **use cases** (business rules), and the
**services** (stateful logic). State is shared with the UI through
[`provider`](https://pub.dev/packages/provider).

---

## State management model

DesignWear uses **Provider** with a clear split:

| Pattern | Registered? | Examples | How widgets use it |
|---------|-------------|----------|--------------------|
| `ChangeNotifierProvider` | Yes (in `main.dart`) | `CartService`, `AuthService`, `ThemeProvider` | `context.watch<T>()` / `Consumer<T>` to rebuild |
| `Provider` (plain) | Yes | `ProductRepository`, all `*UseCase` | `context.read<T>()` to call |
| Manual instantiation | No | `ApiService`, `AIAgentService`, `OrderService`, `RazorpayService`, `VirtualTryOnService`, `SanityService`, design studio services, `LoggingService` (singleton) | constructed where used |

The full provider graph is wired in
[`DesignWearApp.build`](../lib/main.dart) — see
[Architecture → Dependency injection](03-architecture.md#dependency-injection-provider).

---

## Data layer: `ProductRepository`

A thin abstraction so the UI/use cases never touch `ApiService` directly.

```dart
abstract class ProductRepository {
  Future<List<Product>>  fetchProducts();
  Future<List<Product>>  fetchFeaturedProducts();
  Future<List<Category>> fetchCategories();
  Future<List<Product>>  fetchProductsByCategory(String categoryId);
  Future<Product?>       fetchProductById(String productId);
  Future<double>         fetchTaxRate();
}
```

`ProductRepositoryImpl` simply delegates each call to the injected `ApiService`.
The repository is constructed once with either `ApiService.webApi(...)` or
`ApiService.sanity()` depending on `WebApiConfig.useWebApi`.

---

## Domain layer: Use cases

Single-purpose callable classes in
[`product_use_cases.dart`](../lib/domain/usecases/product_use_cases.dart). Each
wraps one repository method behind a `call()` operator:

| Use case | Signature |
|----------|-----------|
| `GetProductsUseCase` | `Future<List<Product>> call()` |
| `GetFeaturedProductsUseCase` | `Future<List<Product>> call()` |
| `GetCategoriesUseCase` | `Future<List<Category>> call()` |
| `GetProductsByCategoryUseCase` | `Future<List<Product>> call(String categoryId)` |
| `GetProductByIdUseCase` | `Future<Product?> call(String productId)` |
| `GetTaxRateUseCase` | `Future<double> call()` |

Usage from a widget:

```dart
final products = await context.read<GetFeaturedProductsUseCase>()();
```

---

## Services

### `ApiService` — data IO hub
[`api_service.dart`](../lib/services/api_service.dart)

The bridge between the app and either the Next.js backend or Sanity. Factories:
`ApiService.webApi(baseUrl)` and `ApiService.sanity()`.

- **Reads with fallback** (`fetchProducts`, `fetchCategories`,
  `fetchProductsByCategory`, `fetchProductById`): try Web API, fall back to
  Sanity if empty/error.
- **Always-Sanity content**: `fetchBanners`, `fetchDeals`,
  `fetchCategoryQuickLinks`, `fetchDesignTemplates`.
- `fetchTaxRate()` — backend `/settings/tax-rate` or Sanity (default `18.0`).
- `publishRemix({...})` — `POST /publish-remix`; publishes a remix to Sanity +
  Firebase, returns the new product id (throws on failure).
- Auth header helper attaches `Bearer <auth_token>` from `SharedPreferences`.

### `SanityService` — CMS queries
[`sanity_service.dart`](../lib/services/sanity_service.dart)

Wraps the local `flutter_sanity` client (`useCdn: true`). Holds a shared GROQ
**`_productProjection`** that normalizes the Sanity schema to the `Product`
model (e.g. `coalesce(title, name)`, `slug.current`, `garmentType → productType`,
image asset URL resolution, `lineage[]` expansion). Methods: `fetchProducts`,
`fetchFeaturedProducts` (falls back to first 6 if none flagged),
`fetchProductsByCategory`, `fetchCategories`, `fetchTaxRate`, `fetchBanners`,
`fetchDeals`, `fetchCategoryQuickLinks`, `fetchDesignTemplates`.

### `AuthService` *(ChangeNotifier)* — authentication
[`auth_service.dart`](../lib/services/auth_service.dart)

Holds a lightweight session `User` (`id`, `email`, `name`, `photoUrl`,
`addresses`, `paymentMethods`, `isGuest`). Backed by **Firebase Auth** and
persisted to `SharedPreferences`.

| Method | Purpose |
|--------|---------|
| `init()` | Sets up FCM (mobile only) |
| `signInWithEmail(email, pwd)` | Email/password sign-in |
| `signUpWithEmail(email, pwd, name)` | Register + set display name |
| `loginAsGuest()` | Anonymous sign-in |
| `signInWithGoogle()` | Google (unsupported on Windows/Linux) |
| `updateProfile({name, email})` | Update Firebase profile (email needs verify) |
| `updateProfileImage(path)` | Set photo URL |
| `addAddress(map)` / `addPaymentMethod(map)` | Persist + sync to backend `/auth/update` |
| `logout()` | Clear prefs + sign out of Google/Firebase |

Getters: `currentUser`, `isLoggedIn`, `isLoading`. Firebase errors are mapped to
friendly messages (`_friendlyFirebaseError`). FCM tokens are synced to
`/auth/update`. `static isGoogleSignInSupported` gates the Google flow.

> There are **two** `User`-named types: the rich [`AppUser`](06-data-models.md)
> in `models/`, and this session `User` defined inside `auth_service.dart`. They
> are not interchangeable.

### `CartService` *(ChangeNotifier)* — cart & coupons
[`cart_service.dart`](../lib/services/cart_service.dart)

Wraps a `Cart` and exposes its computed values (`itemCount`, `subtotal`, `tax`,
`total`, `hasCoupon`, `couponDiscount`, etc.). Constructed with
`GetTaxRateUseCase` so it loads the live tax rate on init.

- Mutations: `addToCart`, `removeFromCart`, `updateQuantity`,
  `incrementQuantity`, `decrementQuantity`, `clearCart`, `applyCoupon`,
  `removeCoupon`.
- **Backend sync** (only when `USE_WEB_API=true` *and* a user is signed in):
  debounced `PUT /cart/items` (2s) after mutations; `loadCartFromBackend()` on
  auth change (`GET /cart`). Uses fresh Firebase ID tokens.

### `OrderService` — order create/list
[`order_service.dart`](../lib/services/order_service.dart)

Backend-only (no-ops when `USE_WEB_API` is false).

- `createOrder(cartService, shippingAddress, notes)` → `POST /orders`
  (`201` returns the order id; `401` throws `UnauthorizedException`).
- `fetchOrders()` → `GET /orders` (returns raw maps).

Always sends a **force-refreshed** Firebase ID token; falls back to the stored
token.

### `RazorpayService` *(singleton)* — payments
[`razorpay_service.dart`](../lib/services/razorpay_service.dart)

- `makePayment({orderId, amount, customerName})`:
  1. `POST /payments/razorpay/order` → `razorpay_order_id`, `key_id`, `amount`
  2. opens native checkout (`razorpay_flutter`)
  3. on success → `_verifyPayment(...)` → `POST /payments/razorpay/verify`
     (server-side signature check). Returns `true` only when verified.

### `AIAgentService` — DesignBot + AI image gen
[`ai_agent_service.dart`](../lib/services/ai_agent_service.dart)

- `sendMessage(userMessage, currentDesign, {imageAttachments})` →
  `AgentResponse(text, updatedDesign?)`. Loads `assets/system_prompt.txt`,
  injects `{{CURRENT_STATE}}` with the current design JSON, calls `/ai/agent`
  **and** `/ai/generate-design` in parallel, parses the fenced ```json``` design
  block, and attaches the generated graphic via `designImageBase64`.
- `generateDesignImage(prompt)` → base64 PNG or null.
- `clearHistory()` resets the in-memory conversation.

See [AI & Virtual Try-On](11-ai-and-virtual-tryon.md) for the contract.

### `VirtualTryOnService` — AI try-on
[`virtual_tryon_service.dart`](../lib/services/virtual_tryon_service.dart)

- `generateTryOn({personImageBytes, clothingImageBytes})` →
  `POST /ai/try-on` → decoded `Uint8List` (throws `VirtualTryOnException`).
- Helpers: `saveImage(bytes, name)`, `fileToBytes(file)`.

### `ThemeProvider` *(ChangeNotifier)* — theming
[`theme_provider.dart`](../lib/services/theme_provider.dart)

Holds `ThemeMode` (system/light/dark), persisted under
`AppConstants.prefKeyThemeMode`. API: `themeMode`, `isDarkMode`,
`toggleTheme(bool)`, `setThemeMode(mode)`.

### `LoggingService` *(singleton)* — logging & route tracking
[`logging_service.dart`](../lib/services/logging_service.dart)

`LoggingService.instance` with `init({flavor, appVersion})`, `log(...)`,
`logInfo`, `logWarn`, `logError`, `logCrash`. Captures device/OS/app/flavor/page
context into `LogRow` (CSV-exportable). Exposes a `routeObserver` wired into
`MaterialApp.navigatorObservers` to track the current page.

---

## Design Studio services

| Service | File | Role |
|---------|------|------|
| `DesignHistoryService` | `design_history_service.dart` | Undo/redo stack. `addToHistory(design)`, `undo()`, `redo()`, `canUndo`, `canRedo`, `clear()` (cap via `AppConstants.maxUndoHistory`) |
| `DesignStorageService` | `design_storage_service.dart` | Persist designs. `getSavedDesigns()`, `saveDesign()`, `deleteDesign(id)`, `getDesignById(id)`, plus **auto-save** (`getAutoSavedDesign()`, `clearAutoSave()`) |
| `DesignTemplateService` | `design_template_service.dart` | Templates & starters. `getAllTemplates()`, `getTemplatesByCategory(cat)`, `getTemplateById(id)`, `getCustomTemplates()`, `getAvailableCategories()`, `getStarterDesigns()`, `getAvailableFonts()` |
| `DesignStudioDemoService` | `design_studio_demo_service.dart` | Canned responses for demo mode |

These power the Design Studio module documented in
[Design Studio](10-design-studio.md).

---

## Patterns & conventions

- **Notify after mutate:** `ChangeNotifier` services call `notifyListeners()`
  after every state change.
- **Fresh tokens for money/identity:** order and payment services force-refresh
  the Firebase ID token before each request.
- **Graceful degradation:** services catch network errors, log via
  `LoggingService`, and return empty/`false` rather than throwing into the UI
  (except deliberate cases like `UnauthorizedException` and
  `VirtualTryOnException`).
- **Backend optionality:** services that need the backend short-circuit when
  `WebApiConfig.useWebApi` is false.
