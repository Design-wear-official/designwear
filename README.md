# DesignWear

Design-and-remix T-shirt commerce. Browse the catalog, design your own garment in the
**Design Studio** (front, back and both sleeves), get help from the **DesignBot**
assistant, publish to the community, join weekly challenges, and order.

One Flutter codebase for **Android, iOS, web, Windows, macOS and Linux**, backed by the
**DesignWear API** (Node, separate repo) and **SethuCMS** for the product catalog.

```
                    ┌────────────────────────────┐
 Flutter app ─HTTPS─►  DesignWear API (Node)     ├──► SethuCMS gateway ──► your database
 (web / mobile /    │  accounts, carts, orders,  │      (catalog, read-only)
  desktop)          │  designs, challenges, AI   ├──► Gemini (assistant, graphics, try-on)
                    └──────────┬─────────────────┘
        Google sign-in         └──► image CDN (proxied for browsers)
 app ► Firebase Auth ► ID token ► API verifies it and issues its own session
```

The app never holds a CMS token or an AI key: everything secret lives on the API server.
See [docs/architecture.md](docs/architecture.md).

## Features

- **Shop:** home with featured and all products, search with suggestions, product page
  with sizes, cart, checkout (cash on delivery), order history, saved addresses.
- **Design Studio:** layers, colours, text, emoji and your own stickers, templates, undo/redo,
  snap guides, keyboard shortcuts, front/back/left/right views. See
  [docs/design-studio.md](docs/design-studio.md).
- **DesignBot:** the one chat bot. Ask for a design in plain words and it edits your design.
- **Community:** publish designs, like, remix (with a visible lineage), weekly challenges
  with a leaderboard.
- **Virtual try-on** with a catalog product or your own design.
- **Accounts:** email and password, password reset by emailed code, or Google sign-in.
  See [docs/accounts-and-sign-in.md](docs/accounts-and-sign-in.md).
- **Diagnostics:** local log viewer, with opt-out reporting of warnings and errors.
- **Two flavours** (`external`, `internal`) that install side by side.

## Quick start

You need Flutter (stable) and Node 20 or newer.

```sh
git clone https://github.com/Design-wear-official/designwear.git
git clone https://github.com/Design-wear-official/designwear-backend.git designwear-server   # sibling folder

cd designwear-server && cp .env.example .env     # fill in the CMS settings (see docs/configuration.md)
cd ../designwear && cp .env.example .env         # set DESIGNWEAR_API_URL=http://localhost:8787
./run.sh                                         # pick flavour and device; it starts the API for you
```

`run.sh` offers Linux desktop, "let Flutter choose" (phones, Chrome) and **web in your own
browser** (it picks a free port). Details and the phone setup are in
[docs/getting-started.md](docs/getting-started.md).

## Tests

```sh
flutter test --concurrency=1           # app: 72 tests
cd ../designwear-server && node --test  # API: 29 tests
```

## Project layout

```
lib/
  api/          HTTP client for the DesignWear API
  cms/          direct SethuCMS client (optional fallback)
  data/         product repository (API first, CMS fallback)
  flavours/     per-flavour title, banner and settings
  logging/      local log + remote reporting
  models/       Product, orders, designs, challenges
  presentation/ original DesignWear theme, shared widgets
  screens/      account, ai, cart, catalog, errors, home, orders, settings, studio
  services/     ai, app, auth, community, shop, studio
  theme/        theme wrapper and colour helpers
test/           unit, widget and layout tests
docs/           documentation
```

## Documentation

| | |
|---|---|
| [Getting started](docs/getting-started.md) | set up, run on every platform, phone and web tips |
| [Architecture](docs/architecture.md) | how the pieces fit, data flow, why the choices |
| [Configuration](docs/configuration.md) | every environment setting, app and server |
| [Design Studio](docs/design-studio.md) | editor, views, DesignBot, publishing |
| [Accounts and sign-in](docs/accounts-and-sign-in.md) | login, reset, Google sign-in setup |
| [API](docs/api.md) | endpoints, auth, limits |
| [Deployment](docs/deployment.md) | host the API and the web app |
| [CI/CD](docs/ci-cd.md) | workflows, releases, secrets |
| [Troubleshooting](docs/troubleshooting.md) | problems we hit and their fixes |
| [Security](SECURITY.md) | what is protected and what you must configure |

## Branches and repositories

- `main` is the rewrite described here. `master` keeps the previous app for reference.
- The API server is the `designwear-backend` repository (`main`), checked out as a sibling
  folder `designwear-server` for local development.
- The app id is `com.vishwamai.designwear` (the internal flavour adds `.internal`).
