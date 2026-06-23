# DesignWear — Documentation Hub

> AI-powered custom apparel e-commerce platform built with Flutter, backed by a
> Next.js + Sanity + Firebase backend.

This folder is the single entry point for all DesignWear documentation. Start
here, then dive into the area you need.

---

## 📚 Documentation Map

| # | Document | What it covers |
|---|----------|----------------|
| 01 | [Project Overview](01-overview.md) | What DesignWear is, feature list, tech stack, monorepo layout |
| 02 | [Getting Started](02-getting-started.md) | Prerequisites, install, environment setup, Firebase, running & building |
| 03 | [Architecture](03-architecture.md) | Clean architecture layers, data flow, build flavors, request lifecycle |
| 04 | [Configuration](04-configuration.md) | Every environment variable, config classes, demo mode, secrets |
| 05 | [Project Structure](05-project-structure.md) | Annotated directory tree of the whole monorepo |
| 06 | [Data Models](06-data-models.md) | Every model in `lib/models/` with fields and JSON shapes |
| 07 | [Services & State](07-services-and-state.md) | Services, use cases, repositories, Provider dependency injection |
| 08 | [Screens & Navigation](08-screens-and-navigation.md) | All screens, named routes, and navigation flows |
| 09 | [Design System](09-design-system.md) | Colors, typography, themes, dimensions, responsive utilities |
| 10 | [Design Studio](10-design-studio.md) | The drag-and-drop garment designer module, deep dive |
| 11 | [AI & Virtual Try-On](11-ai-and-virtual-tryon.md) | DesignBot, AI image generation, virtual try-on |
| 12 | [Backend & API Reference](12-backend-and-api.md) | Next.js backend, all REST endpoints, auth, payments |
| 13 | [Sanity CMS](13-sanity-cms.md) | Content schemas, datasets, studio |
| 14 | [Deployment & CI/CD](14-deployment-and-ci.md) | Web/Android/iOS builds, Firebase Hosting, Vercel, GitHub Actions |
| 15 | [Troubleshooting](15-troubleshooting.md) | Common issues and fixes |
| 16 | [Design Studio — Build Roadmap](16-design-studio-roadmap.md) | Current-state assessment + phased plan to complete the Design Studio |

### Existing topical docs (kept as-is)

| Document | Notes |
|----------|-------|
| [DESIGN_STUDIO_FEATURES.md](DESIGN_STUDIO_FEATURES.md) | Feature changelog for the Design Studio |
| [DESIGN_BOT_AI_FEATURES.md](DESIGN_BOT_AI_FEATURES.md) | DesignBot image-attachment feature notes |
| [CI_CD.md](CI_CD.md) | CI/CD pipeline notes |
| [Flutter App Security Development Roadmap.md](Flutter%20App%20Security%20Development%20Roadmap.md) | Security roadmap |
| [Flutter Overflow Pixel Prevention Guide.md](Flutter%20Overflow%20Pixel%20Prevention%20Guide.md) | Layout overflow guide |
| [flutter-barrel-imports.md](flutter-barrel-imports.md) | Barrel-import conventions |

---

## ⚡ TL;DR for new contributors

```bash
# 1. Install deps
flutter pub get

# 2. (Optional) configure secrets — without them the app runs in Demo Mode
cp .env.example .env       # then edit

# 3. Run
flutter run                                   # default (external flavor)
flutter run --flavor internal -t lib/main_internal.dart   # dev flavor
```

- **No keys?** The app falls back to public/demo data — every screen still works.
- **Where does data come from?** Either the **Next.js backend** (`USE_WEB_API=true`)
  or **Sanity CMS directly** (default). See [Architecture](03-architecture.md).
- **Two apps in one repo:** the Flutter client (`lib/`) and the backend
  (`designwear-backend/`). See [Project Structure](05-project-structure.md).

---

## 🧭 Quick links to source

| Area | Path |
|------|------|
| App entry point | [`lib/main.dart`](../lib/main.dart) |
| Configuration | [`lib/config/`](../lib/config) |
| Models | [`lib/models/`](../lib/models) |
| Services | [`lib/services/`](../lib/services) |
| Screens | [`lib/screens/`](../lib/screens) |
| Design system | [`lib/presentation/`](../lib/presentation) |
| Backend API | [`designwear-backend/app/api/`](../designwear-backend/app/api) |
| Sanity schemas | [`designwear-backend/sanity/schemaTypes/`](../designwear-backend/sanity/schemaTypes) |

> **Conventions:** This documentation reflects the code as of the current branch.
> When code and docs disagree, the code is authoritative — please update the docs
> in the same PR that changes behavior.
