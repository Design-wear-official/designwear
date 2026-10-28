# Security

## How secrets are handled

| Secret | Where it lives | Why |
|---|---|---|
| CMS token | `designwear-server/.env` (API only) | anything bundled with the app, including `/assets/.env` on web, is public |
| Gemini key, Razorpay secret, JWT secret, admin token | the API's environment | never reach a device |
| Firebase app values | the app's `.env` | public by design; the API verifies every token itself |

`.env` files, keystores and signing files are git-ignored, and the API's Docker image excludes
its `.env`. The release workflow writes only `DESIGNWEAR_API_URL` into the app's bundled `.env`.

## What the API enforces

- Passwords are hashed with scrypt; sessions are signed tokens that a password change or reset invalidates.
- Orders are priced on the server from the catalog; prices sent by the app are ignored.
  Users can only read and change their own orders, carts, addresses and designs.
- Google sign-in tokens are verified by the API (signature, issuer, audience, expiry, Google
  provider, verified email). A different Google account can't take over a linked email.
- Rate limits on sign-up, sign-in, reset, orders, publishing, AI and photos; login and reset
  answers don't reveal whether an email has an account.
- CORS allows only the configured origins; the photo proxy only fetches allow-listed image
  hosts and strictly validated paths.
- Error reports from the app are redacted (tokens, passwords, emails) on the device and again on the server.
- In production the API refuses to start without a strong JWT secret, allowed origins and a mail webhook.

Details: [docs/api.md](docs/api.md#rules-the-server-enforces).

## What you must configure

1. **SethuCMS admin (needed now).** The token the app used before could read every
   collection, including `customers`, `orders` and `carts`. Expose only `products` to the
   API, keep the connection read-only, then **rotate the token** and put the new one in the
   API's `.env`. Until you do, anyone holding any token for that connection can read those collections.
2. **Production settings** on the API: `DESIGNWEAR_JWT_SECRET`, `ALLOWED_ORIGINS`,
   `MAIL_WEBHOOK_URL`. See [docs/deployment.md](docs/deployment.md).
3. **Google sign-in** (optional): see [docs/accounts-and-sign-in.md](docs/accounts-and-sign-in.md#setup).
4. If something calls the CMS gateway straight from a browser, set its own allowed origins
   (`SETHUCMS_ALLOWED_ORIGINS`) to your web origin only. The app itself no longer does this.

## Known limits

- The session token is kept in `shared_preferences` (browser storage on web). Sign out on shared devices.
- The API stores data in one file and keeps rate limits in memory, so it must run as a single
  process; back up `/data/store.json`.
- Orders live in the API's own store, not in SethuCMS, and online payments aren't switched on in the app yet.
- Without `DESIGNWEAR_API_URL` the app runs on-device only (local accounts, hashed but on the same device as their data).
- The GitHub Actions workflows haven't been observed running yet.

## Reporting a problem

Please use GitHub's private vulnerability reporting (Security tab → *Report a vulnerability*)
on the relevant repository rather than opening a public issue.
