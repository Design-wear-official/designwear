# 01 · Project Overview

## What is DesignWear?

**DesignWear** is an AI-powered custom apparel e-commerce platform. Users design
their own t-shirts, hoodies, polos, caps, and tote bags in an interactive
**Design Studio**, get help from **DesignBot** (a Gemini-powered conversational
assistant), preview garments with **Virtual Try-On**, and buy them through a full
e-commerce flow with Razorpay payments.

The product is a **monorepo** containing two deployable applications plus shared
content infrastructure:

```
┌──────────────────────────┐      ┌───────────────────────────┐
│  Flutter client (lib/)   │ ───▶ │ Next.js backend           │
│  Android · iOS · Web ·   │      │ (designwear-backend/)     │
│  Windows · macOS · Linux │      │ REST API + Sanity Studio  │
└──────────────────────────┘      └───────────────────────────┘
            │                                  │
            │  (direct, when backend off)      │
            └───────────────▶ Sanity CMS ◀─────┘
                              (products, banners,
                               deals, templates)
```

---

## Key Features

| Feature | Description | Where in code |
|---------|-------------|---------------|
| **Design Studio** | Drag-and-drop canvas: text, stickers, shapes, colors, collar/pocket styles, templates, layers, undo/redo, auto-save | [`lib/screens/design_studio/`](../lib/screens/design_studio) |
| **DesignBot AI** | Conversational designer ("make it blue", "add a spooky logo") with image attachments | [`lib/services/ai_agent_service.dart`](../lib/services/ai_agent_service.dart) |
| **AI Design Generation** | Generates a graphic image for the garment from a text prompt | `generateDesignImage()` in the agent service |
| **Virtual Try-On** | AI-generated preview of a design worn by a person photo | [`lib/services/virtual_tryon_service.dart`](../lib/services/virtual_tryon_service.dart) |
| **Remix / Lineage** | Fork another creator's design; provenance chain is tracked and published | `publishRemix()` in [`api_service.dart`](../lib/services/api_service.dart) |
| **E-commerce flow** | Cart, coupons, tax, checkout, orders, order tracking | [`cart_service.dart`](../lib/services/cart_service.dart), [`order_service.dart`](../lib/services/order_service.dart) |
| **Payments** | Razorpay order creation + signature verification | [`razorpay_service.dart`](../lib/services/razorpay_service.dart) |
| **Auth** | Firebase email/password, Google Sign-In, anonymous guest | [`auth_service.dart`](../lib/services/auth_service.dart) |
| **Push notifications** | Firebase Cloud Messaging with token sync | `_initFcm()` in the auth service |
| **Themes** | System / Light / Dark with persistence | [`theme_provider.dart`](../lib/services/theme_provider.dart) |
| **Responsive UI** | Mobile / tablet / desktop layouts, max-width clamp at 1440px | [`responsive_utils.dart`](../lib/presentation/utils/responsive_utils.dart) |
| **Demo Mode** | Full offline experience with sample data when no keys are configured | See [Configuration](04-configuration.md) |

---

## Tech Stack

### Flutter client

| Layer | Technology |
|-------|-----------|
| UI | Flutter (SDK `^3.10.4`), Material Design 3 |
| State management | [`provider`](https://pub.dev/packages/provider) `^6.1.1` |
| Responsive sizing | [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil) `^5.9.3` (design size 390×844) |
| CMS access | `packages/flutter_sanity` (local package) |
| Auth | `firebase_auth`, `google_sign_in` |
| Payments | `razorpay_flutter` |
| AI | Google Gemini via the backend proxy |
| Notifications | `firebase_messaging` |
| Crash reporting | `firebase_crashlytics` (mobile only) |
| Local storage | `shared_preferences`, `sqflite` |
| Networking | `http` |
| Images | `cached_network_image`, `image_picker` |
| Fonts | `google_fonts` (Outfit + Poppins) |
| Config | `flutter_dotenv` + `--dart-define` |

### Backend (`designwear-backend/`)

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript (strict) |
| CMS | Sanity.io (`sanity`, `next-sanity`) |
| Database / Auth | Firebase Admin SDK (Firestore + ID-token verification) |
| Payments | Razorpay server SDK |
| AI | `@google/genai` + direct Gemini REST calls |
| Logging | Winston |
| Hosting | Vercel (`vercel.json`) |

See [01-overview](01-overview.md) → [Architecture](03-architecture.md) for how
these pieces fit together.

---

## Supported Platforms

The Flutter client targets **Android, iOS, Web, Windows, macOS, and Linux**.
Platform-specific behavior is handled defensively in `lib/main.dart` and the
services:

- **Crashlytics** is skipped on Web, Windows, and Linux.
- **FCM background handler** is skipped on Windows and Linux.
- **Google Sign-In** is unavailable on Windows/Linux (email/password used instead).
- **Web** never bundles `.env`; it reads `--dart-define` build args or built-in defaults.

---

## Build Flavors

Two flavors are defined by the `Flavor` enum in [`lib/main.dart`](../lib/main.dart):

| Flavor | Entry point | Use | Behavior |
|--------|-------------|-----|----------|
| `internal` | [`lib/main_internal.dart`](../lib/main_internal.dart) | Development / QA | Shows the debug banner (`debugShowCheckedModeBanner`) |
| `external` | [`lib/main_external.dart`](../lib/main_external.dart) / [`lib/main.dart`](../lib/main.dart) | Production | No debug banner |

`FlavorConfig.isInternal` is readable statically anywhere after startup. See
[Configuration](04-configuration.md#build-flavors).

---

## Repository at a glance

| Path | Purpose |
|------|---------|
| `lib/` | Flutter application source |
| `designwear-backend/` | Next.js API + Sanity Studio |
| `designwear-sdk/` | TypeScript SDK for the backend (git submodule) |
| `packages/flutter_sanity/` | Local Dart package — Sanity HTTP client |
| `sanity/` | Standalone Sanity schema definitions |
| `assets/` | Images + `system_prompt.txt` (the DesignBot prompt) |
| `docs/` | This documentation |
| `android/ ios/ web/ windows/ macos/` | Platform runners |

A full annotated tree is in [Project Structure](05-project-structure.md).
