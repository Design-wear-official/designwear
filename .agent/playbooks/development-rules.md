---
description: Essential CLI patterns and component boundary rules for interacting with the codebase.
---

# Development Execution Rules

When executing actions, tests, or deploying code across this monorepo, adhere strictly to these scoped command paradigms:

## Directory Isolation
> [!WARNING]
> This is a monorepo. Never install Node dependencies at the root `/`. The codebase expects rigid structural isolation.

- **Flutter Rules (`/lib`, `/android`, `/ios`)**
  - Run `flutter pub get` exclusively in the repository root.
  - Commands resolving flutter builds must explicitly utilize the correct flavor unless instructed otherwise (e.g., `flutter run --flavor internal -t lib/main.dart`).
  - Native permissions or package integrations should be modified cleanly through standard tools (e.g., Gradle, Info.plist). DO NOT hardcode `.env` secrets into native source files.

- **Backend Rules (`/designwear-backend`)**
  - Run all `npm install`, `npm run dev`, or `npx` commands entirely inside `cd designwear-backend`.
  - When debugging Sanity datasets or deploying updates to schemas, always assert that `SANITY_PROJECT_ID` is accurately populated in the backend's `.env.local`.

- **SDK Rules (`/designwear-sdk`)**
  - Before testing downstream SDK dependents, always run `npm run build` inside `cd designwear-sdk` to force TypeScript to transpile out to the `/dist` layer.
  - Type definitions are heavily prioritized. If altering the SDK API surface, forcefully run `npm run build:check` to rigorously assess types prior to creating an artifact.
