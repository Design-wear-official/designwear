# 12 · Backend & API Reference

The backend lives in [`designwear-backend/`](../designwear-backend) — a **Next.js
16 (App Router)** app that serves the REST API **and** hosts the **Sanity
Studio**. It uses **Firebase Admin** (Firestore + ID-token verification),
**Razorpay** (payments), **Sanity** (content), and **Gemini** (AI).

Backend internals (architecture, sync, algorithms) are also documented in
[`designwear-backend/docs/`](../designwear-backend/docs).

---

## Stack & layout

| Concern | Tech |
|---------|------|
| Framework | Next.js 16 App Router, React 19, TypeScript (strict) |
| Data / Auth | Firebase Admin SDK → **Firestore** + **Auth** + **Messaging** |
| Content | Sanity (`@sanity/client`, `next-sanity`) |
| Payments | `razorpay` server SDK |
| AI | `@google/genai` + direct Gemini REST |
| Logging | Winston (`lib/utils/logger.ts`) |
| Hosting | Vercel (`vercel.json`) |

```
designwear-backend/
├── app/api/**/route.ts        # REST handlers (catalog below)
├── app/designwear-studio/     # embedded Sanity Studio (/designwear-studio)
├── lib/config/database.ts     # Firebase Admin: db, auth, messaging (lazy proxies)
├── lib/services/syncService.ts
├── lib/notifications.ts  lib/utils/logger.ts
├── sanity/                    # schemas, actions, widgets, structure
├── shared/                    # workspace pkg of shared TS types
├── sanity.config.ts  next.config.ts  vercel.json
└── package.json
```

### Firebase Admin (`lib/config/database.ts`)
Initializes from `FIREBASE_SERVICE_ACCOUNT_KEY` (single-line JSON; handles quote
stripping and `\n` un-escaping). Exports lazy `Proxy` objects `db`, `auth`,
`messaging`, plus a `firebaseReady` flag. If the key is missing, requests that
touch Firestore throw a descriptive error and `/health` reports `degraded`.

---

## Conventions

- **Response envelope:** `{ success: boolean, data?, error? }` (some routes add
  `total`, `limit`). Always check `success`.
- **Auth:** protected routes expect `Authorization: Bearer <Firebase ID token>`;
  the handler calls `auth.verifyIdToken(token)` and returns **401** on failure.
  The Flutter client force-refreshes the token before order/payment calls.
- **Field aliases:** order routes accept both camelCase and snake_case
  (`totalAmount`/`total_amount`, `shippingAddress`/`shipping_address`, …).
- **Money:** stored in INR; Razorpay amounts are converted to **paise** (×100).
- **Status codes:** `200` ok, `201` created, `400` bad input, `401`
  unauthorized, `404` not found, `500` server error, `503` misconfigured.

---

## Environment (`.env.local`)

From [`.env.local.example`](../designwear-backend/.env.local.example):

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` / `NEXT_PUBLIC_SANITY_DATASET` | Sanity project/dataset |
| `SANITY_API_TOKEN` | Read/write token (order→Sanity sync, publish-remix) |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Service-account JSON (single line) |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Firebase project id |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | Payments |
| `GEMINI_API_KEY` | AI |
| `NEXT_PUBLIC_APP_URL` / `NODE_ENV` | App config |

---

## Endpoint catalog

Base path: `/api`. ✅ = requires Bearer token.

### Health & metrics
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| GET | `/health` | | `{status: ok\|degraded\|error, services.database}`. `503` if Firebase not ready |
| GET | `/metrics/database` | | DB metrics |
| GET | `/metrics/performance` | | Performance metrics |
| GET | `/operations/recent` | | Recent operations feed |

### Products & categories
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| GET | `/products` | | `?limit` (def 50), `?status`. Returns Firestore products normalized to `Product.fromApiMap` |
| POST | `/products` | | Create product (`title`/`name` + `price` required) → `201` |
| GET | `/products/[id]` | | Single product |
| GET | `/categories` | | All categories |
| GET | `/categories/[id]/products` | | Products in a category |

### Settings
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| GET | `/settings/tax-rate` | | `{ data: { taxRate } }` (default **18**, never fails) |
| PUT | `/settings/tax-rate` | (admin) | `taxRate` 0–100 |

### Cart
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| GET | `/cart` | ✅ | Load the user's cart |
| PUT | `/cart/items` | ✅ | Replace items (`items`, `subtotal`, `tax`, `total`, `itemCount`) — debounced sync from the client |

### Orders
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/orders` | ✅ | Create order. Requires `items` + `shippingAddress`. Generates `orderNumber` (`DW-<ts>-<rand>`) → `201 { data: { id, … } }` |
| GET | `/orders` | ✅ | Orders for the authenticated user |
| GET | `/orders/[id]` | ✅ | Single order |
| PUT/PATCH | `/orders/[id]/status` | ✅ | Update order status |

### Payments (Razorpay)
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/payments/razorpay/order` | ✅ | Body `{ order_id }`. Validates ownership, creates Razorpay order (amount in paise), stores `razorpayOrderId`. Returns `{ razorpay_order_id, amount, currency, key_id }` |
| POST | `/payments/razorpay/verify` | ✅ | Body `{ razorpay_order_id, razorpay_payment_id, razorpay_signature }`. Verifies **HMAC-SHA256** signature, marks order `PAID`, and **syncs the order + customer to Sanity** |

### AI
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/ai/agent` | | DesignBot chat. Body `{ systemPrompt, history, userMessage, imageAttachments }` → `{ data }` (raw Gemini). `503` if no key |
| POST | `/ai/generate-design` | | Body `{ prompt }` → `{ imageData }` base64 PNG |
| POST | `/ai/try-on` | | Body `{ personImageBase64, clothingImageBase64 }` → `{ generateImageBase64 }` |

### Auth (server-side helpers)
| Method | Path | Notes |
|--------|------|-------|
| POST | `/auth/login` | Email/password login |
| POST | `/auth/register` | Register |
| POST | `/auth/google` | Google auth exchange |
| POST | `/auth/guest` | Anonymous/guest |
| POST | `/auth/update` | Update user fields (FCM token, addresses, payment methods) — used by the client's `AuthService` |
| POST | `/auth/token` · GET `/auth/tokens` · POST `/auth/token/revoke` | Token management |

### Community / content
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/publish-remix` | | Publish a remixed design → Sanity product + Firebase sync. Returns `{ productId }` |
| POST | `/sync/[action]` | | Content/data sync actions (`syncService`) |

---

## Detailed contracts (selected)

### `POST /orders`
```jsonc
// Request (client sends camelCase; snake_case also accepted)
{
  "items": [
    { "product_id": "abc", "title": "Custom Tee", "quantity": 1,
      "price": 29.99, "size": "M", "color": "0xFF000000" }
  ],
  "shippingAddress": { /* address object */ },
  "billingAddress":  { /* defaults to shippingAddress */ },
  "totalAmount": 35.39,
  "paymentMethod": "RAZORPAY",
  "notes": "Leave at door"
}
// Response 201
{ "success": true, "data": { "id": "<firestoreId>", "orderNumber": "DW-…", "status": "PENDING", … } }
```

### `POST /payments/razorpay/order`
```jsonc
// Request
{ "order_id": "<firestoreOrderId>" }
// Response 200
{ "success": true, "razorpay_order_id": "order_…",
  "amount": 3539, "currency": "INR", "key_id": "rzp_…" }   // amount in paise
```

### `POST /payments/razorpay/verify`
```jsonc
// Request
{ "razorpay_order_id": "order_…", "razorpay_payment_id": "pay_…", "razorpay_signature": "…" }
// Response 200  (after HMAC check + order→PAID + Sanity sync)
{ "success": true }
// 400 on signature mismatch
```

### `publish-remix`
See [Design Studio → Publish](10-design-studio.md#publish-remix) and
`ApiService.publishRemix` for the request body (`creatorHandle`, `garmentType`,
`lineage[]`, `tags[]`, …). Returns `{ productId }`.

---

## Running & deploying the backend

```bash
cd designwear-backend
npm install
cp .env.local.example .env.local   # fill values
npm run dev      # http://localhost:3000  (API at /api, Studio at /designwear-studio)
npm run build && npm run start      # production
```

Deployment (Vercel) and CI are covered in
[Deployment & CI/CD](14-deployment-and-ci.md). Content schemas are in
[Sanity CMS](13-sanity-cms.md).
