# 14 · Deployment & CI/CD

DesignWear ships **four** things: the Flutter web app (Firebase Hosting), Android
& iOS builds, and the Next.js backend (Vercel). CI is GitHub Actions.

> The canonical CI reference is [CI_CD.md](CI_CD.md) (workflows, secrets, platform
> notes). This page covers the build/deploy commands and config.

---

## Build matrix

| Target | Entry point | Output | Notes |
|--------|-------------|--------|-------|
| Web | `lib/main.dart` | `build/web` | `--dart-define` config; deployed to Firebase Hosting |
| Android | `lib/main_external.dart` | `build/app/outputs/...` | `--flavor external` required |
| iOS | `lib/main.dart` | `build/ios` | No flavor schemes; `--no-codesign` in CI |
| Backend | — | `.next` | Next.js on Vercel |

---

## Web build & Firebase Hosting

### Local build
Use the project's [`build_web.sh`](../build_web.sh): it reads `.env` line-by-line
and converts each entry to a `--dart-define`, then runs
`flutter build web --release`. This keeps secrets out of the bundled assets.

```bash
./build_web.sh          # reads .env → --dart-define → build/web
# or manually:
flutter build web --release \
  --dart-define=USE_WEB_API=true \
  --dart-define=WEB_API_BASE_URL=https://designwear-backend.vishwamai.com/api \
  --dart-define=SANITY_PROJECT_ID=jh7llku7 \
  --dart-define=SANITY_DATASET=production
```

> **Web never bundles `.env`.** Always pass config via `--dart-define`. See
> [Configuration](04-configuration.md).

### Hosting config — [`firebase.json`](../firebase.json)
- `public: build/web`
- SPA rewrite: `**` → `/index.html`
- Long-cache (`max-age=31536000`) for `js|css|wasm`
- Security headers: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`

### Deploy
```bash
firebase deploy --only hosting           # manual
```
In CI this is automated:
- **`firebase-hosting-merge.yml`** — push to `master` → deploy to the **live**
  channel.
- **`firebase-hosting-pull-request.yml`** — PR → deploy to a **preview** channel.

Secret: `FIREBASE_SERVICE_ACCOUNT_DESIGNWEAR_731C9`.

---

## Android

```bash
flutter build apk       --flavor external -t lib/main_external.dart --release
flutter build appbundle --flavor external -t lib/main_external.dart --release
```

- The `internal`/`external` product flavors require `--flavor`.
- `android/app/google-services.json` is **gitignored**; CI recreates it from the
  base64 secret `GOOGLE_SERVICES_JSON`.
- For Google Sign-In, register the build's **SHA-1** in Firebase.
- Store-signed releases need an upload keystore wired into a release
  `signingConfig` (see [CI_CD.md](CI_CD.md) → "Extending to signed releases").

---

## iOS

```bash
flutter build ipa --flavor external -t lib/main_external.dart --release   # signed
flutter build ios --release --no-codesign                                  # CI verify
```

- No custom flavor schemes (only `Runner`); CI verifies compilation with
  `--no-codesign`.
- `ios/Runner/GoogleService-Info.plist` is **gitignored**; CI recreates it from
  `GOOGLE_SERVICE_INFO_PLIST`.

---

## Backend (Vercel)

[`vercel.json`](../designwear-backend/vercel.json):
- `framework: nextjs`, `buildCommand: npm run build`, output `.next`
- `installCommand: npm ci --legacy-peer-deps`
- Public env baked in: `NEXT_PUBLIC_SANITY_PROJECT_ID`,
  `NEXT_PUBLIC_SANITY_DATASET`, `NEXT_PUBLIC_SANITY_API_VERSION`,
  `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `GCP_PROJECT_ID`

**Secret** env (set in Vercel Project Settings, **not** committed):
`FIREBASE_SERVICE_ACCOUNT_KEY`, `SANITY_API_TOKEN`, `RAZORPAY_KEY_ID`,
`RAZORPAY_KEY_SECRET`, `GEMINI_API_KEY`. See
[Backend & API Reference](12-backend-and-api.md).

```bash
cd designwear-backend
npm run build && npm run start   # local production
# Vercel: push to the connected branch, or `vercel --prod`
```

The Sanity Studio deploys with the backend at `/designwear-studio`. The backend
also has its own CI at `designwear-backend/.github/workflows/ci.yml`.

---

## CI workflows (summary)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR, push to `master`, manual | Build-verify web + Android + iOS; `flutter analyze` + tests; upload artifacts |
| `firebase-hosting-merge.yml` | push to `master` | Deploy web to **live** Firebase channel |
| `firebase-hosting-pull-request.yml` | PR | Deploy web to **preview** channel |
| `create-issue.yml` | manual | Open a prioritized issue |

Required repo secrets: `FIREBASE_SERVICE_ACCOUNT_DESIGNWEAR_731C9`,
`GOOGLE_SERVICES_JSON`, `GOOGLE_SERVICE_INFO_PLIST`. All actions are pinned to
commit SHAs. Full details: [CI_CD.md](CI_CD.md).

---

## Pre-deploy checklist

- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Correct `--dart-define`s (especially `USE_WEB_API`, `WEB_API_BASE_URL`)
- [ ] No secrets in the web bundle (use `build_web.sh`)
- [ ] Firebase config files present in CI secrets (Android/iOS)
- [ ] Backend env set in Vercel (Firebase Admin, Sanity token, Razorpay, Gemini)
- [ ] `/health` returns `ok` after backend deploy
- [ ] Razorpay in the right mode (`rzp_test_` vs `rzp_live_`)
