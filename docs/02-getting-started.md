# 02 · Getting Started

This guide takes you from a fresh clone to a running app, then a release build.

---

## 1. Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Flutter SDK | `^3.10.4` (Dart 3.10+) | `flutter --version` |
| Dart | bundled with Flutter | `dart --version` |
| Android Studio / Xcode | latest | for device builds |
| Node.js | 18+ | `node -v` (only for the backend) |
| Git | any | `git --version` |

Run `flutter doctor` and resolve any reported issues before continuing.

> **Windows note:** the project is developed on Windows. PowerShell is the
> primary shell; a Bash environment (Git Bash) also works.

---

## 2. Clone & install

```bash
git clone <repo-url> designwear
cd designwear

# This repo uses git submodules (designwear-sdk, vendored Pub git caches)
git submodule update --init --recursive

flutter pub get
```

The Flutter app depends on a **local package** at `packages/flutter_sanity`
(declared as a path dependency in `pubspec.yaml`) — `flutter pub get` wires it up
automatically.

---

## 3. Configure environment (optional)

> **You can skip this entirely.** With no `.env`, the app runs in **Demo Mode**
> using the public Sanity project (`jh7llku7`) and built-in fallbacks. Every
> screen is functional; no payments are real.

To configure real services, copy the example and fill in values:

```bash
cp .env.example .env
```

Two files are loaded on **mobile/desktop** (in order, later wins):

1. `.env`        — base/dev defaults
2. `.env.local`  — overrides (production settings take precedence)

On **web**, `.env` is **not** bundled — use `--dart-define` instead (see below).

A minimal `.env`:

```env
# ── Sanity CMS ───────────────────────────────────────────────
SANITY_PROJECT_ID=jh7llku7
SANITY_DATASET=production

# ── Backend API (set USE_WEB_API=true to route through it) ────
WEB_API_BASE_URL=https://designwear-backend.vishwamai.com/api
USE_WEB_API=false
API_TIMEOUT_SECONDS=30

# ── Google Gemini (AI) — proxied by the backend ──────────────
GEMINI_API_KEY=your_gemini_key

# ── Razorpay ─────────────────────────────────────────────────
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx

# ── App / feature flags ──────────────────────────────────────
APP_NAME=DesignWear
DEBUG_MODE=true
DATA_SOURCE=sanity
ENABLE_FALLBACK=true

# ── Firebase (mobile/desktop runtime gate; see below) ────────
FIREBASE_ANDROID_API_KEY=...
FIREBASE_WEB_API_KEY=...
```

The complete variable reference (including every Firebase key) is in
[Configuration](04-configuration.md).

---

## 4. Firebase setup

Firebase powers Auth, Cloud Messaging, and Crashlytics. **It is gated** — if no
Firebase credentials are present, `mainCommon()` logs a notice and runs without
Firebase (see [`lib/main.dart`](../lib/main.dart)).

To enable it:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Register Android, iOS, and (optionally) Web apps.
3. Drop the platform config files in:
   - Android → `android/app/google-services.json`
   - iOS → `ios/Runner/GoogleService-Info.plist`
4. Confirm [`lib/firebase_options.dart`](../lib/firebase_options.dart) matches
   your project (regenerate with `flutterfire configure` if needed).
5. In **Authentication**, enable **Email/Password**, **Google**, and **Anonymous**.
6. For Google Sign-In on Android, add your build's **SHA-1** fingerprint under
   *Project Settings → Your Apps* (`com.vishwamai.designwear`). Missing SHA-1 is
   the usual cause of `ApiException: 10` (the auth service surfaces a friendly hint).

---

## 5. Run the app

```bash
# Default (external flavor, lib/main.dart)
flutter run

# Internal / development flavor (debug banner on)
flutter run --flavor internal -t lib/main_internal.dart

# Explicit external / production flavor
flutter run --flavor external -t lib/main_external.dart

# Web, routing through the backend, with build-time config
flutter run -d chrome \
  --dart-define=USE_WEB_API=true \
  --dart-define=WEB_API_BASE_URL=http://localhost:3000/api
```

> On Android, the `--flavor` must match a product flavor in
> `android/app/build.gradle`. If you only need a quick run, plain `flutter run`
> uses the default external entry point.

---

## 6. Run the backend (optional)

Only needed if you set `USE_WEB_API=true` or want AI / payments locally.

```bash
cd designwear-backend
npm install
cp .env.local.example .env.local   # fill Sanity + Firebase Admin + Razorpay + Gemini
npm run dev                          # http://localhost:3000
```

Required backend env (in `.env.local`):

- `SANITY_PROJECT_ID`, `SANITY_DATASET`
- `FIREBASE_SERVICE_ACCOUNT` (service-account JSON for Firebase Admin)
- `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`
- `GEMINI_API_KEY`

See [Backend & API Reference](12-backend-and-api.md) for the full list and the
endpoint catalog.

---

## 7. Build for release

```bash
# Android
flutter build apk   --flavor external -t lib/main_external.dart --release
flutter build appbundle --flavor external -t lib/main_external.dart --release

# iOS
flutter build ipa   --flavor external -t lib/main_external.dart --release

# Web (see build_web.sh for the project's canonical web build)
./build_web.sh
```

Deployment targets (Firebase Hosting, Vercel) are covered in
[Deployment & CI/CD](14-deployment-and-ci.md).

---

## 8. Tests & analysis

```bash
flutter test                # run unit/widget tests
flutter test --coverage     # with coverage
flutter analyze             # static analysis (rules in analysis_options.yaml)
```

Windows convenience scripts exist: `run_analyze.bat`.

---

## Common first-run problems

| Symptom | Fix |
|---------|-----|
| App shows demo data only | No/disabled backend — set `USE_WEB_API=true` and a reachable `WEB_API_BASE_URL` |
| `ApiException: 10` on Google Sign-In | Add the build's SHA-1 to Firebase (Android) |
| Firebase "duplicate-app" warning | Harmless — caught and ignored in `mainCommon()` |
| Web build leaking secrets | Never bundle `.env` on web; use `--dart-define` |
| Google Sign-In fails on Windows/Linux | Unsupported there by design — use email/password |

More in [Troubleshooting](15-troubleshooting.md).
