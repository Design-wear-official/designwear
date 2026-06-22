# Firebase Hosting Environment Configuration Playbook

## The Core Problem

Firebase Hosting has `"**/.*"` in its default `ignore` array inside `firebase.json`. This strips every
dotfile — including `.env`, `.env.local` — before uploading. Even if those files are listed as Flutter
assets in `pubspec.yaml`, `rootBundle.loadString('.env')` returns a 404 at runtime, `flutter_dotenv`
silently skips the load (because `isOptional: true`), and `dotenv.isInitialized` stays `false`.

Any code that then reads `dotenv.env[key]` throws:

```
NotInitializedError: DotEnv has not been initialized.
Call load() or loadFromString() before accessing env variables.
```

This cascades into Firebase failing to init → `FirebaseAuth` being null → a null-check crash on the
login screen.

**Do NOT remove `"**/.*"` from `firebase.json`** to "fix" this. `.env` contains `RAZORPAY_KEY_SECRET`,
`GEMINI_API_KEY`, and other server-side secrets that must never be served publicly.

Serving an `assets/env.json` file (the old approach documented here) has the same problem — the file
is publicly downloadable at `/assets/assets/env.json` by anyone.

---

## The Correct Solution: `--dart-define-from-file`

Flutter's `--dart-define-from-file` flag reads a **gitignored** JSON file and bakes every value
directly into `main.dart.js` at compile time via `String.fromEnvironment()`. No separate file is
ever served; values are compiled in. Firebase Hosting never sees the config file.

```
Local machine            Build step            Deployed bundle
config/env.web.json  →   flutter build web  →  main.dart.js (values compiled in)
(gitignored)             --dart-define-         No separate config file exists
                         from-file=...
```

---

## File Structure

```
designwear/
├── config/
│   └── env.web.json          ← gitignored; never committed; used only at build time
├── lib/
│   ├── config/app_config.dart  ← ConfigLoader reads String.fromEnvironment()
│   └── firebase_options.dart   ← uses ConfigLoader.get() for all platforms
├── .env                        ← mobile/desktop only (filesystem, never bundled)
├── .env.local                  ← mobile/desktop overrides
├── pubspec.yaml                ← .env/.env.local NOT in assets
└── firebase.json               ← "**.*" ignore stays (correct)
```

---

## Implementation

### 1. `config/env.web.json` (gitignored)

Contains all web-facing config. **Never include server-side secrets** (e.g. `RAZORPAY_KEY_SECRET`,
backend signing keys). Firebase keys are safe — they are public client identifiers; security is
enforced by Firebase Security Rules, not by hiding the keys.

```json
{
  "SANITY_PROJECT_ID": "jh7llku7",
  "SANITY_DATASET": "production",
  "APP_NAME": "Design Wear",
  "DEBUG_MODE": "false",
  "DATA_SOURCE": "sanity",
  "ENABLE_FALLBACK": "true",
  "USE_WEB_API": "true",
  "WEB_API_BASE_URL": "https://designwear-backend.vishwamai.com/api",
  "API_TIMEOUT_SECONDS": "30",
  "GEMINI_API_KEY": "<from secret store>",
  "RAZORPAY_KEY_ID": "<public key — safe>",
  "FIREBASE_PROJECT_ID": "designwear-731c9",
  "FIREBASE_API_KEY": "<web api key>",
  "FIREBASE_APP_ID": "1:653328426569:web:005abd63cc23b9a7628198",
  "FIREBASE_WEB_API_KEY": "<web api key>",
  "FIREBASE_WEB_APP_ID": "1:653328426569:web:005abd63cc23b9a7628198",
  "FIREBASE_MESSAGING_SENDER_ID": "653328426569",
  "FIREBASE_STORAGE_BUCKET": "designwear-731c9.firebasestorage.app",
  "FIREBASE_ANDROID_API_KEY": "<android api key>",
  "FIREBASE_ANDROID_APP_ID": "1:350351347585:android:17a893404ea99d6fafe280",
  "FIREBASE_IOS_API_KEY": "<ios api key>",
  "FIREBASE_IOS_APP_ID": "1:653328426569:ios:c4a0bf64daf45268628198",
  "FIREBASE_IOS_BUNDLE_ID": "",
  "FIREBASE_WINDOWS_APP_ID": ""
}
```

### 2. `.gitignore`

```
# Web build-time env (contains API keys — never commit)
config/env.web.json
config/env.*.json
```

### 3. `lib/config/app_config.dart` — ConfigLoader

Every key used anywhere in the app must have a `String.fromEnvironment()` entry in `_dartDefines`.
At build time, `--dart-define-from-file` populates these. On mobile, dotenv is the fallback.

```dart
static const Map<String, String> _dartDefines = {
  'SANITY_PROJECT_ID':            String.fromEnvironment('SANITY_PROJECT_ID'),
  'FIREBASE_WEB_API_KEY':         String.fromEnvironment('FIREBASE_WEB_API_KEY'),
  'FIREBASE_WEB_APP_ID':          String.fromEnvironment('FIREBASE_WEB_APP_ID'),
  'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  // ... all other keys
};

static String? get(String key) {
  final injected = _dartDefines[key];
  if (injected != null && injected.isNotEmpty) return injected;
  if (dotenv.isInitialized) return dotenv.env[key];
  return null;
}
```

### 4. `lib/firebase_options.dart`

Check `kIsWeb` **before** the `defaultTargetPlatform` switch. On Chrome/Windows,
`defaultTargetPlatform` returns `TargetPlatform.windows` even for web builds — without the
`kIsWeb` guard, the wrong getter runs.

```dart
static FirebaseOptions get currentPlatform {
  if (kIsWeb) return web;           // ← must be first
  switch (defaultTargetPlatform) {
    case TargetPlatform.android: return android;
    case TargetPlatform.iOS:     return ios;
    // ...
  }
}

static FirebaseOptions get web => FirebaseOptions(
  apiKey:            _get('FIREBASE_WEB_API_KEY'),
  appId:             _get('FIREBASE_WEB_APP_ID'),
  messagingSenderId: _get('FIREBASE_MESSAGING_SENDER_ID'),
  projectId:         _get('FIREBASE_PROJECT_ID'),
  storageBucket:     _get('FIREBASE_STORAGE_BUCKET'),
  authDomain:        '${_get('FIREBASE_PROJECT_ID')}.firebaseapp.com',
);
```

### 5. `lib/main.dart` — dotenv loading

```dart
// Web: dotenv is never loaded — Firebase Hosting strips dotfiles.
// Values come from --dart-define-from-file baked into main.dart.js at build time.
// Mobile/Desktop: load from filesystem .env files.
if (!kIsWeb) {
  await dotenv.load(fileName: ".env", isOptional: true);
  await dotenv.load(
    fileName: ".env.local",
    isOptional: true,
    mergeWith: Map<String, String>.from(dotenv.env), // copy, not live reference
  );
}
```

> **`mergeWith: dotenv.env` bug**: `dotenv.load()` calls `clean()` at the start which clears
> `_envMap`. Passing `dotenv.env` (a live reference to `_envMap`) as `mergeWith` means the map
> is cleared before it can be merged. Always pass `Map.from(dotenv.env)` to merge a snapshot.

### 6. `pubspec.yaml` — remove `.env` from assets

```yaml
flutter:
  assets:
    - assets/images/
    - assets/system_prompt.txt
    # .env and .env.local must NOT be listed here.
    # On web they are never served (Firebase Hosting strips dotfiles).
    # On mobile they are loaded from the filesystem, not the asset bundle.
```

---

## Build Commands

```bash
# Local dev (web)
flutter run -d chrome --dart-define-from-file=config/env.web.json

# Production build
flutter build web --release --dart-define-from-file=config/env.web.json

# Deploy
firebase deploy --only hosting
```

---

## CI/CD (GitHub Actions)

Store the entire JSON blob as one repository secret `WEB_ENV_JSON`:

```yaml
- name: Build Flutter web
  run: |
    mkdir -p config
    echo '${{ secrets.WEB_ENV_JSON }}' > config/env.web.json
    flutter build web --release --dart-define-from-file=config/env.web.json

- name: Deploy to Firebase
  run: firebase deploy --only hosting --token ${{ secrets.FIREBASE_TOKEN }}
```

---

## Security Classification

| Value | In `config/env.web.json`? | Reason |
|---|---|---|
| Firebase API keys / App IDs | ✅ Yes | Public client identifiers; security via Security Rules |
| Sanity project ID | ✅ Yes | Already visible in every CDN request URL |
| Backend API URL | ✅ Yes | Not a secret |
| Razorpay key_id | ✅ Yes | Public merchant identifier |
| Gemini API key | ⚠️ Dev only | Risk: API quota abuse; use backend proxy in production |
| Razorpay key_secret | ❌ Never | Server-side only — used to sign payment requests |
| Backend signing tokens | ❌ Never | Server-side only |

---

## Troubleshooting

### `NotInitializedError: DotEnv has not been initialized`

**Cause**: Something reads `dotenv.env[key]` on web where dotenv is never loaded.  
**Fix**: Ensure all web code paths go through `ConfigLoader.get()`, which guards with
`dotenv.isInitialized` before touching `dotenv.env`.

### Firebase init failed / null check crash on login

**Cause**: `firebase_options.dart` hit the `windows` case on Chrome/Windows, which called
`dotenv.env[...]` directly (not through ConfigLoader).  
**Fix**: Add `if (kIsWeb) return web;` at the top of `currentPlatform`, before the switch.

### Empty values in deployed app

**Cause**: Build ran without `--dart-define-from-file`, so all `String.fromEnvironment()` calls
returned `''`.  
**Fix**: Always build with `--dart-define-from-file=config/env.web.json`.

### Values present locally but empty after deploy

**Cause**: CI pipeline didn't write `config/env.web.json` before the build step.  
**Fix**: Add the secret injection step before `flutter build web`.

---

## Related Files

| File | Purpose |
|---|---|
| `config/env.web.json` | Web build-time config (gitignored) |
| `.env` / `.env.local` | Mobile/desktop config (gitignored, filesystem only) |
| `lib/config/app_config.dart` | `ConfigLoader` — single source of truth for all config |
| `lib/firebase_options.dart` | Firebase platform options using `ConfigLoader.get()` |
| `lib/main.dart` | dotenv loading (mobile/desktop only) |
| `pubspec.yaml` | Asset declarations (`.env` must NOT be listed) |
| `firebase.json` | Hosting config — `"**/.*"` ignore must stay |

---

**Last Updated**: 2026-06-22
**Flutter**: 3.x / Dart 3.x
**firebase-tools**: 15.x
**Status**: ✅ Production-ready
