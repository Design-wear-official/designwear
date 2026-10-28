# Getting started

## Requirements

- Flutter (stable channel) with the platforms you want to run.
- Node 20 or newer, for the API.
- For phones: a device or emulator, and `adb` for Android.

## 1. Check out both repositories side by side

```
~/designwear          the Flutter app   (github.com/Design-wear-official/designwear)
~/designwear-server   the API           (github.com/Design-wear-official/designwear-backend)
```

`run.sh` looks for the API in `../designwear-server`.

## 2. Configure

```sh
cd ~/designwear-server && cp .env.example .env
cd ~/designwear        && cp .env.example .env
```

- In `designwear-server/.env`: the SethuCMS address, connection id and token.
  This file is private and is **not** committed, and the Docker image excludes it.
- In `designwear/.env`: set `DESIGNWEAR_API_URL=http://localhost:8787`. Leave the
  `SETHUCMS_*` values blank: the app gets the catalog through the API.

Every setting is listed in [configuration.md](configuration.md).

## 3. Run

```sh
./run.sh
```

It asks for a flavour (`external` or `internal`) and a device:

| Choice | What it does |
|---|---|
| Linux desktop | runs the desktop build |
| Let Flutter choose | prompts if several devices are attached (phones, Chrome) |
| Web in your own browser | serves the app on a free port (it starts at 8081) and prints the address; use this if Chrome fails to launch from Flutter |

If `DESIGNWEAR_API_URL` points at this machine and nothing is listening, `run.sh` starts
the API from `../designwear-server` for the length of the run and stops it when you quit.

Run it by hand with:

```sh
flutter run --flavor external --dart-define=FLAVOR=external      # Android, iOS, macOS, Linux, Windows
flutter run -d web-server --dart-define=FLAVOR=external          # web: no --flavor flag
```

### On a phone

The phone's `localhost` is the phone, not your computer. Forward the API port over USB:

```sh
adb reverse tcp:8787 tcp:8787
```

Debug builds allow plain `http` to `localhost` only. Release builds require `https`. Run
it again if the app can't sign in after you replug the cable.

### In the browser

The API allows any `localhost` port in development. Product photos load through the API
(the image CDN refuses browsers from other origins), so keep the API running.

## 4. Test

```sh
flutter test --concurrency=1                 # app
cd ../designwear-server && node --test       # API
dart analyze lib test                        # static analysis
dart format --set-exit-if-changed lib test   # formatting
```

Running tests next to a heavy editor can exhaust memory on small machines. If VS Code
closes, see [troubleshooting.md](troubleshooting.md#vs-code-crashes-or-runs-out-of-memory).

## Regenerating the icons

The icon artwork is in `assets/images/` (`app_icon.png`, `app_icon_foreground.png`).

```sh
dart run flutter_launcher_icons
```
