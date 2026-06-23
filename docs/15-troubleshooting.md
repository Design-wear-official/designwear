# 15 · Troubleshooting

Common issues, their root cause, and the fix. Grouped by area.

---

## Setup & run

| Symptom | Cause | Fix |
|---------|-------|-----|
| `flutter pub get` can't find `flutter_sanity` | Local path package | It's at `packages/flutter_sanity`; ensure you cloned with submodules (`git submodule update --init --recursive`) |
| App only shows demo/sample data | Backend disabled or `.env` missing | Set `USE_WEB_API=true` + a reachable `WEB_API_BASE_URL`, or accept Demo Mode (intended fallback) |
| `--flavor` error on Android | Flavor not passed | Run with `--flavor external -t lib/main_external.dart` (or `internal`) |
| Changes to `.env` not picked up on web | `.env` isn't loaded on web | Use `--dart-define` / `build_web.sh` for web config |
| New env var not visible on web | Not in `ConfigLoader._dartDefines` | Add the key to the `_dartDefines` map in `app_config.dart` |

---

## Firebase & Auth

| Symptom | Cause | Fix |
|---------|-------|-----|
| `ℹ️ Firebase credentials not configured` | Firebase gate found no creds | Set `FIREBASE_ANDROID_API_KEY` (Android) / `FIREBASE_WEB_API_KEY` (desktop), or run without Firebase intentionally |
| `duplicate-app` warning at startup | Firebase init ran twice | Harmless — caught and ignored in `mainCommon()` |
| Google Sign-In `ApiException: 10` / `DEVELOPER_ERROR` | Missing SHA-1 | Add the build's SHA-1 to Firebase → Project Settings → Your Apps (`com.vishwamai.designwear`) |
| "Google Sign-In is not supported on Windows" | Unsupported platform | Use email/password on Windows/Linux (`AuthService.isGoogleSignInSupported`) |
| Friendly errors like "Incorrect email or password" | Mapped Firebase codes | Expected — see `_friendlyFirebaseError` in `auth_service.dart` |
| Crashlytics not reporting on Windows/Linux/Web | Unsupported there | By design — Crashlytics only wires up on mobile |

---

## Data & content

| Symptom | Cause | Fix |
|---------|-------|-----|
| Empty product list | Both Web API and Sanity returned nothing | Check `WEB_API_BASE_URL`/Sanity project id; reads auto-fall-back to Sanity |
| Home banners/deals look generic | CMS content not published | App renders `HomeBanner.fallbacks` / `Deal.fallbacks` until you publish in the Studio |
| Product title blank from Sanity | Schema uses `name`, model uses `title` | Handled by `coalesce(title, name)` in the GROQ projection — ensure `name` is set |
| Categories/products missing fields | `fromMap` vs `fromApiMap` mismatch | Sanity docs use `fromMap`; backend JSON uses `fromApiMap`. Confirm which source is active |

---

## Cart, Orders & Payments

| Symptom | Cause | Fix |
|---------|-------|-----|
| Cart doesn't sync across devices | `USE_WEB_API` off or not signed in | Cart sync only runs with the backend enabled **and** an authenticated user |
| `Session expired. Please login again.` | `401` on order create | `OrderService` throws `UnauthorizedException`; re-authenticate (tokens are force-refreshed but can still fail) |
| Order created but stays `PENDING` | Payment not verified | Razorpay success → `/payments/razorpay/verify` must pass the HMAC check to mark `PAID` |
| Payment "succeeds" but app reports failure | Verification failed | `RazorpayService.makePayment` returns `true` only after server-side `verify`; check `RAZORPAY_KEY_SECRET` on the backend |
| External wallet payments not confirmed | Can't verify immediately | Treated as not-verified by design (`onExternalWallet` → `false`) |
| Wrong amount charged | Paise conversion | Backend multiplies INR by 100; ensure `totalAmount` is in rupees |
| Order not appearing in Sanity Studio | `SANITY_API_TOKEN` missing | Order→Sanity sync is skipped without it (payment still succeeds) |

---

## AI (DesignBot / Try-On)

| Symptom | Cause | Fix |
|---------|-------|-----|
| `API Error: Gemini API key is missing` (503) | No `GEMINI_API_KEY` on backend | Set it in the backend env |
| DesignBot replies but design doesn't change | No valid ```json``` block | Model must return a fenced `{"design": {...}}` block; check the system prompt rendering |
| Colors render wrong from AI | Model used `#RRGGBB` | The prompt mandates `0xFFRRGGBB`; reinforce/clear history |
| Try-on throws `VirtualTryOnException` | Backend error / no image | Check `/ai/try-on`, image sizes, and connectivity |
| Image attachments fail | Permissions denied | Grant camera/photos (`permission_handler`); guide user to settings |
| Slow AI responses | Multiple images / network | Image analysis can take 3–10s; compress images (~1024px, 85%) |

---

## Backend / Vercel

| Symptom | Cause | Fix |
|---------|-------|-----|
| `/health` returns `degraded` (503) | `FIREBASE_SERVICE_ACCOUNT_KEY` missing/malformed | Set the single-line service-account JSON in Vercel env and redeploy |
| "Firebase Admin is not initialized" on API calls | Same as above | Same — the lazy `db`/`auth` proxies throw until the key is set |
| `npm ci` fails | Peer-dep conflicts | Use `npm ci --legacy-peer-deps` (matches `vercel.json`) |
| 401 on protected endpoints | Missing/expired Bearer token | Client must send a fresh Firebase ID token; verify clock + token refresh |

---

## UI / layout

| Symptom | Cause | Fix |
|---------|-------|-----|
| RenderFlex overflow on small phones | Fixed sizes | Follow [Flutter Overflow Pixel Prevention Guide.md](Flutter%20Overflow%20Pixel%20Prevention%20Guide.md); use `.w/.h/.sp` and flexible widgets |
| Content stretched on desktop/web | Expected clamp | The app caps content at **1440px** (centered) via `MaterialApp.builder` |
| Wrong/clipped sizing | ScreenUtil canvas | Sizes are relative to the **390×844** design canvas |

---

## Diagnostics

- **Logs:** `LoggingService` records to CSV-style `LogRow`s (and route changes
  via its `routeObserver`); check `logs.txt` and debug console.
- **Static analysis:** `flutter analyze` (rules in `analysis_options.yaml`),
  or `run_analyze.bat` on Windows.
- **Backend health:** `GET /api/health`.
- **Crash reports:** Firebase Crashlytics (mobile builds only).

If a problem isn't here, check the relevant deep-dive doc
([Configuration](04-configuration.md), [Services & State](07-services-and-state.md),
[Backend & API Reference](12-backend-and-api.md)) — the code is authoritative.
