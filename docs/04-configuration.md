# 04 · Configuration

All runtime configuration flows through one loader and a set of typed config
classes in [`lib/config/`](../lib/config). This page is the authoritative
reference for every variable and flag.

---

## How config is resolved

[`ConfigLoader`](../lib/config/app_config.dart) resolves each key with a strict
precedence:

1. **`--dart-define` build args** (compile-time, via `String.fromEnvironment`)
2. **`dotenv`** values from `.env` / `.env.local` (runtime, mobile/desktop only)
3. **Hard-coded defaults** in the typed config classes

```dart
ConfigLoader.get('SANITY_PROJECT_ID')  // dart-define → dotenv → null
```

> **Web vs mobile/desktop:** On web, `.env` is **not** loaded (it must never be
> served publicly), so web builds rely on `--dart-define` or the built-in
> defaults. On mobile/desktop, `.env` then `.env.local` are loaded in
> `mainCommon()` (later file overrides earlier).

Only the keys listed in `ConfigLoader._dartDefines` are readable via dart-define.
If you add a new variable that must work on web, **add it to that map**.

---

## Environment variable reference

### Sanity CMS — `SanityConfig`
| Variable | Default | Notes |
|----------|---------|-------|
| `SANITY_PROJECT_ID` | `jh7llku7` | Public — appears in every CDN URL |
| `SANITY_DATASET` | `production` | Dataset name |

### Web API — `WebApiConfig`
| Variable | Default | Notes |
|----------|---------|-------|
| `WEB_API_BASE_URL` | `https://designwear-backend.vishwamai.com/api` | Backend base URL |
| `USE_WEB_API` | `false` | `"true"` routes reads through the backend (with Sanity fallback) |
| `API_TIMEOUT_SECONDS` | `30` | Parsed into a `Duration` |

### App — `AppConfig`
| Variable | Default | Notes |
|----------|---------|-------|
| `APP_NAME` | `DesignWear` | Display name |
| `DEBUG_MODE` | `false` | `"true"` enables debug behavior |
| `DATA_SOURCE` | `sanity` | `sanity` \| `demo` (force demo data) |
| `ENABLE_FALLBACK` | `false` | `"true"` enables data-source fallbacks |

### Google Gemini — `GeminiConfig`
| Variable / const | Value | Notes |
|------------------|-------|-------|
| `GEMINI_API_KEY` | `''` | Used by the **backend**; the client proxies AI calls |
| `model` (const) | `gemini-3.5-flash` | Matches the backend's `MODEL_URL` |
| `maxOutputTokens` (const) | `8192` | |
| `temperature` (const) | `0.7` | |
| `isConfigured` | derived | true when key non-empty |

> **Doc/code note:** Some feature docs mention "Gemini 2.0 Flash". The code
> (`GeminiConfig.model` and the backend `MODEL_URL`) currently targets
> `gemini-3.5-flash`. Treat the code value as authoritative.

### Razorpay — `RazorpayConfig`
| Variable / const | Value | Notes |
|------------------|-------|-------|
| `RAZORPAY_KEY_ID` | `''` | Public key id (secret lives on the backend) |
| `currency` (const) | `INR` | |
| `isConfigured` | derived | true when key id non-empty |

### Firebase runtime — `FirebaseRuntimeConfig`
These are **runtime** values (separate from `google-services.json` /
`firebase_options.dart`). Used for the Firebase-init gate and any runtime needs.

| Variable | Notes |
|----------|-------|
| `FIREBASE_PROJECT_ID` | |
| `FIREBASE_API_KEY` | |
| `FIREBASE_APP_ID` | |
| `FIREBASE_MESSAGING_SENDER_ID` | |
| `FIREBASE_STORAGE_BUCKET` | |
| `FIREBASE_ANDROID_API_KEY` | **Gates** Firebase init on Android (see below) |
| `FIREBASE_WEB_API_KEY` | **Gates** Firebase init on desktop |

#### Firebase init gate (`lib/main.dart`)
Firebase only initializes when credentials are present:

```dart
final hasFirebaseCreds = kIsWeb
  || (dotenv.env['FIREBASE_ANDROID_API_KEY']?.isNotEmpty ?? false)
  || (isDesktop && (dotenv.env['FIREBASE_WEB_API_KEY']?.isNotEmpty ?? false));
```

If false, the app logs `ℹ️ Firebase credentials not configured — running without
Firebase` and continues (Auth/FCM/Crashlytics disabled).

---

## Config classes summary

| Class | File | Responsibility |
|-------|------|----------------|
| `ConfigLoader` | `app_config.dart` | dart-define + dotenv resolution |
| `SanityConfig` | `app_config.dart` | Sanity project/dataset |
| `WebApiConfig` | `app_config.dart` | Backend URL, toggle, timeout |
| `AppConfig` | `app_config.dart` | Name, debug, data source, fallback |
| `GeminiConfig` | `app_config.dart` | AI model params |
| `RazorpayConfig` | `app_config.dart` | Payment key/currency |
| `FirebaseRuntimeConfig` | `app_config.dart` | Runtime Firebase values |
| `AppConstants` | `app_constants.dart` | Non-env constants (see below) |
| `AppRoutes` | `app_routes.dart` | Named route strings |
| `FlavorConfig` | `flavor_config.dart` | Active build flavor |

All are re-exported through [`lib/config/config.dart`](../lib/config/config.dart),
so a single `import 'package:designwear/config/config.dart';` brings them all in.

---

## Build flavors

`Flavor { internal, external }` (defined in `lib/main.dart`).

`FlavorConfig` is a static singleton set once in `mainCommon()`:

```dart
FlavorConfig.init(flavor);
FlavorConfig.isInternal   // true for the dev flavor
FlavorConfig.isExternal   // true for production
FlavorConfig.label        // 'INTERNAL' | 'EXTERNAL'
```

- `internal` → debug banner visible, dev defaults.
- `external` → production (default for `flutter run` and `lib/main.dart`).

---

## `AppConstants` (non-env constants)

[`app_constants.dart`](../lib/config/app_constants.dart) holds values that don't
belong in env config. Highlights:

| Group | Examples |
|-------|----------|
| App identity | `appVersion 1.0.0`, `appBuildNumber 1`, `supportEmail`, `privacyPolicyUrl`, `termsUrl` |
| Products | `availableSizes` (XS–3XL), `productTypes`, `maxCartQuantityPerItem 10`, `maxImagesPerProduct 8` |
| Design Studio | `maxDesignElements 50`, `maxUndoHistory 30`, `designCanvasWidth 400`, `designCanvasHeight 500`, `supportedFonts`, `baseProductColors` (10 hex) |
| Orders | `orderStatuses` (pending → refunded) |
| Pagination | `defaultPageSize 20`, `featuredProductLimit 10`, `searchResultsLimit 50` |
| Animations | `animFast 150ms`, `animNormal 300ms`, `animSlow 500ms`, `bannerAutoScrollInterval 4s` |
| Prefs keys | `prefKeyThemeMode`, `prefKeyAuthToken`, `prefKeyUser`, `prefKeySavedDesigns`, `prefKeyCartItems`, … |
| Currency/locale | `defaultCurrency INR`, `defaultCurrencySymbol ₹`, `defaultLocale en_IN`, `supportedCurrencies` (INR/USD/EUR/GBP) |

> **Note:** Some persistence code uses literal key strings (e.g. `'auth_token'`,
> `'auth_uid'`) rather than the `AppConstants.prefKey*` constants. When adding new
> persistence, prefer the constants and migrate literals opportunistically.

---

## Demo Mode

When no API keys are configured (or `DATA_SOURCE=demo`), the app runs fully on
sample/public data:

- Reads fall back to the **public Sanity project** (`jh7llku7`).
- AI/Studio/Try-On surfaces still render with demo responses
  (`design_studio_demo_service.dart`).
- Payments are not real.

To force it explicitly, set `DATA_SOURCE=demo` in `.env`.

---

## Secrets & safety

- **Never** commit real secrets. `.env`, `.env.local`, service-account JSON, and
  `client_secret_*.json` are ignored via `.gitignore`.
- **Never** bundle `.env` into web builds (it's excluded from web loading by
  design). Use `--dart-define` for web config.
- `SANITY_PROJECT_ID` and `RAZORPAY_KEY_ID` are **public** by nature (they appear
  client-side). The Razorpay **secret** and Firebase **service account** live
  only on the backend.
- The backend verifies Razorpay signatures and Firebase ID tokens server-side —
  the client never trusts itself for money or identity.
