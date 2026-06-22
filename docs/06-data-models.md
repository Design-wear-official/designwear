# 06 · Data Models

All models live in [`lib/models/`](../lib/models) and are re-exported via
[`models.dart`](../lib/models/models.dart). They are **pure Dart** (no Flutter
widget imports; a couple use `dart:ui Color` for convenience). Each model
typically provides `copyWith`, `toJson`/`fromJson`, and—for CMS-sourced
models—`fromMap` (Sanity shape) and/or `fromApiMap` (backend shape).

> **Two parse paths:** `fromMap` parses raw **Sanity** documents (e.g. `_id`,
> `slug.current`, `category._ref`). `fromApiMap` parses the **Next.js backend**'s
> normalized JSON (e.g. `id`, flat `slug`, `categoryId`). This mirrors the
> dual data source described in [Architecture](03-architecture.md).

---

## Product

Catalog item, including **community / remix** metadata. Source:
[`product.dart`](../lib/models/product.dart).

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `title`, `slug`, `description` | `String` | |
| `price` | `double` | |
| `originalPrice` | `double?` | pre-discount |
| `discountPercent` | `double?` | computed when `originalPrice > price` |
| `imageUrl` | `String?` | primary image |
| `images` | `List<String>` | all images |
| `categoryId` | `String` | |
| `stockStatus` | `String` | `inStock` \| `outOfStock` |
| `stockCount` | `int` | |
| `featured` | `bool` | |
| `rating`, `reviewCount` | `double` / `int` | |
| `tags` | `List<String>` | |
| `material`, `productType` | `String?` | |
| `availableSizes` | `List<String>` | default `['S','M','L','XL','XXL']` |
| `availableColors` | `List<String>` | |
| **Community** `creatorName`, `creatorHandle`, `creatorFollowerCount` | | populated from Sanity "community" group |
| `garmentBaseColor` | `String?` | hex, e.g. `#2C5F5A` |
| `artText` | `String?` | text printed on the preview |
| `remixedFromHandle`, `remixedFromVersion` | `String?` | provenance |
| `likeCount`, `remixCount` | `int` | |
| `lineage` | `List<Map<String,String>>` | `[{handle, version, baseColor, artText}]` |

Getters: `isOnSale`, `isInStock`.
Constructors: `Product.fromMap` (Sanity), `Product.fromApiMap` (backend),
`toJson`, `copyWith`.

---

## Category

Source: [`category.dart`](../lib/models/category.dart).

| Field | Type | Notes |
|-------|------|-------|
| `id`, `title`, `slug`, `description` | `String` | |
| `imageUrl` | `String?` | |
| `iconName` | `String?` | Material icon name |
| `productCount` | `int` | |
| `parentId` | `String?` | subcategory parent |
| `featured` | `bool` | |

Getters: `hasImage`, `hasParent`. Constructors: `fromMap`, `fromApiMap`,
`toJson`, `copyWith`.

---

## Cart, CartItem, Coupon

Source: [`cart.dart`](../lib/models/cart.dart). Drives [`CartService`](../lib/services/cart_service.dart).

### `CartItem`
`product`, mutable `quantity`, `selectedSize?`, `selectedColor?`,
`customDesign?`. `total => product.price * quantity`. `toJson` embeds the full
product; `fromJson` rebuilds via `Product.fromApiMap`.

### `Coupon`
`code`, `discountPercent`, optional `maxDiscountAmount`, `minOrderAmount`,
`isValid`. `discountFor(subtotal)` applies min-order and max-cap rules.

### `Cart`
Holds `items` + `appliedCoupon`. Money math:

```
subtotal            = Σ item.total
couponDiscount      = appliedCoupon.discountFor(subtotal)
discountedSubtotal  = subtotal - couponDiscount
tax                 = discountedSubtotal * taxRate     (taxRate default 0.18)
total               = discountedSubtotal + tax
```

`setTaxRate(rate)` takes a **percentage** and stores `rate/100`. Mutators:
`addItem` (custom designs are always added as new lines; identical
plain items merge by id+size+color), `removeItem`, `updateQuantity`, `clear`,
`applyCoupon`, `removeCoupon`.

---

## CustomDesign, DesignElement

The heart of the Design Studio + the AI contract. Source:
[`custom_design.dart`](../lib/models/custom_design.dart).

### `DesignElementType`
`enum { text, sticker, shape }` with `value` (serialized name) and
`fromString`.

### `DesignElement`
A single layered element on the canvas.

| Field | Type | Default |
|-------|------|---------|
| `id` | `String` | required |
| `type` | `DesignElementType` | `text` |
| `content` | `String` | `''` (text or emoji) |
| `x`, `y` | `double` | `0` (position) |
| `size` | `double` | `20` |
| `color` | `String` | `0xFF000000` (hex string) |
| `properties` | `Map<String,dynamic>` | `{}` (font, effects, …) |

### `CustomDesign`
Combines legacy single text/sticker fields **and** the modern layered
`elements` list (backward compatible).

| Field | Type | Notes |
|-------|------|-------|
| `baseColor` | `String` | garment color hex, default white |
| `text`, `textX`, `textY`, `fontSize`, `textColor` | | legacy single-text |
| `sticker`, `stickerX`, `stickerY`, `stickerSize` | | legacy single-sticker |
| `elements` | `List<DesignElement>` | layered system |
| `templateId`, `name` | `String` | |
| `productType` | `String` | `T-Shirt`, `Hoodie`, … |
| `printLocation` | `String` | `centre_chest`, `left_chest`, … |
| `collarStyle` | `String` | `crew` \| `vneck` \| `polo` |
| `pocketStyle` | `String` | `none` \| `left` \| `right` \| `both` |
| `thumbnailPath` | `String?` | local thumbnail |
| `createdAt`, `updatedAt` | `DateTime?` | |
| `designImageBase64` | `String?` | **runtime-only** AI graphic, *not* persisted to JSON |

Helpers: `isEmpty`, `addElement`, `removeElement(id)`, `updateElement(id, new)`,
`reorderElements(old, new)`. `copyWith` uses a sentinel so
`designImageBase64` can be explicitly cleared.

> `designImageBase64` is omitted from `toJson()` on purpose—it's large and
> regenerated at runtime by the AI service.

---

## Order, OrderItem, OrderStatus

Source: [`order.dart`](../lib/models/order.dart).

### `OrderStatus`
`enum { pending, confirmed, processing, shipped, outForDelivery, delivered,
cancelled, refunded }`.
Extension `OrderStatusX`: `displayName`, `isActive`, `isFinal`. Parsing accepts
both `out_for_delivery` and `outForDelivery`.

### `OrderItem`
`productId`, `productTitle`, `productImageUrl?`, `price`, `quantity`,
`selectedSize?`, `selectedColor?`, `customDesign?`. `total => price*quantity`.
Built from a product via `OrderItem.fromProduct(...)`.

### `Order`
`id`, `userId`, `items`, `status`, `shippingAddress`, money fields (`subtotal`,
`tax`, `discount`, `shippingFee`, `total`), `couponCode?`, `paymentId?`
(Razorpay), `paymentMethod?`, timestamps (`createdAt`, `updatedAt?`,
`deliveredAt?`), and tracking (`trackingNumber?`, `trackingUrl?`, `notes?`).
Getters: `itemCount`, `hasCustomDesigns`.

---

## AppUser, AuthProvider

Source: [`user.dart`](../lib/models/user.dart). This is the rich domain user
model. (Note: `AuthService` also defines a **separate, lighter** `User` class for
session state—see [Services](07-services-and-state.md).)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | accepts `id` or `uid` |
| `name`, `email`, `phone`, `photoUrl` | `String?` | |
| `isEmailVerified`, `isPhoneVerified` | `bool` | |
| `authProvider` | `AuthProvider` | `email` \| `google` \| `phone` |
| `addresses` | `List<Address>` | |
| `paymentMethods` | `List<PaymentMethod>` | |
| `loyaltyPoints` | `int` | |
| `createdAt`, `lastLoginAt` | `DateTime?` | |
| `preferences` | `Map<String,dynamic>` | |

Getters: `displayName`, `initials`, `defaultAddress`, `defaultPaymentMethod`.

---

## Address

Source: [`address.dart`](../lib/models/address.dart). `id`, `fullName`, `phone`,
`line1`, `line2?`, `city`, `state`, `pincode`, `country` (default `India`),
`isDefault`, `label?` (`Home`/`Work`/`Other`). Getter `formatted` produces a
one-line string.

---

## PaymentMethod, PaymentMethodType

Source: [`payment_method.dart`](../lib/models/payment_method.dart).
`enum PaymentMethodType { card, upi, netBanking, wallet, cod }`.

Fields: `id`, `type`, `displayName`, `last4?`, `brand?`, `upiId?`,
`walletName?`, `isDefault`, `expiryMonth?`, `expiryYear?`. Getters: `isExpired`,
`maskedDisplay` (e.g. `Visa •••• 4242`).

---

## Home content models (CMS-driven, with fallbacks)

These are sourced from Sanity (always, even in Web-API mode) and ship with
**hard-coded fallbacks** so the home screen renders before content is published.

### `HomeBanner` — [`banner.dart`](../lib/models/banner.dart)
`id`, `badge`, `title`, `subtitle`, `ctaLabel`, `ctaAction` (`shop`/`design`/`deal`),
`ctaColor` (`purple`/`blue`/`orange`), `imageUrl`, `order`. Static
`HomeBanner.fallbacks` provides 3 default banners.

### `Deal` — [`deal.dart`](../lib/models/deal.dart)
`id`, `label`, `originalPrice`, `salePrice`, `discountPercent`, `colorHex`,
`imageUrl?`. Getter `color` parses `colorHex`. Static `Deal.fallbacks` provides 6
default deals.

### `CategoryQuickLink` — [`category_quick_link.dart`](../lib/models/category_quick_link.dart)
`id`, `label`, `iconName`, `colorHex`, `action` (`QuickLinkAction.designStudio` /
`tab`), `tabIndex`, `order`. Getters `icon` (maps `iconName` → `IconData` via an
internal map) and `color`.

---

## JSON conventions

- Colors are stored as **hex strings** like `0xFF1565C0` (ARGB) in design models
  and `#RRGGBB` in CMS content models.
- Dates serialize via `toIso8601String()` and parse with `DateTime.tryParse`.
- Nullable numerics are read defensively: `(json['x'] as num?)?.toDouble() ?? 0`.
- Sanity references appear as `{_ref: ...}`; the backend flattens them to ids.
