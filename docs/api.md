# API reference

The DesignWear API is the `designwear-backend` repository (plain Node, no dependencies).
This is a summary; the server README has the full detail.

- Base address: `DESIGNWEAR_API_URL` (for example `http://localhost:8787`).
- Bodies are JSON. Errors are `{ "error": { "code", "message" } }`.
- Every response carries `x-request-id`. Quote it when asking for support.
- Authenticated routes need `Authorization: Bearer <session token>` from sign-in.

## Routes

| Method and path | Auth | Purpose |
|---|---|---|
| `GET /v1/health` | none | liveness |
| `GET /v1/config` | none | which features are on: `designAgent`, `tryOn`, `onlinePayments`, `googleSignIn` |
| `POST /v1/auth/register` · `/login` | none | create an account / sign in; returns `{ token, user }` |
| `POST /v1/auth/google` | none | exchange a Firebase ID token for a session |
| `POST /v1/auth/password-reset/request` · `/confirm` | none | emailed code, then the new password |
| `GET` · `PATCH /v1/me` | user | profile |
| `POST /v1/me/password` | user | change password (signs out other devices) |
| `GET` · `PUT /v1/me/addresses` | user | saved addresses |
| `GET /v1/products` · `/v1/products/:id` | none | the sellable catalog (`?limit=`, `?featured=1`) |
| `GET /v1/search?q=&inStock=1` | none | ranked search |
| `GET` · `PUT /v1/cart` | user | the cart (server re-prices lines) |
| `POST /v1/orders` · `GET /v1/orders` · `POST /v1/orders/:id/cancel` | user | place, list, cancel |
| `POST /v1/payments/razorpay/order` · `/verify` | user | online payments (server side; needs Razorpay keys) |
| `GET` · `POST /v1/designs` | optional / user | community feed (`?sort=popular`, `?mine=1`) and publish |
| `GET` · `DELETE /v1/designs/:id` | optional / user | one design / delete your own |
| `POST /v1/designs/:id/like` | user | toggle like |
| `GET /v1/challenges/current` · `/v1/challenges/:id/entries` | none | running challenge and its leaderboard |
| `POST /v1/ai/design-agent` | user | the DesignBot: returns `{ text, design? }` |
| `POST /v1/ai/design-image` | user | a graphic for a design |
| `POST /v1/ai/try-on` | user | try a product or your own design on a photo |
| `GET /v1/img/:host/:project/:dataset/:file` | none | product photos for browsers (allow-listed CDN only; `?w=`, `?q=`, `?auto=format`) |
| `POST /v1/logs` | optional | app warnings and errors (redacted again server side) |
| `PUT /v1/admin/challenges/:id` | admin token | create or update a challenge |

## Rules the server enforces

- **Prices are the server's.** Orders and carts are priced from the catalog; client prices
  are ignored. Stock, sizes (`XS`–`XXL`) and quantity (1–20) are checked.
- **Ownership.** You only see and change your own orders, carts, addresses and designs.
- **Validation.** Designs: at most 60 elements, 400 KB, previews about 330 KB. Addresses need a
  6-digit PIN. Passwords need 8 or more characters.
- **Rate limits** (per address, or per user for signed-in routes):

  | Area | Limit |
  |---|---|
  | sign-up | 10 per hour |
  | sign-in, Google sign-in | 10 / 20 per 15 minutes |
  | password reset request / confirm | 5 / 10 per hour |
  | orders | 20 per hour |
  | publish | 60 per hour |
  | DesignBot, graphics, try-on | 60, 20, 10 per hour |
  | photo proxy | 600 per minute |
  | client logs | 30 per minute |

- **CORS** allows only `ALLOWED_ORIGINS` (and any `localhost` port outside production).
- **Production start-up** fails without `DESIGNWEAR_JWT_SECRET`, `ALLOWED_ORIGINS` and
  `MAIL_WEBHOOK_URL`.

## Admin

Challenges are created with the admin token (the routes don't exist when
`DESIGNWEAR_ADMIN_TOKEN` is unset):

```sh
curl -X PUT "$API/v1/admin/challenges/monsoon" \
  -H "authorization: Bearer $DESIGNWEAR_ADMIN_TOKEN" -H 'content-type: application/json' \
  -d '{"title":"Monsoon","description":"Remix a rain-ready tee",
       "startsAt":"2026-10-26T00:00:00Z","endsAt":"2026-11-01T00:00:00Z"}'
```

The Home banner shows the open challenge with the latest start, its real entry count and
the time left; it is hidden when none is open. Entries must be published and are ranked by likes.
