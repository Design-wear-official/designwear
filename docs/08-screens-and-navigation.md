# 08 · Screens & Navigation

All screens live in [`lib/screens/`](../lib/screens). The app's root widget sets
`home: const HomeScreen()` ([`lib/main.dart`](../lib/main.dart)); there is no
central `routes:` table—navigation is **imperative**.

---

## Navigation model

Screens are pushed directly with `MaterialPageRoute`, attaching a
`RouteSettings(name: ...)` so the `LoggingService.routeObserver` can record the
current page:

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => const DesignStudioScreen(),
  settings: const RouteSettings(name: '/design-studio'),  // for analytics
));
```

The canonical route-name strings are centralized in
[`AppRoutes`](../lib/config/app_routes.dart) and used as those
`RouteSettings` names:

| Constant | Value |
|----------|-------|
| `AppRoutes.home` | `/` |
| `AppRoutes.login` | `/login` |
| `AppRoutes.register` | `/register` |
| `AppRoutes.productDetail` | `/product` |
| `AppRoutes.cart` | `/cart` |
| `AppRoutes.checkout` | `/checkout` |
| `AppRoutes.orderSuccess` | `/order-success` |
| `AppRoutes.myOrders` | `/my-orders` |
| `AppRoutes.orderDetail` | `/order-detail` |
| `AppRoutes.designStudio` | `/design-studio` |
| `AppRoutes.savedDesigns` | `/saved-designs` |
| `AppRoutes.virtualTryOn` | `/virtual-try-on` |
| `AppRoutes.profile` | `/profile` |
| `AppRoutes.settings` | `/settings` |
| `AppRoutes.shippingAddresses` | `/shipping-addresses` |
| `AppRoutes.paymentMethods` | `/payment-methods` |
| `AppRoutes.searchResults` | `/search` |

> **Heads-up:** Because there's no `routes`/`onGenerateRoute` table, prefer
> `Navigator.push(MaterialPageRoute(...))`. A few call sites use
> `pushReplacementNamed(...)`; if you rely on named routing, register a route
> table or `onGenerateRoute` in `MaterialApp` first.

---

## Screen catalog

### Shell & discovery

| Screen | File | Purpose |
|--------|------|---------|
| **Home** | [`home_screen.dart`](../lib/screens/home_screen.dart) + [`home/`](../lib/screens/home) | App entry: sticky `HomeAppBar`, weekly challenge banner, featured row, product grid, pull-to-refresh. Composed from the `home/` module (app bar, sections, feed grid, challenge banner, settings sheet). |
| **Search Results** | [`search_results_screen.dart`](../lib/screens/search_results_screen.dart) | Query-driven product results (`initialQuery`). |
| **Product Detail** | [`product_detail_screen.dart`](../lib/screens/product_detail_screen.dart) | Product info, images, sizes/colors, add-to-cart, remix entry. |

The home screen renders the feed in two layouts (`FeedLayout.grid` /
`FeedLayout.detail`), toggled via the settings sheet, and persists theme through
`ThemeProvider`.

### Design & creation

| Screen | File | Purpose |
|--------|------|---------|
| **Design Studio** | [`design_studio_screen.dart`](../lib/screens/design_studio_screen.dart) + [`design_studio/`](../lib/screens/design_studio) | The garment designer. Accepts an optional `remixSource` (`Product?`) to open in remix mode. Deep dive: [Design Studio](10-design-studio.md). |
| **Design Detail** | [`design_detail_screen.dart`](../lib/screens/design_detail_screen.dart) | View a saved/community design and its lineage. |
| **Saved Designs** | [`saved_designs_screen.dart`](../lib/screens/saved_designs_screen.dart) | Library of locally saved designs (`DesignStorageService`). |
| **Virtual Try-On** | [`virtual_tryon_screen.dart`](../lib/screens/virtual_tryon_screen.dart) | Upload a person photo + garment, generate an AI try-on. |

### Commerce

| Screen | File | Purpose |
|--------|------|---------|
| **Cart** | [`cart_screen.dart`](../lib/screens/cart_screen.dart) | Line items, quantity, coupon input, totals (`CartService`). |
| **Checkout** | [`checkout_screen.dart`](../lib/screens/checkout_screen.dart) | Address selection, order creation (`OrderService`), Razorpay payment (`RazorpayService`). |
| **My Orders** | [`my_orders_screen.dart`](../lib/screens/my_orders_screen.dart) | Order history + status (`OrderService.fetchOrders`). |

### Account & auth

| Screen | File | Purpose |
|--------|------|---------|
| **Login** | [`login_screen.dart`](../lib/screens/login_screen.dart) | Email/password, Google, guest. |
| **Register** | [`register_screen.dart`](../lib/screens/register_screen.dart) | Email sign-up. |
| **Forgot Password** | [`forgot_password_screen.dart`](../lib/screens/forgot_password_screen.dart) | Password reset. |
| **Profile** | [`profile_screen.dart`](../lib/screens/profile_screen.dart) | Stats + menu sections. |
| **Settings** | [`settings_screen.dart`](../lib/screens/settings_screen.dart) | Notifications, language, theme. |
| **Shipping Addresses** | [`shipping_addresses_screen.dart`](../lib/screens/shipping_addresses_screen.dart) | Manage addresses (`AuthService.addAddress`). |
| **Payment Methods** | [`payment_methods_screen.dart`](../lib/screens/payment_methods_screen.dart) | Manage saved payment methods. |

---

## Key navigation flows

### Browse → buy
```
Home → Product Detail → (add to cart) → Cart → Checkout
     → OrderService.createOrder → RazorpayService.makePayment → My Orders
```

### Design → publish / buy
```
Home (challenge banner "Remix") ─┐
Product Detail (remix) ──────────┤→ Design Studio
                                 │     ├─ DesignBot (AI) edits the design
                                 │     ├─ Virtual Try-On (preview)
                                 │     ├─ Save  → Saved Designs
                                 │     ├─ Publish (remix) → new community product
                                 │     └─ Add to Cart (custom design line)
```

### Auth gate
Auth-required actions (checkout, save sync, addresses) check
`AuthService.isLoggedIn`; unauthenticated users are routed to **Login**, which
also offers **guest** (anonymous) sign-in.

---

## The `home/` module

The home screen is decomposed into a folder with a barrel
([`home.dart`](../lib/screens/home/home.dart)):

| File | Responsibility |
|------|----------------|
| `home_app_bar.dart` | Sticky search bar, cart icon, settings, profile entry |
| `home_challenge_banner.dart` | Weekly design challenge CTA → Design Studio |
| `home_sections.dart` | Section titles, featured row, banners/deals/quick-links |
| `home_feed_grid.dart` | Responsive product grid + states (loading/empty/error) |
| `home_settings_sheet.dart` | Bottom sheet for theme + feed layout |
| `home_constants.dart` | Home-specific constants (`FeedLayout`, sizing) |

This mirrors the **module-folder + barrel** pattern also used by the Design
Studio. See [Project Structure](05-project-structure.md).
