# Security

- **Content** comes from the SethuCMS gateway (`lib/cms/`). Put only a **read-only viewer
  token** in `.env` (`SETHUCMS_VIEWER_TOKEN`) and expose only `products` to it. The token
  ships inside the app (and `/assets/.env` on web), so assume it is public.
- **Accounts, carts, orders, community designs, search and AI** go through the DesignWear
  API (`~/designwear-server`, set `DESIGNWEAR_API_URL`). It hashes passwords, prices orders
  itself, rate-limits, and keeps the AI/payment keys; none of those keys are in the app.
- Without `DESIGNWEAR_API_URL` the app runs on-device only (local accounts and orders).
- The session token is stored with `shared_preferences` (browser storage on web). Sign out
  on shared devices.
- Set `ALLOWED_ORIGINS` on the API and `SETHUCMS_ALLOWED_ORIGINS` on the gateway to your web origin only.
- Never commit `.env`, keystores or signing files (all gitignored).

## Google sign-in (Firebase)
Firebase is used only for the Google login; the API then issues the app's own session.

1. Firebase console: create a project, enable **Authentication → Google**, add your web
   domain under Authorized domains, and register the Android/iOS/web apps.
2. Android: register the app as `com.vishwamai.designwear` (the internal flavour is
   `com.vishwamai.designwear.internal`) and add the debug and release **SHA-1/SHA-256**
   fingerprints. iOS and macOS bundle id: `com.vishwamai.designwear`.
   iOS: add the app's URL scheme (`app-1-<project number>-ios-<hash>`) to Info.plist.
3. Copy the app values into `.env` (see `.env.example`, `FIREBASE_*`; the internal flavour
   uses `FIREBASE_INTERNAL_*`), and set `FIREBASE_PROJECT_ID` on the API server to the same project.
4. Until all of that is filled in the "Continue with Google" button stays hidden. Linux and
   Windows don't support Firebase Auth, so the button never shows there.

Firebase web config is public by design (it identifies the project). The API verifies every
Google token itself, so a forged or other-project token is rejected.
