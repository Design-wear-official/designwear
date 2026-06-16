# CI/CD Pipelines

DesignWear ships to three targets — **web**, **Android**, and **iOS** — via GitHub
Actions. All actions are pinned to commit SHAs.

## Workflows

| File | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/ci.yml` | PR, push to `master`, manual | Build verification for **web + Android + iOS**, plus `flutter analyze` and tests. Uploads web build and the Android APK as artifacts. |
| `.github/workflows/firebase-hosting-merge.yml` | push to `master` | Builds web and deploys to the **live** Firebase Hosting channel. |
| `.github/workflows/firebase-hosting-pull-request.yml` | PR | Builds web and deploys to a **preview** Firebase Hosting channel. |
| `.github/workflows/create-issue.yml` | manual | Helper to open a prioritized issue. |

`ci.yml` only verifies that each platform compiles. Web *deployment* is handled
by the two `firebase-hosting-*` workflows.

## Required repository secrets

Add these under **Settings → Secrets and variables → Actions**.

| Secret | Used by | How to generate |
| --- | --- | --- |
| `FIREBASE_SERVICE_ACCOUNT_DESIGNWEAR_731C9` | web deploy | Firebase console → Project settings → Service accounts → generate key (JSON). |
| `GOOGLE_SERVICES_JSON` | Android build | `base64 -w0 android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | iOS build | `base64 -i ios/Runner/GoogleService-Info.plist` |

> `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
> are **gitignored** (they are Firebase secrets), so CI recreates them from the
> base64 secrets above before building. Without these secrets the Android/iOS
> jobs fail fast with a clear error.

`firebase.json` (Hosting config) **is** committed — the deploy action needs it
after checkout. It contains no secrets.

## Platform notes

- **Web** — entrypoint `lib/main.dart`. Built with `--no-wasm-dry-run` and
  `--dart-define`s for Sanity + the backend API URL. Output: `build/web`.
- **Android** — the app defines `internal`/`external` product flavors, so builds
  must pass `--flavor`. CI builds the **external** flavor via
  `lib/main_external.dart`. Output: `build/app/outputs/flutter-apk/`.
- **iOS** — no flavor schemes exist (only the default `Runner`), so it builds
  with `flutter build ios --release --no-codesign` from `lib/main.dart`. Signing
  / store upload is intentionally out of scope for build verification.

## Extending to signed releases

To produce store-ready artifacts later, add:

- **Android** — an upload keystore (as a base64 secret) wired into a release
  `signingConfig`, then `flutter build appbundle --flavor external`, optionally
  uploaded to Play via `r0adkll/upload-google-play`.
- **iOS** — an Apple distribution certificate + provisioning profile (via
  `apple-actions/import-codesign-certs`) and an App Store Connect API key, then
  `flutter build ipa` + `xcrun altool`/`fastlane` upload.
