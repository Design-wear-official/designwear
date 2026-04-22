---
description: Comprehensive overview of the Designwear Monorepo architecture and component context
---

# Designwear Monorepo Context

This repository is built as a complete e-commerce solution with distinct internal domains.

## 1. Flutter Mobile Application (`lib`, `android`, `ios`)
The mobile application handles the entire end-user shopping, design, and trying-on experience.
- **Language**: Dart / Flutter
- **State Management**: Provider
- **Key Integrations**: 
  - **Firebase** (Auth, Crashlytics, Messaging, Realtime DB)
  - **Sanity headless CMS** (Packages via `flutter_sanity` interface)
  - **Google Gemini 3.1** (`firebase_ai` integrations for the Virtual Try-On and chat assistant)
  - **Razorpay** (`razorpay_flutter` for checkout)
- **Deployment Mechanics**: Built structurally via flavors (`internal`, `dev`, `prod`). Relies extensively on an explicitly formatted assets directory (`assets/`, `assets/images`) and a root `.env` file for API resolution.

## 2. Next.js CMS & Backend API (`designwear-backend`)
A centralized server-side repository hosting the Sanity CMS schema models and the Firebase Admin interfaces.
- **Stack**: Next.js 16 (App Router), React 19, TypeScript
- **Styling**: TailwindCSS & `styled-components`
- **Key Integrations**: 
  - **@sanity/vision** and **next-sanity** to operate the catalog management interface natively.
  - **@google/genai** to expose custom multimodal models.
  - **Razorpay API** (Node implementation) and **Firebase Admin**.
- **Run Mechanics**: `npm run dev` running on `localhost:3000`. Relies on a `.env.local` to resolve `NEXT_PUBLIC_SANITY_PROJECT_ID` schemas.

## 3. TypeScript Platform SDK (`designwear-sdk`)
A self-contained NPM package to provide programmatic access to the backend systems for external microservices or custom logic platforms.
- **Stack**: Pure TypeScript compiled down to Node 18+ compliant ES Modules and CommonJS (`dist`).
- **Run Mechanics**: `npm run build` compiles `index.ts` to Javascript using `tsc`.
