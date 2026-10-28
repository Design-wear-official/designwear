# Deployment

Three things go live: the **API**, the **web app**, and the **mobile builds**. The API comes first, because the app is useless without it: the app carries no CMS token, so if the API is down there are no products.

## 1. The API (one always-on machine with a disk)

The API stores everything in one file and keeps rate limits in memory, so it must run as
**exactly one process on a persistent disk**. That rules out serverless hosts such as Vercel
Functions. It fits Fly.io, Railway, Render (with a disk) or a VPS with Docker.

The repository includes a `Dockerfile` and a `fly.toml` for Fly.io. The image was tested
locally against a root-owned data folder and production settings (health, saving a user,
running as an unprivileged user, refusing to start without secrets, no `.env` inside).
It has **not** been deployed yet.

```sh
cd designwear-server
fly launch --no-deploy --copy-config
fly volume create designwear_data --size 1 --region sin
fly secrets set \
  DESIGNWEAR_JWT_SECRET="$(openssl rand -base64 48)" \
  ALLOWED_ORIGINS="https://your-web-app.vercel.app" \
  MAIL_WEBHOOK_URL="https://your-mail-relay/hook" \
  SETHUCMS_URL=… SETHUCMS_CONNECTION_ID=… SETHUCMS_TOKEN=… \
  FIREBASE_PROJECT_ID=… GEMINI_API_KEY=… \
  DESIGNWEAR_ADMIN_TOKEN="$(openssl rand -base64 32)"
fly deploy --ha=false          # one machine only
```

Check `https://<app>.fly.dev/v1/health`, then `/v1/config` to see which features are on.

- **Password-reset email:** `MAIL_WEBHOOK_URL` receives `POST {to, subject, text}`. Use any
  small relay you control (Resend, Postmark or SES behind a tiny function). Production
  won't start without it.
- **Backups:** everything is `/data/store.json`. Take snapshots (`fly volumes snapshots`) or
  copy it with `fly ssh sftp get /data/store.json`.
- **Scaling later:** replace `src/store.js` with a database before running more than one machine.

## 2. The web app

Flutter web builds to static files, which suit Vercel (or any static host).

### Deploy with a Vercel token (GitHub Actions)

The `Deploy web (Vercel)` workflow builds the app and deploys `build/web` on every push to
`main` (or run it by hand from the Actions tab).

1. In Vercel, create a project (framework "Other") and a token: *Account Settings → Tokens*.
2. Find the project's ids: run `npx vercel link` once locally, then read `orgId` and
   `projectId` from `.vercel/project.json`. Don't commit that folder.
3. In GitHub: *Settings → Secrets and variables → Actions*, add secrets `VERCEL_TOKEN`,
   `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` and `DESIGNWEAR_API_URL` (your API's `https://` address).

`web/vercel.json` makes every path serve `index.html` (single-page app) and adds basic
security headers. To deploy from your machine instead:

```sh
# .env must contain DESIGNWEAR_API_URL=https://<your api>   (no CMS values)
flutter build web --release --dart-define=FLAVOR=external
VERCEL_TOKEN=… npx vercel deploy build/web --prod
```

Then add the site's address to the API's `ALLOWED_ORIGINS` (`fly secrets set ALLOWED_ORIGINS=…`).

The `.env` file is bundled into the build and is publicly downloadable, so it may only hold
public values. The release workflow writes it from the `DESIGNWEAR_API_URL` secret and
nothing else. This path hasn't been run end to end yet.

## 3. Mobile and desktop

- **Android:** the release workflow builds a signed APK (`external` flavour). Put the upload
  keystore in the repository secrets (see [ci-cd.md](ci-cd.md)). Without it the APK is signed
  with the debug key, fine for testing and not for the Play Store. Store publishing isn't set up.
- **iOS and macOS:** need your Apple signing and a bundle id registration for
  `com.vishwamai.designwear`. Not configured.
- **Windows and Linux:** build with `flutter build windows|linux`; no Firebase sign-in there.
- The app id changed from the old `com.example.designwear`, so a phone with an old build
  treats this as a separate app.

## 4. Before real users

1. In the **SethuCMS admin**: expose only `products` to the API, keep the connection
   read-only, then rotate the token and put the new one in the API's secrets.
2. API secrets set, `/v1/config` shows what you expect.
3. Create the first weekly challenge (see [api.md](api.md#admin)) if you want the Home banner.
4. Decide whether orders should also be written into SethuCMS. Today they are kept in the
   API's own store and do not reduce CMS stock.
5. Test on a phone, in a browser, and on one desktop platform.

### Google sign-in on the website

"Continue with Google" appears only when the build knows the Firebase project. Add these as
GitHub secrets (Firebase console → Project settings → Your apps → Web app → config; they
identify the project and are not private) and re-run **Deploy web (Vercel)**:

`FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_AUTH_DOMAIN`,
`FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID` (and optionally `FIREBASE_STORAGE_BUCKET`).

Also: enable the Google provider (Authentication → Sign-in method), add the site's domain
under Authentication → Settings → Authorized domains, and set `FIREBASE_PROJECT_ID` on the
API server (same project) so it accepts the sign-in.
