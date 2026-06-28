---
description: How to run the Flutter app and Next.js backend with flavors
---

# Running DesignWear

**Flutter:** 3.44.1 (stable) · **Gradle:** 8.14 · **Next.js:** 16.2.9

---

## Flutter App

The Flutter app uses two product flavors: `internal` and `external`.  
You must always pass `--flavor` and `-t` together — omitting either will fail.

### Run (debug)

```bash
# Internal flavor (appId: com.vishwamai.designwear.internal)
flutter run --flavor internal -t lib/main_internal.dart

# External flavor (appId: com.vishwamai.designwear)
flutter run --release --flavor external -t lib/main_external.dart --dart-define-from-file=config/env.web.json
```

### Run (release)

```bash
flutter run --release --flavor internal -t lib/main_internal.dart
flutter run --release --flavor external -t lib/main_external.dart
```

### Build APK

```bash
flutter build apk --flavor internal -t lib/main_internal.dart
flutter build apk --flavor external -t lib/main_external.dart
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --flavor external -t lib/main_external.dart
```

---

## Next.js Backend (`designwear-backend/`)

```bash
cd designwear-backend

# Development server (http://localhost:3000)
npm run dev

# Production build
npm run build

# Start production server (after build)
npm run start

# Lint
npm run lint
```

> Required env vars: `FIREBASE_SERVICE_ACCOUNT_KEY`, `FIREBASE_API_KEY`,
> `NEXT_PUBLIC_SANITY_PROJECT_ID`, `NEXT_PUBLIC_SANITY_DATASET`,
> `NEXT_PUBLIC_FIREBASE_PROJECT_ID` — set in `.env.local` or Vercel dashboard.

---

## Troubleshooting

**`Unresolved reference: filePermissions`** — update `android/gradle/wrapper/gradle-wrapper.properties` to `gradle-8.14-all.zip` and sync `android/settings.gradle.kts`.

**`Another next build process is already running`** — delete `.next/` and retry:
```bash
rm -rf designwear-backend/.next && npm run build
```

**Firebase Admin `auth` not found** — all routes import `{ auth }` from `@/lib/config/database`, not `firebase-admin` directly. Set `FIREBASE_SERVICE_ACCOUNT_KEY` in env.
