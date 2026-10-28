# Troubleshooting

Problems met while building this, with what actually fixed them.

## "Couldn't load products"

Products come through the API, so check in this order:

1. Is `DESIGNWEAR_API_URL` set in `designwear/.env`, and is the API running? Open
   `<api>/v1/health`; it should answer `{"ok":true}`. `./run.sh` starts the API for you when the
   address is `http://localhost:<port>`.
2. Does the API reach the CMS? Check `designwear-server/.env` (`SETHUCMS_URL`,
   `SETHUCMS_CONNECTION_ID`, `SETHUCMS_TOKEN`). The first request after the gateway has been idle can take several seconds.
3. Is `/v1/products` empty? The shop hides remixes ("Remix by …", or anything with a
   "remixed from" field) and anything priced at ₹0.
4. After changing `.env`, **stop and restart** the run: it is bundled as an asset, so hot reload won't pick it up.

## Product photos are broken in the browser

The image CDN (Sanity) only allows browsers from origins on its own CORS list, so a page on
`localhost` or your own domain gets `403 CORS Origin not allowed`. On web the app loads
photos through the API (`/v1/img/…`). Keep the API running and make sure the web origin is in
`ALLOWED_ORIGINS` in production. To load photos directly instead, add your site under
*API → CORS origins* in the Sanity project settings.

## Flutter can't launch Chrome

Errors such as `Settings schema 'org.gnome.desktop.interface' does not have key …` or
`Failed to launch browser after 3 tries` come from the desktop session, not the app. In
`./run.sh` choose **Web in your own browser**: it serves the app and prints an address to
open in the browser you already use.

## "Address already in use"

Port 8080 is often taken (Jenkins and the SethuCMS gateway both default to it). `run.sh`
starts at 8081 and moves up to a free port. Pick one yourself with `WEB_PORT=9000 ./run.sh`.
If the **API** port 8787 is taken, something else is already listening there; `run.sh` reuses it.

## Phone can't sign in or load anything

- Android: forward the port, `adb reverse tcp:8787 tcp:8787`, and re-run it after unplugging.
- Release builds need an `https` API address; plain `http` only works for `localhost` in debug builds.
- iOS simulator uses the Mac's `localhost` directly.

## Web dev server logs `Bad state: No element` for `/assets/.env.local`

An empty (zero-byte) asset file. `run.sh` writes a comment line into empty `.env` and
`.env.local` files, and CI creates them with a comment instead of `touch`.

## Google button doesn't show

It appears only when the API is configured **and** the platform's `FIREBASE_*` values are
filled in. It is never shown on Linux or Windows. See
[accounts-and-sign-in.md](accounts-and-sign-in.md#setup).

## DesignBot says it isn't connected

The API needs `GEMINI_API_KEY`, and you need to be signed in. Check `/v1/config`: `designAgent`
should be `true`. If the model name is wrong the API returns an error; confirm `GEMINI_MODEL`
in Google AI Studio.

## Sign-in fails after an app update

The app id changed to `com.vishwamai.designwear` (from `com.example.designwear`), so a phone
with the old build treats the new one as a separate app: uninstall the old one. Old accounts,
carts and orders are not carried over.

## VS Code crashes or runs out of memory

Symptoms: "Application stopped: device memory is nearly full", tests killed with exit code 137.

- A `flutter build` leaves gigabytes in `build/`. Delete it (`rm -rf build`), it is regenerated.
- The workspace settings (`.vscode/settings.json`) stop VS Code watching `build/` and
  `.dart_tool/`, turn off Java/Gradle project import, and limit Dart analysis to `lib/` and
  `test/`. Reload the window after pulling them.
- End leftover Gradle daemons: `./android/gradlew --stop`.
- Stop `flutter run` when you aren't using it, close spare browser tabs, and run tests one
  file at a time: `flutter test --concurrency=1 test/<file>`.

## Tests

- A long wall of `google_fonts was unable to load font` lines in test output is harmless:
  there is no network and no bundled font in the test environment.
- A widget test failing with "A Timer is still pending" usually means something scheduled a
  delayed save; the shared app log doesn't write to disk or print during tests for this reason.
- A test that compares large byte arrays can print a huge diff. Compare bytes with
  `Buffer.equals(...)` (server) or `listEquals` (app) so a failure prints a short line.

## Gradle / Android build

- The per-flavour app name uses `resValue`, which needs `buildFeatures { resValues = true }`
  (already set in `android/app/build.gradle.kts`).
- The first build after an id change recompiles everything and takes a few minutes.
