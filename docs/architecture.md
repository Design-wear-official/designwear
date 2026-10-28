# Architecture

## Pieces

| Piece | Where | Does |
|---|---|---|
| **App** | this repo | all screens, on every platform |
| **DesignWear API** | `designwear-backend` repo | accounts, carts, orders, community designs, challenges, AI, image proxy |
| **SethuCMS** | your gateway | the product catalog (read-only from the app's point of view) |
| **Firebase Auth** | Google | only the Google sign-in step |
| **Gemini** | Google | the DesignBot, graphics and try-on, called by the API |

## Why the API sits in the middle

- **Secrets stay off devices.** The CMS token, the AI key and the payment secret are on
  the server. Anything shipped in an app (and `/assets/.env` on web) is public.
- **Prices are the server's.** An order is priced from the catalog (or the design price
  table) on the server; any price the app sends is ignored.
- **Browsers can't call the CMS or the image CDN directly** (their CORS lists don't include
  your site), so the API serves the catalog and proxies the photos.

## Data flow

**Browse.** App → `GET /v1/products` → API reads the CMS (cached 60 s) → only originals
with a price are returned. Remix records and ₹0 entries stay in the database but are hidden.

**Order.** App sends product ids, sizes and quantities and an address → API prices them,
checks stock and sizes → saves the order. Cash on delivery today.

**Design.** The Studio keeps a design as JSON on the device (auto-saved). Publishing sends
the JSON plus front and back PNG previews; the API stores them and lists the design in the
community feed. Remixing opens the stored JSON in the Studio.

**DesignBot.** App sends your message and the current design JSON → API adds its private
prompt and calls Gemini → returns text and, when the model made one, a new design → the
Studio applies it. There is exactly one chat bot.

**Google sign-in.** App signs in with Firebase → sends the ID token → API checks signature,
issuer, audience, expiry, provider and verified email → issues its own session.

## State

The API keeps accounts, carts, orders and designs in **one JSON file** (atomic writes) and
rate limits in memory, so it runs as **one process on a machine with a persistent disk**.
To scale out, replace `src/store.js` with a database first. See [deployment.md](deployment.md).

## App structure

- `api/` HTTP client with session handling and request logging.
- `data/` the product repository: API first, CMS fallback when a CMS token is configured.
- `services/` feature services (`auth`, `shop`, `ai`, `community`, `studio`, `app`).
- `screens/` one folder per feature; `screens/studio/editor` is the Design Studio itself.
- `presentation/` the original DesignWear theme and shared widgets (`image_proxy.dart` routes
  CDN photos through the API on web).
- `flavours/` per-flavour settings.
- Local mode: with no `DESIGNWEAR_API_URL`, accounts, carts and orders are kept on the device.

## Platform notes

| Platform | Notes |
|---|---|
| Web | product photos load through the API; session token is in browser storage |
| Android | release builds need `https`; debug allows `http://localhost` via `adb reverse` |
| iOS / macOS | Google sign-in needs the Firebase URL scheme in `Info.plist` |
| Linux / Windows | no Firebase Auth, so no Google sign-in; no 3D preview anywhere yet |
