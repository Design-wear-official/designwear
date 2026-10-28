# Configuration

Settings are plain environment variables. Nothing secret goes in the app.

## The app: `designwear/.env`

The file is bundled into the app as an asset (and is publicly downloadable on web), so it
may only hold public values. `.env.local` is an optional personal override and is ignored by git.

| Setting | Purpose |
|---|---|
| `DESIGNWEAR_API_URL` | Address of the DesignWear API, for example `http://localhost:8787` or your deployed `https://…`. Empty means the app runs on-device only. |
| `DESIGNWEAR_INTERNAL_API_URL` | Same, for the internal flavour. |
| `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET` | Firebase project, used only for Google sign-in. |
| `FIREBASE_{WEB,ANDROID,IOS,MACOS}_API_KEY` and `_APP_ID`, `FIREBASE_{IOS,MACOS}_BUNDLE_ID` | Per-platform Firebase app values. The Google button stays hidden until the ones for the platform you run on are filled in. The internal flavour uses the same names with a `FIREBASE_INTERNAL_` prefix. |
| `SETHUCMS_URL`, `SETHUCMS_CONNECTION_ID`, `SETHUCMS_VIEWER_TOKEN` | Optional direct CMS access. **Leave blank.** The API holds the CMS credentials. |

Flavours are chosen at launch with `--dart-define=FLAVOR=external|internal`.

## The API: `designwear-server/.env`

Loaded by the server itself (`node --env-file-if-exists=.env`). Private; never committed.

| Setting | Required | Purpose |
|---|---|---|
| `PORT`, `HOST` | no | Default port 8787. Host defaults to `127.0.0.1`, or `0.0.0.0` in production. |
| `NODE_ENV` | no | `production` turns on the safety checks below. |
| `DESIGNWEAR_JWT_SECRET` | production | 32+ random characters; signs sessions. |
| `ALLOWED_ORIGINS` | production | Comma-separated web origins allowed to call the API. In development any `localhost` port is allowed. |
| `MAIL_WEBHOOK_URL` | production | Receives `POST {to, subject, text}` to send password-reset codes. |
| `SETHUCMS_URL`, `SETHUCMS_CONNECTION_ID`, `SETHUCMS_TOKEN` | for the catalog | The CMS the API reads products from. Use a read-only token. |
| `FIREBASE_PROJECT_ID` | for Google sign-in | The project whose ID tokens are accepted. Unset: `POST /v1/auth/google` answers 404. |
| `GEMINI_API_KEY` | for AI | Turns on the assistant, graphics and try-on. |
| `GEMINI_MODEL` | no | Text model for the assistant (default `gemini-4-argon`; confirm the id in Google AI Studio). |
| `GEMINI_IMAGE_MODEL` | no | Image model for graphics and try-on (default `gemini-2.5-flash-image`). |
| `DESIGNWEAR_ADMIN_TOKEN` | no | 24+ characters. Enables `PUT /v1/admin/challenges/:id`. Unset: those routes don't exist. |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | no | Server side of online payments. The app currently offers cash on delivery only. |
| `IMAGE_HOSTS` | no | Image CDN hosts the API may fetch for browsers (default `cdn.sanity.io`). |
| `DESIGNWEAR_DATA_FILE`, `DESIGNWEAR_CLIENT_LOG_FILE` | no | Where state and client reports are stored. |
| `TRUST_PROXY` | no | Set to `1` only behind a proxy you control (uses `X-Forwarded-For` for rate limits). |

In production the server **refuses to start** without `DESIGNWEAR_JWT_SECRET`,
`ALLOWED_ORIGINS` and `MAIL_WEBHOOK_URL`.

## Where does each secret live?

| Secret | Lives on | Never in |
|---|---|---|
| CMS token | API server | the app, the web `.env`, CI builds of the app |
| Gemini key | API server | the app |
| Razorpay secret | API server | the app |
| JWT secret | API server | anywhere else |
| Firebase app values | the app `.env` | (public by design; the API verifies every token itself) |
